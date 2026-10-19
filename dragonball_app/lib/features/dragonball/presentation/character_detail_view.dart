import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/design/category_style.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/platform/experience_policy.dart';
import '../../../core/result/result.dart';
import '../../../core/utils/ki_parser.dart';
import '../../../core/utils/text_cleaners.dart';
import '../../../widgets/breadcrumb_bar.dart';
import '../../../widgets/build_character_image.dart';
import '../../../widgets/favorite_heart.dart';
import '../../../widgets/image_preloader.dart';
import '../../../widgets/ki_bar.dart';
import '../../../widgets/motion_hero.dart';
import '../../../widgets/shared_widgets.dart';
import '../models/dragonball_models.dart';
import 'catalog_components.dart' show characterHeroTag, favoriteCharacterHeroTag;
import 'dragonball_notifier.dart';
import 'full_screen_image_viewer.dart';
import 'navigation_path.dart';
import 'planet_detail_view.dart';

// =============================================================================
// CharacterProfileView
//
// LEARN (what this screen teaches):
//  * PageView: swipe left/right to the previous/next character of the SAME
//    group (the sibling list comes from the screen that opened this one).
//  * State vs provider: the page index is local UI state (setState); the
//    character data is provider state (characterProfileProvider.family).
//  * Slivers: SliverAppBar + FlexibleSpaceBar gives a parallax hero image
//    that stretches when you over-scroll.
//  * Hero: the card image flies into the header image (MotionHero skips the
//    flight when the user asked for reduced motion).
//  * Breadcrumb: built from the PathSource + the current character's name.
//  * Text-scale safety: the transformation strip's height grows with the
//    user's text size instead of being a fixed number.
// =============================================================================
class CharacterProfileView extends ConsumerStatefulWidget {
  const CharacterProfileView({
    super.key,
    required this.characterId,
    this.fromFavorites = false, // kept so existing favorites code still works
    this.nav,
  });

  final int characterId;
  final bool fromFavorites;

  /// Where we came from + siblings. Null = opened by older code with only an id.
  final CharacterNavContext? nav;

  @override
  ConsumerState<CharacterProfileView> createState() =>
      _CharacterProfileViewState();
}

class _CharacterProfileViewState extends ConsumerState<CharacterProfileView> {
  // `late final` + initializer runs on first use, when `widget` is available.
  late final CharacterNavContext _nav = widget.nav ?? _fallbackNav();
  late final PageController _pages = PageController(initialPage: _nav.index);
  late int _index = _nav.index;

  CharacterNavContext _fallbackNav() => CharacterNavContext(
        source: widget.fromFavorites ? const FromFavorites() : const FromAll(),
        siblingIds: [widget.characterId],
        index: 0,
        heroTagFor:
            widget.fromFavorites ? favoriteCharacterHeroTag : characterHeroTag,
      );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final ids = _nav.siblingIds;
    final currentId = ids[_index];

    // Watch only the NAME of the current character, so the breadcrumb updates
    // when the profile loads or when the user swipes.
    final currentName = ref.watch(
      characterProfileProvider(currentId).select((a) => a.asData?.value.name),
    );

