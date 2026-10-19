import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/app_icons.dart';
import '../core/design/app_tokens.dart';
import '../core/errors/failure.dart';
import '../core/l10n/language_provider.dart';
import '../features/dragonball/presentation/catalog_provider.dart';

// LEARN (extension methods + honest UI):
//  * The banner texts live in AppStrings (catalogOffline, catalogSlow, ...).
//  * Offline vs slow vs broken are DIFFERENT situations, and the user can act
//    differently on each, so the banner says which one it is. The failure TYPE
//    (a sealed class) drives the message; a switch over a sealed class must
//    cover every case, so adding a new Failure type breaks the build here
//    until you decide what the banner should say.
//  * "Slow" is not a network API: it is simply "a refresh has been running for
//    longer than _slowAfter". That is measurable without any plugin.
class CatalogStatusBanner extends ConsumerStatefulWidget {
  const CatalogStatusBanner({super.key});

  @override
  ConsumerState<CatalogStatusBanner> createState() =>
      _CatalogStatusBannerState();
}

class _CatalogStatusBannerState extends ConsumerState<CatalogStatusBanner> {
  static const Duration _slowAfter = Duration(seconds: 4);

  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();

    // listenManual is the way to listen from initState. fireImmediately covers
    // the case where a refresh is ALREADY running when this widget appears.
    ref.listenManual<bool>(
      catalogProvider
          .select((value) => value.asData?.value.isRefreshing ?? false),
      (previous, refreshing) {
        _slowTimer?.cancel();

        if (!refreshing) {
          if (_slow && mounted) setState(() => _slow = false);
          return;
        }

        _slowTimer = Timer(_slowAfter, () {
          if (mounted) setState(() => _slow = true);
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(catalogProvider).asData?.value;

    // No data at all: the screen's own empty / error state explains it.
    if (snapshot == null || !snapshot.hasAnyData) {
      return const SizedBox.shrink();
    }

    final s = ref.watch(stringsProvider);

    if (snapshot.isRefreshing) {
      return _slow
          ? _BannerBar(icon: AppIcons.retry, message: s.catalogSlow)
          : const LinearProgressIndicator(minHeight: 2);
    }

    final failure = snapshot.characters.failure ?? snapshot.planets.failure;

    final message = switch (failure) {
      null => snapshot.isComplete ? null : s.catalogPartial,
      NetworkFailure() => s.catalogOffline,
      ServerFailure() => s.catalogServerProblem,
      ParseFailure() => s.catalogServerProblem,
      UnknownFailure() => s.catalogServerProblem,
    };

    if (message == null) return const SizedBox.shrink();

    return _BannerBar(
      icon: AppIcons.offline,
      message: message,
      actionLabel: s.retry,
      onAction: () {
        ref.read(catalogProvider.notifier).refresh(force: true);
      },
    );
  }
}

class _BannerBar extends StatelessWidget {
  const _BannerBar({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.x4,
          vertical: AppSpace.x1,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.onSecondaryContainer),
            const SizedBox(width: AppSpace.x3),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}