import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_management_system/core/widgets/custom_button.dart';
import 'package:order_management_system/core/widgets/error_widget.dart';
import 'package:order_management_system/core/widgets/loading_widget.dart';

import '../providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo & Title
                  _buildHeader(context, theme),

                  const SizedBox(height: 48),

                  // Loading State
                  if (authState.isLoading)
                    const LoadingWidget.circular(
                      message: 'Signing you in...',
                    )
                  else ...[
                    // Error State
                    if (authState.error != null) ...[
                      InlineErrorWidget(
                        message: authState.error!,
                        onDismiss: () {
                          // Clear error by refreshing provider
                          ref.refresh(authStateProvider);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Login Form
                    _LoginForm(),

                    const SizedBox(height: 32),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Google Sign-In Button
                    CustomButton.outlined(
                      text: 'Continue with Google',
                      icon: Icons.login,
                      onPressed: () async {
                        await ref
                            .read(authStateProvider.notifier)
                            .signInWithGoogle();
                      },
                      isExpanded: true,
                      size: CustomButtonSize.large,
                    ),

                    const SizedBox(height: 16),

                    // Sign Up Option
                    _buildSignUpOption(context, theme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        // App Icon/Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.shopping_cart_outlined,
            size: 40,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),

        const SizedBox(height: 24),

        // App Title
        Text(
          'JBS Food Products',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Sign in to manage your orders',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignUpOption(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New to the app? ',
          style: theme.textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            // TODO: Navigate to sign up or show sign up form
            _showSignUpDialog(context);
          },
          child: const Text('Create Account'),
        ),
      ],
    );
  }

  void _showSignUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Account'),
        content: const Text(
          'Contact your administrator to get access to the system. '
          'Admin accounts are created by invitation only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Separate login form widget using Riverpod
class _LoginForm extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = ref.watch(_emailControllerProvider);
    final passwordController = ref.watch(_passwordControllerProvider);
    final isPasswordVisible = ref.watch(_passwordVisibilityProvider);
    final authNotifier = ref.read(authStateProvider.notifier);

    return Form(
      key: ref.watch(_formKeyProvider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  ref.read(_passwordVisibilityProvider.notifier).state =
                      !isPasswordVisible;
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleEmailSignIn(ref),
          ),

          const SizedBox(height: 8),

          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                _showForgotPasswordDialog(context);
              },
              child: const Text('Forgot Password?'),
            ),
          ),

          const SizedBox(height: 24),

          // Sign In Button
          CustomButton.primary(
            text: 'Sign In',
            icon: Icons.login,
            onPressed: () => _handleEmailSignIn(ref),
            isExpanded: true,
            size: CustomButtonSize.large,
          ),
        ],
      ),
    );
  }

  void _handleEmailSignIn(WidgetRef ref) async {
    final formKey = ref.read(_formKeyProvider);
    if (!formKey.currentState!.validate()) return;

    final email = ref.read(_emailControllerProvider).text.trim();
    final password = ref.read(_passwordControllerProvider).text;

    await ref.read(authStateProvider.notifier).signInWithEmail(email, password);
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text(
          'Contact your administrator to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Riverpod providers for form state
final _formKeyProvider = Provider<GlobalKey<FormState>>((ref) {
  return GlobalKey<FormState>();
});

final _emailControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final _passwordControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final _passwordVisibilityProvider = StateProvider<bool>((ref) => false);