    final labels = _nav.source.labels(s);
    final crumbs = <Crumb>[
      for (var i = 0; i < labels.length; i++)
        Crumb(
          labels[i],
          onTap: () => _nav.source.onCrumbTap(i, ref, context),
        ),
      Crumb(currentName ?? '…'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.characterDossier),
        actions: [
          FavoriteHeart(characterId: currentId, overlay: false),
          const SizedBox(width: AppSpace.x1),
        ],
      ),
      body: Column(
        children: [
          BreadcrumbBar(
            crumbs: crumbs,
            trailing: ids.length > 1
                ? Text(
                    '${_index + 1} / ${ids.length}',
                    style: Theme.of(context).textTheme.labelMedium,
                  )
                : null,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: ids.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _ProfilePage(
                key: ValueKey<int>(ids[i]),
                characterId: ids[i],
                heroTag: _nav.heroTagFor(ids[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// One page of the PageView = load one profile, show loading / error / data.
class _ProfilePage extends ConsumerWidget {
  const _ProfilePage({
    super.key,
    required this.characterId,
    required this.heroTag,
  });

  final int characterId;
  final String heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final async = ref.watch(characterProfileProvider(characterId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (error, _) => MessageBlock(
        icon: AppIcons.offline,
        title: s.loadFailed,
        message: error.toString(),
        actionLabel: s.retry,
        onAction: () => ref.invalidate(characterProfileProvider(characterId)),
      ),
      data: (character) => RefreshIndicator(
        onRefresh: () async {
          // Fetch (this also refreshes the disk cache), then re-read it.
          final repo = ref.read(dragonBallRepositoryProvider);
          final result = await repo.fetchCharacterProfile(characterId);
          if (result case Ok()) {
            ref.invalidate(characterProfileProvider(characterId));
          }
        },
        child: _ProfileScroll(
          key: ValueKey<int>(character.id),
          character: character,
          heroTag: heroTag,
        ),
      ),
    );
  }
}

class _ProfileScroll extends ConsumerStatefulWidget {
  const _ProfileScroll({
    super.key,
    required this.character,
    required this.heroTag,
  });

  final CharacterProfile character;
  final String heroTag;

  @override
  ConsumerState<_ProfileScroll> createState() => _ProfileScrollState();
}

class _ProfileScrollState extends ConsumerState<_ProfileScroll> {
  @override
  void initState() {
    super.initState();

    // initState runs ONCE per profile: the old code preloaded images on every
    // build. We still wait for the first frame because precacheImage needs a
    // fully mounted context.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !ref.read(experiencePolicyProvider).preloadImages) {
        return;
      }
      final c = widget.character;
      preloadImageUrls(context, [
        c.imageUrl,
        if (c.originPlanet != null) c.originPlanet!.imageUrl,
        ...c.transformations.map((t) => t.imageUrl),
      ]);
    });
  }

  void _openImage() {
    final c = widget.character;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullScreenImageViewer(
          images: [
            FullScreenImageItem(
              imageUrl: c.imageUrl,
              heroTag: widget.heroTag,
              title: c.name,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.character;
    final s = ref.watch(stringsProvider);
    final contentLanguage =
        ref.watch(languageProvider.select((l) => l.content));
    final theme = Theme.of(context);

    final affiliation = styleForCategory(c.affiliation);
    final race = styleForCategory(c.race);

    // null when the ki values are unreadable ("Unknown"): no tier is shown
    // instead of calling an unknown character a Civilian.
    final tier = tierForKi(c.ki, c.maxKi);

    return CustomScrollView(
      // AlwaysScrollable so pull-to-refresh works even on short content.
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ---- parallax hero ---------------------------------------------------
        SliverAppBar(
          primary: false,
          automaticallyImplyLeading: false,
          stretch: true,
          expandedHeight: 320,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            stretchModes: const [StretchMode.zoomBackground],
            background: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    affiliation.color.withValues(alpha: 0.35),
                    affiliation.color.withValues(alpha: 0.03),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Semantics(
                  button: true,
                  label: '${c.name}, open full screen',
                  child: GestureDetector(
                    onTap: _openImage,
                    child: MotionHero(
                      tag: widget.heroTag,
                      child: buildCharacterImage(
                        c.imageUrl,
                        fit: BoxFit.contain,
                        showLoadingIndicator: true,
                        errorWidget: const Icon(AppIcons.imageBroken, size: 80),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ---- content ---------------------------------------------------------
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.x5,
            AppSpace.x2,
            AppSpace.x5,
            AppSpace.x8,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(c.name, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpace.x3),
              Wrap(
                spacing: AppSpace.x2,
                runSpacing: AppSpace.x2,
                children: [
                  InfoChip(label: c.race, icon: race.icon, color: race.color),
                  InfoChip(
                    label: c.gender,
                    icon: genderIcon(c.gender),
                    color: theme.colorScheme.secondary,
                  ),
                  InfoChip(
                    label: c.affiliation,
                    icon: affiliation.icon,
                    color: affiliation.color,
                  ),
                ],
              ),

              // Power
              const SizedBox(height: AppSpace.x6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(s.power, style: theme.textTheme.titleLarge),
                          ),
                          if (tier != null)
                            InfoChip(
                              label: s.tierName(tier),
                              icon: AppIcons.ki,
                              color: tierColor(tier),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.x4),
                      KiBar(
                        ki: c.ki,
                        maxKi: c.maxKi,
                        height: 12,
                        showLabels: true,
                        kiLabel: s.kiNow,
                        maxLabel: s.kiMax,
                      ),
                      const SizedBox(height: AppSpace.x2),
                      Text(s.logScaleNote, style: theme.textTheme.bodySmall),
                      const Divider(height: AppSpace.x6),
                      Row(
                        children: [
                          Expanded(child: _Stat(label: s.kiNow, value: c.ki)),
                          Expanded(child: _Stat(label: s.kiMax, value: c.maxKi)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // About
              const SizedBox(height: AppSpace.x6),
              Row(
                children: [
                  Text(s.about, style: theme.textTheme.titleLarge),
                  const SizedBox(width: AppSpace.x3),
                  Flexible(
                    child: InfoChip(
                      label: s.descriptionLanguageNote(contentLanguage.label),
                      icon: AppIcons.translate,
                      color: theme.colorScheme.secondary,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.x2),
              _ExpandableText(
                text: c.description.isEmpty
                    ? s.noDescription
                    : stripFootnotes(c.description),
                moreLabel: s.showMore,
                lessLabel: s.showLess,
              ),

              // Origin planet
              if (c.originPlanet != null) ...[
                const SizedBox(height: AppSpace.x6),
                Text(s.originPlanet, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpace.x3),
                _OriginPlanetCard(planet: c.originPlanet!),
              ],

              // Transformations
              if (c.transformations.isNotEmpty) ...[
                const SizedBox(height: AppSpace.x6),
                Text(
                  '${s.transformations} (${c.transformations.length})',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpace.x3),
                _TransformationStrip(
                  characterId: c.id,
                  characterName: c.name,
                  transformations: c.transformations,
                  fallbackColor: affiliation.color,
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpace.x1),
        Text(value.trim(), style: theme.textTheme.titleMedium),
      ],
    );
  }
}

// LEARN (StatefulWidget + implicit animation): a tiny widget with ONE piece of
// state. AnimatedSize animates the height change for free; its duration goes
// through AppMotion.resolve so reduced motion makes the change instant.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({
    required this.text,
    required this.moreLabel,
    required this.lessLabel,
  });

  final String text;
  final String moreLabel;
  final String lessLabel;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.length > 220;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: AppMotion.resolve(context, AppMotion.base),
          curve: AppMotion.curve,
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            maxLines: _open || !isLong ? null : 5,
            overflow: _open || !isLong ? TextOverflow.visible : TextOverflow.fade,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (isLong)
          TextButton(
            onPressed: () => setState(() => _open = !_open),
            child: Text(_open ? widget.lessLabel : widget.moreLabel),
          ),
      ],
    );
  }
}

class _OriginPlanetCard extends ConsumerWidget {
  const _OriginPlanetCard({required this.planet});

  final Planet planet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpace.x3),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: buildCharacterImage(
            planet.imageUrl,
            fit: BoxFit.contain,
            errorWidget: const Icon(AppIcons.globe),
          ),
        ),
        title: Text(planet.name),
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpace.x1),
            child: InfoChip(
              label: planet.isDestroyed ? s.destroyed : s.intact,
              icon: planet.isDestroyed ? AppIcons.destroyed : AppIcons.globe,
              color: planet.isDestroyed ? scheme.error : AppColors.of(context).intact,
              dense: true,
            ),
          ),
        ),
        trailing: const Icon(AppIcons.caretRight),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlanetDetailView(planetId: planet.id),
          ),
        ),
      ),
    );
  }
}

// LEARN (keeping TWO screens in sync): the full-screen viewer and this strip
// share ONE ValueNotifier<int> (the viewer's page index).
//   * Swiping in the viewer writes to the notifier.
//   * This strip LISTENS and scrolls itself to the same form, while it is
//     hidden behind the viewer. When the viewer closes (X button, system back
//     or back swipe) the Hero finds the right card already on screen and the
//     image flies back to exactly the form you were looking at.
//   * The viewer's onBeforePop is NOT called on system back, so listening to
//     the notifier is more reliable than a "before pop" callback.
// The selected card also gets a colored border and a slight scale, so you can
// see which form is active.
//
// LEARN (text scale and fixed heights): the card needs room for a 2-line name
// and a ki row, and BOTH grow with the user's text size. A fixed `height: 240`
// either overflows or squeezes the image to nothing at large scales. The strip
// height below is "room for the text at this scale + a constant image area".
class _TransformationStrip extends StatefulWidget {
  const _TransformationStrip({
    required this.characterId,
    required this.characterName,
    required this.transformations,
    required this.fallbackColor,
  });

  final int characterId;
  final String characterName;
  final List<Transformation> transformations;
  final Color fallbackColor;

  @override
  State<_TransformationStrip> createState() => _TransformationStripState();
}

class _TransformationStripState extends State<_TransformationStrip> {
  static const double _itemWidth = 150;
  static const double _gap = AppSpace.x3;

  // Image area + fixed chrome (accent bar, paddings) at text scale 1.
  static const double _fixedHeight = 180;

  // Height taken by the name (2 lines) and the ki row at text scale 1.
  static const double _textHeightAtScale1 = 60;

  final ScrollController _scroll = ScrollController();

  // The viewer's PageView is endless (page = count * 1000 + index), so this
  // holds a PAGE number; the form index is always page % count.
  late final ValueNotifier<int> _page;

  bool _viewerOpen = false;

  int get _count => widget.transformations.length;

  @override
  void initState() {
    super.initState();
    _page = ValueNotifier<int>(_count * 1000);
    _page.addListener(_followViewer);
  }

  @override
  void dispose() {
    _page.removeListener(_followViewer);
    _page.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _heroTag(int index) => 'form-${widget.characterId}-$index';

  double _stripHeight(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final effective = textScale < 1 ? 1.0 : textScale;

    return _fixedHeight + _textHeightAtScale1 * effective;
  }

  // Runs every time the viewer changes page.
  void _followViewer() {
    if (!_viewerOpen || _count == 0) return;
    _centerOn(_page.value % _count);
  }

  // jumpTo (not animateTo): the strip is covered by the viewer, so animating
  // would only risk a half-finished scroll when the Hero flight starts.
  void _centerOn(int index) {
    if (!_scroll.hasClients) return;

    final position = _scroll.position;
    final target =
        index * (_itemWidth + _gap) - (position.viewportDimension - _itemWidth) / 2;

    _scroll.jumpTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent).toDouble(),
    );
  }

  Future<void> _open(int index, List<String> names) async {
    // Start from the tapped form, even if an earlier session swiped far away.
    _page.value = _count * 1000 + index;
    _viewerOpen = true;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullScreenImageViewer(
          images: [
            for (var j = 0; j < _count; j++)
              FullScreenImageItem(
                imageUrl: widget.transformations[j].imageUrl,
                heroTag: _heroTag(j),
                title: names[j],
              ),
          ],
          initialIndex: index,
          // With ONE image the viewer has no PageView; passing the notifier
          // would make it look for page 1000 and drop the Hero.
          pageNotifier: _count > 1 ? _page : null,
        ),
      ),
    );

