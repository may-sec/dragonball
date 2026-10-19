import 'package:flutter/material.dart';

import '../core/design/app_icons.dart';
import '../core/design/app_tokens.dart';
import '../features/dragonball/presentation/navigation_path.dart';

// LEARN (layout + semantics):
//  * Wrap lets the path flow onto a second line on narrow screens or with
//    large text, instead of overflowing like a Row would.
//  * The LAST crumb is the current page (bold, not tappable); earlier crumbs
//    are links that run Crumb.onTap.
//  * AnimatedSwitcher cross-fades the last crumb when you swipe to another
//    character, with no controller needed. Its duration goes through
//    AppMotion.resolve, so it becomes instant when motion is reduced.
//  * One Semantics label reads the whole path to a screen reader.
class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({super.key, required this.crumbs, this.trailing});

  final List<Crumb> crumbs;

  /// e.g. "3 / 12" position text.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final last = crumbs.length - 1;

    return Semantics(
      container: true,
      label: 'Path: ${crumbs.map((c) => c.label).join(', ')}',
      child: Material(
        color: scheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.x4,
            vertical: AppSpace.x2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.x1,
                  runSpacing: AppSpace.x1,
                  children: [
                    for (var i = 0; i < crumbs.length; i++) ...[
                      if (i > 0)
                        Icon(
                          AppIcons.caretRight,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      if (i == last)
                        AnimatedSwitcher(
                          duration:
                              AppMotion.resolve(context, AppMotion.base),
                          child: Padding(
                            key: ValueKey<String>(crumbs[i].label),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              crumbs[i].label,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        )
                      else
                        InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          onTap: crumbs[i].onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              crumbs[i].label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}