import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  // Required scopes for your application
  static const List<String> _requiredScopes = ['email', 'profile'];

  static const String _serverClientId =
      "719977785219-j8n2vhg5te2jh4vsmcam53r7853jlveq.apps.googleusercontent.com";

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  @override
  Stream<UserEntity?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _getUserFromFirestore(user.uid);
    });
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      // ignore: unnecessary_null_comparison
      if (account == null) return null;

      // Get authentication tokens
      final authTokens = await _getAuthenticationTokens(account);

      // Try Firebase credential first, with fallback
      try {
        if (kDebugMode) {
          print('🔥 Attempting Firebase credential sign-in...');
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: authTokens.accessToken,
          idToken: authTokens.idToken,
        );

        final UserCredential result =
            await _firebaseAuth.signInWithCredential(credential);

        if (result.user != null) {
          return await _createOrUpdateUser(result.user!);
        }
      } catch (credentialError) {
        if (kDebugMode) {
          print('❌ Firebase credential failed: $credentialError');
          print('🔄 Falling back to manual user creation...');
        }

        // Fallback: Create user manually from token data
        return await _createUserFromTokens(authTokens);
      }

      return null;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// Create user manually from Google tokens without Firebase Auth credential
  Future<UserEntity?> _createUserFromTokens(_AuthTokens authTokens) async {
    try {
      // Decode ID token to extract user information
      final userInfo = _decodeIdToken(authTokens.idToken);

      final userId = userInfo['sub'] as String;
      final email = userInfo['email'] as String;
      final displayName = userInfo['name'] as String? ?? email;
      final photoUrl = userInfo['picture'] as String?;

      if (kDebugMode) {
        print('👤 Decoded user info: $email, $displayName');
      }

      // Create UserEntity
      final userEntity = UserEntity(
        id: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        role: UserRole.user,
        isVerified: false,
      );

      // Save directly to Firestore
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': 'user',
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ User created manually in Firestore');
      }

      return userEntity;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Manual user creation failed: $e');
      }
      throw Exception('Failed to create user from tokens: $e');
    }
  }

  /// Decode JWT ID token to extract user information
  Map<String, dynamic> _decodeIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid ID token format');
      }

      // Get the payload (second part)
      String payload = parts[1];

      // Add padding if needed for base64 decoding
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
        default:
          throw Exception('Invalid base64 string');
      }

      // Decode base64url
      final decoded = utf8.decode(base64Url.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to decode ID token: $e');
    }
  }

  /// Ensure GoogleSignIn is properly initialized
  Future<void> _ensureGoogleSignInInitialized() async {
    if (kDebugMode) {
      print('🔧 Checking GoogleSignIn initialization...');
    }

    try {
      if (kDebugMode) {
        print('🆔 Using serverClientId: $_serverClientId');
      }

      await _googleSignIn.initialize(serverClientId: _serverClientId);

      if (kDebugMode) {
        print('✅ GoogleSignIn initialization completed successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ GoogleSignIn initialization failed:');
        print('   Error: $e');
        print('   Type: ${e.runtimeType}');
        print('   Stack trace: $stackTrace');
      }
      throw Exception('Failed to initialize Google Sign-In service: $e');
    }
  }

  /// Get authentication tokens with retry logic
  Future<_AuthTokens> _getAuthenticationTokens(
      GoogleSignInAccount account) async {
    if (kDebugMode) {
      print('🎫 Starting token retrieval process...');
    }

    try {
      // Step 3.1: Get authentication object
      if (kDebugMode) {
        print('🔐 Step 3.1: Getting authentication object...');
      }
      final GoogleSignInAuthentication auth = await account.authentication;
      if (kDebugMode) {
        print('✅ Step 3.1: Authentication object retrieved');
      }

      // Step 3.2: Extract ID token
      if (kDebugMode) {
        print('🆔 Step 3.2: Extracting ID token...');
      }
      final idToken = auth.idToken;
      if (kDebugMode) {
        print('✅ Step 3.2: ID token extracted, length: ${idToken?.length}');
      }

      // ignore: unnecessary_null_comparison
      if (idToken == null) {
        if (kDebugMode) {
          print('❌ Step 3.2: ID token is null!');
        }
        throw Exception('Failed to retrieve ID token');
      }

      // Step 3.3: Get authorization client
      if (kDebugMode) {
        print('🔑 Step 3.3: Getting authorization client...');
      }
      final authClient = account.authorizationClient;
      if (kDebugMode) {
        print('✅ Step 3.3: Authorization client obtained');
      }

      // Step 3.4: First attempt to get authorization
      if (kDebugMode) {
        print(
            '🎯 Step 3.4: First authorization attempt with scopes: $_requiredScopes');
      }
      GoogleSignInClientAuthorization? authResult;

      try {
        authResult = await authClient.authorizationForScopes(_requiredScopes);
        if (kDebugMode) {
          print('✅ Step 3.4: First authorization attempt completed');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Step 3.4: First authorization attempt failed: $e');
        }
        throw e;
      }

      String? accessToken = authResult?.accessToken;
      if (kDebugMode) {
        print(
            '🔑 Access token from first attempt: ${accessToken != null ? 'SUCCESS (length: ${accessToken.length})' : 'NULL'}');
      }

      // Step 3.5: Retry if access token is null
      if (accessToken == null) {
        if (kDebugMode) {
          print('🔄 Step 3.5: First attempt failed, retrying authorization...');
        }

        try {
          final auth2 = await authClient.authorizeScopes(_requiredScopes);
          accessToken = auth2.accessToken;
          if (kDebugMode) {
            print('✅ Step 3.5: Second authorization attempt completed');
            print(
                '🔑 Access token from retry: ${accessToken != null ? 'SUCCESS (length: ${accessToken.length})' : 'NULL'}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Step 3.5: Second authorization attempt failed: $e');
          }
          throw e;
        }

        // ignore: unnecessary_null_comparison
        if (accessToken == null) {
          if (kDebugMode) {
            print('❌ Step 3.5: Access token is still null after retry!');
          }
          throw Exception('Failed to retrieve access token after retry');
        }
      }

      if (kDebugMode) {
        print('🎉 Token retrieval completed successfully');
      }
      return _AuthTokens(accessToken: accessToken, idToken: idToken);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error in _getAuthenticationTokens:');
        print('   Error: $e');
        print('   Type: ${e.runtimeType}');
        print('   Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await _getUserFromFirestore(user.uid);
  }

  @override
  Future<bool> verifyClientCode(String code) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return false;

    final codeRef = _firestore.collection('client_codes').doc(code);
    final codeSnap = await codeRef.get();

    if (!codeSnap.exists) return false;
    final data = codeSnap.data()!;
    final bool isValid = data['isValid'] == true;
    if (!isValid) return false;

    // Atomically mark code as used & promote user
    final userRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((txn) async {
      txn.update(codeRef, {
        'isValid': false,
        'assignedTo': uid,
        'usedAt': FieldValue.serverTimestamp(),
      });
      txn.update(userRef, {
        'role': 'client',
        'isVerified': true,
      });
    });

    return true;
  }

  @override
  Future<void> requestClientAccess(String email, String displayName) async {
    await _firestore.collection('client_requests').add({
      'email': email,
      'displayName': displayName,
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Future<UserEntity?> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return UserEntity(
      id: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'client',
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Future<UserEntity> _createOrUpdateUser(User firebaseUser) async {
    final userData = {
      'email': firebaseUser.email,
      'displayName': firebaseUser.displayName,
      'photoUrl': firebaseUser.photoURL,
      'lastSignIn': FieldValue.serverTimestamp(),
    };

    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // New user - set default role as client
      userData.addAll({
        'role': 'client',
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await userDoc.set(userData);
    } else {
      // Existing user - update login info
      await userDoc.update(userData);
    }

    return await _getUserFromFirestore(firebaseUser.uid) ??
        UserEntity(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
          role: UserRole.client,
          isVerified: false,
        );
  }

  @override
  Future<UserEntity?> signUpWithEmail(String email, String password) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return _createOrUpdateUser(cred.user!);
  }

  @override
  Future<UserEntity?> signInWithEmail(String email, String password) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return _createOrUpdateUser(cred.user!);
  }
}

// Helper class for token management
class _AuthTokens {
  final String accessToken;
  final String idToken;

  _AuthTokens({required this.accessToken, required this.idToken});
}
