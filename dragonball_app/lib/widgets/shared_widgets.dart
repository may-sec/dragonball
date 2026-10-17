import 'package:flutter/material.dart';

import '../core/design/app_tokens.dart';

// LEARN (composition): small stateless widgets with a few parameters are the
// building blocks of every screen. Build them once, reuse them everywhere.

/// Tinted pill with an icon and a label (race, affiliation, tier, status).
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.dense = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Pure orange text on a light background has weak contrast. Mixing the
    // category color with the normal text color keeps the hue but is readable.
    final textColor = Color.lerp(color, scheme.onSurface, 0.35)!;

    return Material(
      color: color.withValues(alpha: 0.14),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 8 : 10,
            vertical: dense ? 3 : 5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: dense ? 12 : 14, color: textColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One widget for empty, error and offline states.
class MessageBlock extends StatelessWidget {
  const MessageBlock({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.x8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpace.x3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpace.x2),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpace.x4),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}