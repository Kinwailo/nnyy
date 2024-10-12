import 'package:flutter/material.dart';

SnackBar getSnackBar(Widget widget) {
  return SnackBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    duration: Durations.extralong4 * 2,
    content: Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: Builder(
          builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            return Card(
              elevation: 8,
              color: colorScheme.onSurface,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: DefaultTextStyle.merge(
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: colorScheme.surface),
                    child: widget),
              ),
            );
          },
        ),
      ),
    ),
  );
}
