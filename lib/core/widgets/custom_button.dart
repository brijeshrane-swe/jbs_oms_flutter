import 'package:flutter/material.dart';

enum CustomButtonType {
  primary,
  secondary,
  outlined,
  text,
  elevated,
  floating,
}

enum CustomButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final CustomButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = CustomButtonType.primary,
    this.size = CustomButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  });

  // Factory constructors for common button types
  const CustomButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = CustomButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  }) : type = CustomButtonType.primary;

  const CustomButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = CustomButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  }) : type = CustomButtonType.secondary;

  const CustomButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = CustomButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  }) : type = CustomButtonType.outlined;

  const CustomButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.size = CustomButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  }) : type = CustomButtonType.text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Size configuration
    final buttonSize = _getButtonSize(size);
    final iconSize = _getIconSize(size);
    final fontSize = _getFontSize(size);

    // Loading state handling
    final isDisabled = onPressed == null || isLoading;

    Widget buttonChild = _buildButtonChild(
      theme: theme,
      iconSize: iconSize,
      fontSize: fontSize,
    );

    Widget button = _buildButtonByType(
      context: context,
      colorScheme: colorScheme,
      buttonSize: buttonSize,
      child: buttonChild,
      isDisabled: isDisabled,
    );

    // Make button full width if expanded
    if (isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildButtonChild({
    required ThemeData theme,
    required double iconSize,
    required double fontSize,
  }) {
    if (isLoading) {
      return SizedBox(
        height: iconSize,
        width: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            foregroundColor ?? theme.colorScheme.onPrimary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(fontSize: fontSize),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildButtonByType({
    required BuildContext context,
    required ColorScheme colorScheme,
    required Size buttonSize,
    required Widget child,
    required bool isDisabled,
  }) {
    final effectivePadding = padding ?? _getDefaultPadding(size);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(8);

    switch (type) {
      case CustomButtonType.primary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.primary,
            foregroundColor: foregroundColor ?? colorScheme.onPrimary,
            minimumSize: buttonSize,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
          ),
          child: child,
        );

      case CustomButtonType.secondary:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.secondary,
            foregroundColor: foregroundColor ?? colorScheme.onSecondary,
            minimumSize: buttonSize,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
          ),
          child: child,
        );

      case CustomButtonType.outlined:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? colorScheme.primary,
            minimumSize: buttonSize,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
            side: BorderSide(
              color: backgroundColor ?? colorScheme.outline,
            ),
          ),
          child: child,
        );

      case CustomButtonType.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor ?? colorScheme.primary,
            minimumSize: buttonSize,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
          ),
          child: child,
        );

      case CustomButtonType.elevated:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 4,
            backgroundColor: backgroundColor ?? colorScheme.surface,
            foregroundColor: foregroundColor ?? colorScheme.onSurface,
            minimumSize: buttonSize,
            padding: effectivePadding,
            shape: RoundedRectangleBorder(borderRadius: effectiveBorderRadius),
          ),
          child: child,
        );

      case CustomButtonType.floating:
        return FloatingActionButton.extended(
          onPressed: isDisabled ? null : onPressed,
          backgroundColor: backgroundColor ?? colorScheme.primary,
          foregroundColor: foregroundColor ?? colorScheme.onPrimary,
          label: child,
        );
    }
  }

  Size _getButtonSize(CustomButtonSize size) {
    switch (size) {
      case CustomButtonSize.small:
        return const Size(80, 32);
      case CustomButtonSize.medium:
        return const Size(120, 40);
      case CustomButtonSize.large:
        return const Size(160, 48);
    }
  }

  double _getIconSize(CustomButtonSize size) {
    switch (size) {
      case CustomButtonSize.small:
        return 16;
      case CustomButtonSize.medium:
        return 20;
      case CustomButtonSize.large:
        return 24;
    }
  }

  double _getFontSize(CustomButtonSize size) {
    switch (size) {
      case CustomButtonSize.small:
        return 12;
      case CustomButtonSize.medium:
        return 14;
      case CustomButtonSize.large:
        return 16;
    }
  }

  EdgeInsetsGeometry _getDefaultPadding(CustomButtonSize size) {
    switch (size) {
      case CustomButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case CustomButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case CustomButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
  }
}

// Specialized buttons for common use cases
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget iconWidget = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                foregroundColor ?? colorScheme.onPrimary,
              ),
            ),
          )
        : Icon(
            icon,
            color: foregroundColor ?? colorScheme.onPrimary,
          );

    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: isLoading ? null : onPressed,
          icon: iconWidget,
          splashRadius: (size ?? 48.0) / 2,
        ),
      ),
    );
  }
}