    _viewerOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transformations = widget.transformations;

    // Clean every name (e.g. "Goku SSJB" -> "Super Saiyan Blue").
    final names = [
      for (final t in transformations)
        prettyTransformationName(t.name, widget.characterName),
    ];

    return SizedBox(
      height: _stripHeight(context),
      // Rebuilds only the strip when the selected form changes.
      child: ValueListenableBuilder<int>(
        valueListenable: _page,
        builder: (context, page, _) {
          final selected = page % _count;

          return ListView.separated(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(vertical: AppSpace.x2),
            itemCount: _count,
            separatorBuilder: (_, __) => const SizedBox(width: _gap),
            itemBuilder: (context, i) {
              final t = transformations[i];
              final accent = formAccentColor(names[i], widget.fallbackColor);
              final isSelected = i == selected;

              return AnimatedScale(
                scale: isSelected ? 1.0 : 0.96,
                duration: AppMotion.resolve(context, AppMotion.base),
                curve: AppMotion.curve,
                child: SizedBox(
                  width: _itemWidth,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.lgAll,
                      side: BorderSide(
                        color: isSelected
                            ? accent
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _open(i, names),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(height: 4, color: accent),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpace.x2),
                              child: MotionHero(
                                tag: _heroTag(i),
                                child: buildCharacterImage(
                                  t.imageUrl,
                                  fit: BoxFit.contain,
                                  showLoadingIndicator: true,
                                  errorWidget: const Icon(AppIcons.imageBroken),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpace.x2,
                              0,
                              AppSpace.x2,
                              AppSpace.x3,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  names[i],
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: AppSpace.x1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(AppIcons.ki, size: 14, color: accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatKi(parseKi(t.ki)),
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}