import 'package:flutter/material.dart';

import 'custom_button.dart';

enum ErrorType {
  network,
  server,
  notFound,
  permission,
  generic,
  validation,
}

class CustomErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final ErrorType type;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;
  final String? retryText;
  final IconData? customIcon;
  final bool showRetryButton;
  final bool showHomeButton;

  const CustomErrorWidget({
    super.key,
    this.title,
    this.message,
    this.type = ErrorType.generic,
    this.onRetry,
    this.onGoHome,
    this.retryText,
    this.customIcon,
    this.showRetryButton = true,
    this.showHomeButton = false,
  });

  const CustomErrorWidget.network({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.onGoHome,
    this.retryText,
    this.customIcon,
    this.showRetryButton = true,
    this.showHomeButton = false,
  }) : type = ErrorType.network;

  const CustomErrorWidget.server({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.onGoHome,
    this.retryText,
    this.customIcon,
    this.showRetryButton = true,
    this.showHomeButton = false,
  }) : type = ErrorType.server;

  const CustomErrorWidget.notFound({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.onGoHome,
    this.retryText,
    this.customIcon,
    this.showRetryButton = false,
    this.showHomeButton = true,
  }) : type = ErrorType.notFound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    final errorConfig = _getErrorConfig();

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: errorConfig.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                customIcon ?? errorConfig.icon,
                size: isSmallScreen ? 64 : 80,
                color: errorConfig.iconColor,
              ),
            ),

            SizedBox(height: isSmallScreen ? 20 : 24),

            // Error Title
            Text(
              title ?? errorConfig.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            // Error Message
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                message ?? errorConfig.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: isSmallScreen ? 24 : 32),

            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (showRetryButton && onRetry != null)
                  CustomButton.primary(
                    text: retryText ?? 'Try Again',
                    icon: Icons.refresh,
                    onPressed: onRetry,
                    size: CustomButtonSize.medium,
                  ),
                if (showHomeButton && onGoHome != null)
                  CustomButton.outlined(
                    text: 'Go Home',
                    icon: Icons.home,
                    onPressed: onGoHome,
                    size: CustomButtonSize.medium,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _ErrorConfig _getErrorConfig() {
    switch (type) {
      case ErrorType.network:
        return _ErrorConfig(
          title: 'Network Error',
          message: 'Please check your internet connection and try again.',
          icon: Icons.wifi_off,
          iconColor: Colors.orange,
        );

      case ErrorType.server:
        return _ErrorConfig(
          title: 'Server Error',
          message: 'Something went wrong on our end. Please try again later.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );

      case ErrorType.notFound:
        return _ErrorConfig(
          title: 'Not Found',
          message: 'The page or content you\'re looking for doesn\'t exist.',
          icon: Icons.search_off,
          iconColor: Colors.grey,
        );

      case ErrorType.permission:
        return _ErrorConfig(
          title: 'Access Denied',
          message: 'You don\'t have permission to access this content.',
          icon: Icons.lock_outline,
          iconColor: Colors.red,
        );

      case ErrorType.validation:
        return _ErrorConfig(
          title: 'Validation Error',
          message: 'Please check your input and try again.',
          icon: Icons.warning_amber,
          iconColor: Colors.amber,
        );

      case ErrorType.generic:
      default:
        return _ErrorConfig(
          title: 'Oops! Something went wrong',
          message: 'An unexpected error occurred. Please try again.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
    }
  }
}

class _ErrorConfig {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;

  const _ErrorConfig({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
  });
}

// Inline error widget for forms or smaller spaces
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final Color? backgroundColor;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onDismiss,
    this.showIcon = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              Icons.error_outline,
              size: 20,
              color: colorScheme.error,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 18,
                color: colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Error boundary widget for handling widget errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!, _stackTrace) ??
          CustomErrorWidget(
            title: 'Something went wrong',
            message: 'An unexpected error occurred in the app.',
            onRetry: () {
              setState(() {
                _error = null;
                _stackTrace = null;
              });
            },
          );
    }

    return widget.child;
  }
}
