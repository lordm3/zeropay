import 'package:flutter/material.dart';

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? icon;

  const PillButton({
    super.key,
    required this.label,
    this.onTap,
    this.outlined = false,
    this.height = 52,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.primary;
    final fg = foregroundColor ?? cs.onPrimary;

    if (outlined) {
      return SizedBox(
        height: height,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: const StadiumBorder(),
          disabledBackgroundColor: bg.withAlpha(80),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
