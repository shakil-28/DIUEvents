import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final double width;
  final double height;
  final TextStyle textStyle;
  final double borderRadius;
  final double elevation;
  final bool enableFeedback;
  final Widget? leading; // New parameter for leading widget (icon/image)

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Colors.black,
    this.width = double.infinity,
    this.height = 50.0,
    this.textStyle = const TextStyle(color: Colors.white, fontSize: 16),
    this.borderRadius = 8.0,
    this.elevation = 2.0,
    this.enableFeedback = true,
    this.leading, // Initialize it
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.1),
          backgroundColor: color,
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: height / 4),
          animationDuration: const Duration(milliseconds: 50),
          enableFeedback: enableFeedback,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: textStyle.copyWith(
                color: textStyle.color ?? Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
