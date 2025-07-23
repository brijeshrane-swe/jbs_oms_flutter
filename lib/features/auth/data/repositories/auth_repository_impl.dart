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
    if (kDebugMode) {
      print('🚀 Starting Google Sign-In process...');
    }

    try {
      // Step 1: Initialize GoogleSignIn
      if (kDebugMode) {
        print('📋 Step 1: Initializing GoogleSignIn...');
      }
      await _ensureGoogleSignInInitialized();
      if (kDebugMode) {
        print('✅ Step 1: GoogleSignIn initialization completed');
      }

      // Step 2: Attempt authentication
      if (kDebugMode) {
        print('🔐 Step 2: Calling authenticate() method...');
      }
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      if (kDebugMode) {
        print('✅ Step 2: authenticate() completed successfully');
        print('👤 Account details: ${account.email}, ${account.displayName}');
      }

      // ignore: unnecessary_null_comparison
      if (account == null) {
        if (kDebugMode) {
          print('❌ Step 2: Account is null (user cancelled)');
        }
        return null;
      }

      // Step 3: Get authentication tokens
      if (kDebugMode) {
        print('🎫 Step 3: Getting authentication tokens...');
      }
      final authTokens = await _getAuthenticationTokens(account);
      if (kDebugMode) {
        print('✅ Step 3: Authentication tokens retrieved successfully');
        print(
            '🔑 Token info: accessToken length=${authTokens.accessToken.length}, idToken length=${authTokens.idToken.length}');
      }

      // Step 4: Create Firebase credential
      if (kDebugMode) {
        print('🔥 Step 4: Creating Firebase credential...');
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: authTokens.accessToken,
        idToken: authTokens.idToken,
      );
      if (kDebugMode) {
        print('✅ Step 4: Firebase credential created successfully');
      }

      // Step 5: Sign in to Firebase
      if (kDebugMode) {
        print('🔥 Step 5: Signing in to Firebase with credential...');
      }
      final UserCredential result =
          await _firebaseAuth.signInWithCredential(credential);
      if (kDebugMode) {
        print('✅ Step 5: Firebase sign-in completed');
        print('👤 Firebase user: ${result.user?.uid}, ${result.user?.email}');
      }

      // Step 6: Create/Update user in Firestore
      if (result.user != null) {
        if (kDebugMode) {
          print('💾 Step 6: Creating/updating user in Firestore...');
        }
        final userEntity = await _createOrUpdateUser(result.user!);
        if (kDebugMode) {
          print('✅ Step 6: User created/updated successfully');
          print(
              '🎯 Final result: ${userEntity?.email}, role: ${userEntity?.role}');
        }
        return userEntity;
      }

      if (kDebugMode) {
        print('❌ Step 5: Firebase user is null');
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('🔥❌ Firebase Auth Exception caught:');
        print('   Code: ${e.code}');
        print('   Message: ${e.message}');
        print('   Stack trace: ${e.stackTrace}');
      }
      throw Exception('Firebase Auth Error: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ General Exception caught:');
        print('   Error: $e');
        print('   Type: ${e.runtimeType}');
        print('   Stack trace: $stackTrace');
      }

      // Handle specific errors
      if (e.toString().contains('PigeonUserDetails')) {
        if (kDebugMode) {
          print(
              '🐦 PigeonUserDetails error detected - this is the root cause!');
        }
        throw Exception(
            'Authentication service temporarily unavailable. Please restart the app.');
      } else if (e.toString().contains('Sign in aborted by user')) {
        if (kDebugMode) {
          print('👤 User cancelled sign-in');
        }
        return null; // User cancelled
      }

      throw Exception('Google Sign-In failed: Please try again');
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
