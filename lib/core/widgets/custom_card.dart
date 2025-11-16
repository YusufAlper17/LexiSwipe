import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          boxShadow: boxShadow,
        ),
        child: Card(
          elevation: boxShadow != null ? 0 : (elevation ?? 2),
          color: backgroundColor ?? Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomCardTitle extends StatelessWidget {
  final String text;
  final double? fontSize;
  final Color? color;
  final TextStyle? style;

  const CustomCardTitle({
    Key? key,
    required this.text,
    this.fontSize,
    this.color,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style?.copyWith(
        fontSize: fontSize,
        color: color,
      ) ?? TextStyle(
        fontSize: fontSize ?? 20,
        fontWeight: FontWeight.bold,
        color: color ?? Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }
}

class CustomCardSubtitle extends StatelessWidget {
  final String text;
  final double? fontSize;
  final Color? color;
  final TextStyle? style;
  final FontStyle? fontStyle;

  const CustomCardSubtitle({
    Key? key,
    required this.text,
    this.fontSize,
    this.color,
    this.style,
    this.fontStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style?.copyWith(
        fontSize: fontSize,
        color: color,
        fontStyle: fontStyle,
      ) ?? TextStyle(
        fontSize: fontSize ?? 14,
        color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
        fontStyle: fontStyle ?? FontStyle.normal,
      ),
    );
  }
}

class CustomCardBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const CustomCardBadge({
    Key? key,
    required this.text,
    this.backgroundColor,
    this.color,  // For backward compatibility
    this.textColor,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color ?? Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 