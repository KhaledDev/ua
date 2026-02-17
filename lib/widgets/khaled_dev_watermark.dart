import 'package:flutter/material.dart';

/// A small, non-intrusive bottom bar watermark
/// shown across the app.
class KhaledDevWatermark extends StatelessWidget {
  const KhaledDevWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 32,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              'Web/App Made by KhaledDev',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

