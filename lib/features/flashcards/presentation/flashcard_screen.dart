import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/tomo_theme.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../../core/widgets/ui_action.dart';
import '../../progress/domain/progress_repository.dart';
import 'study_controller.dart';
import '../../vocabulary/presentation/word_detail_sheet.dart';

class FlashcardScreen extends ConsumerWidget {
  const FlashcardScreen({super.key, required this.request});
  final StudyRequest request;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: 'Flashcard Session',
    showNavigation: false,
    maxContentWidth: 560,
    actions: [
      IconButton(
        tooltip: 'Session settings',
        onPressed: () => _settings(context, ref),
        icon: const Icon(Icons.tune),
      ),
      const SizedBox(width: 16),
    ],
    child: ref
        .watch(studyControllerProvider(request))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => SurfacePanel(
            child: Column(
              children: [
                Text(error.toString().replaceFirst('Bad state: ', '')),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(studyControllerProvider(request)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (view) => _body(context, ref, view),
        ),
  );
  Widget _body(BuildContext context, WidgetRef ref, StudyView view) {
    final theme = Theme.of(context), scheme = Theme.of(context).colorScheme;
    final controller = ref.read(studyControllerProvider(request).notifier);
    final progress = view.card == null
        ? null
        : ref.watch(wordProgressProvider(view.card!.id)).value;
    if (view.completed) {
      return SurfacePanel(
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 54, color: scheme.primary),
            const SizedBox(height: 20),
            Text(
              view.isReview ? 'Review complete' : 'Learning session complete',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              view.isReview
                  ? 'Your reviews have been saved on this device.'
                  : 'Viewing cards did not record review answers.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    }
    if (view.ids.isEmpty) {
      return const SurfacePanel(
        child: Column(
          children: [
            Icon(Icons.auto_stories_outlined, size: 44),
            SizedBox(height: 20),
            Text('No words in this collection yet.'),
            SizedBox(height: 8),
            Text(
              'Try an available chapter or return after studying to build your review collections.',
            ),
          ],
        ),
      );
    }
    final card = view.card!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'End session',
              onPressed: view.busy
                  ? null
                  : () async {
                      if (await confirmAction(
                            context,
                            title: 'End this session?',
                            message:
                                'Your recorded reviews will stay saved. The unfinished position will be cleared.',
                            confirm: 'End session',
                          ) &&
                          context.mounted) {
                        await runUiAction(context, controller.end);
                      }
                    },
              icon: const Icon(Icons.close),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.isReview ? 'Review Mode' : 'Learn Mode',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    view.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: view.shuffle ? 'Turn shuffle off' : 'Shuffle cards',
              isSelected: view.shuffle,
              onPressed: view.busy
                  ? null
                  : () async {
                      final enable = !view.shuffle;
                      if (view.active != null &&
                          !await confirmAction(
                            context,
                            title: 'Restart card order?',
                            message:
                                'This starts at the first card. Your recorded reviews will stay saved.',
                            confirm: enable ? 'Shuffle' : 'Restore order',
                          )) {
                        return;
                      }
                      if (context.mounted) {
                        await runUiAction(
                          context,
                          () => controller.setShuffle(enable),
                        );
                      }
                    },
              icon: Icon(
                Icons.shuffle,
                color: view.shuffle ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: TomoSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Card ${view.index + 1} / ${view.ids.length}',
                style: theme.textTheme.labelLarge,
              ),
            ),
            Text(
              '${(((view.index + 1) / view.ids.length) * 100).round()}%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: TomoSpacing.sm),
        LinearProgressIndicator(value: (view.index + 1) / view.ids.length),
        const SizedBox(height: TomoSpacing.lg),
        if (view.conflict != null) ...[
          SurfacePanel(
            padding: 16,
            child: Column(
              children: [
                const Text('You have an unfinished session.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.pushNamed(
                    AppRoutes.session,
                    pathParameters: {'level': view.conflict!.level},
                  ),
                  child: const Text('Resume saved session'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Semantics(
            button: true,
            label:
                'Flashcard ${card.word}. ${view.flipped ? 'Hide meaning' : 'Show meaning'}',
            child: InkWell(
              borderRadius: BorderRadius.circular(TomoRadii.card),
              onTap: view.busy ? null : controller.flip,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TomoBadge(
                                view.isReview ? 'REVIEW MODE' : 'LEARN MODE',
                              ),
                              if (card.partOfSpeech.isNotEmpty)
                                TomoBadge(
                                  card.partOfSpeech.join(' · ').toUpperCase(),
                                ),
                              TomoBadge(
                                'JLPT ${card.level.label}',
                                accent: false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: progress?.favorite == true
                              ? 'Remove favorite'
                              : 'Favorite',
                          onPressed: view.busy
                              ? null
                              : () => runUiAction(
                                  context,
                                  controller.toggleFavorite,
                                ),
                          icon: Icon(
                            progress?.favorite == true
                                ? Icons.star
                                : Icons.star_outline,
                            color: progress?.favorite == true
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 56),
                    Text(
                      card.reading,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 120,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          card.word,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 86,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (card.romaji != null) ...[
                      const SizedBox(height: 12),
                      TomoBadge(card.romaji!, accent: false),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: view.flipped
                          ? Container(
                              key: const ValueKey('answer'),
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 28),
                              padding: const EdgeInsets.all(TomoSpacing.md),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(
                                  TomoRadii.control,
                                ),
                              ),
                              child: Text(
                                card.meanings.join(' · '),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge,
                              ),
                            )
                          : const SizedBox(key: ValueKey('hidden'), height: 58),
                    ),
                    const SizedBox(height: 36),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            view.flipped
                                ? view.isReview
                                      ? 'Meaning revealed'
                                      : 'Tap to hide meaning for self-testing'
                                : view.isReview
                                ? 'Tap to reveal'
                                : 'Tap to show meaning',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (view.active == null)
          FilledButton(
            onPressed: view.busy
                ? null
                : () async {
                    if (view.conflict != null &&
                        !await confirmAction(
                          context,
                          title: 'Start a new session?',
                          message:
                              'The previous session will end. Its recorded reviews will stay saved.',
                          confirm: 'Start new',
                        )) {
                      return;
                    }
                    if (context.mounted) {
                      await runUiAction(
                        context,
                        () => controller.start(
                          replaceCurrent: view.conflict != null,
                        ),
                      );
                    }
                  },
            child: Text(view.isReview ? 'Start Review' : 'Start Learning'),
          )
        else
          Row(
            children: [
              IconButton.filledTonal(
                key: const Key('previous-card'),
                tooltip: 'Previous card',
                onPressed: view.busy || view.index == 0
                    ? null
                    : () => runUiAction(context, () => controller.move(-1)),
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  onPressed: view.busy ? null : controller.flip,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flip),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          view.flipped
                              ? 'Hide Meaning'
                              : view.isReview
                              ? 'Reveal Meaning'
                              : 'Show Meaning',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                key: const Key('next-card'),
                tooltip: 'Next card',
                onPressed: view.busy || view.index == view.ids.length - 1
                    ? null
                    : () => runUiAction(context, () => controller.move(1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        if (view.isReview) ...[
          const SizedBox(height: 16),
          Row(
            children: ReviewRating.values
                .map(
                  (rating) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: _ratingColor(rating),
                          side: BorderSide(
                            color: _ratingColor(rating).withValues(alpha: 0.5),
                          ),
                        ),
                        onPressed:
                            view.active == null || !view.flipped || view.busy
                            ? null
                            : () => runUiAction(
                                context,
                                () => controller.rate(rating),
                              ),
                        child: FittedBox(child: Text(_rating(rating))),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            TextButton.icon(
              onPressed: () => context.pushNamed(
                AppRoutes.word,
                pathParameters: {'level': request.level.name, 'id': card.id},
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Word Detail'),
            ),
            TextButton.icon(
              onPressed: view.busy
                  ? null
                  : () => runUiAction(context, controller.toggleDifficult),
              icon: Icon(
                progress?.difficult == true ? Icons.flag : Icons.flag_outlined,
              ),
              label: Text(
                progress?.difficult == true
                    ? 'Marked difficult'
                    : 'Mark Difficult',
              ),
            ),
          ],
        ),
        if (view.busy) const LinearProgressIndicator(),
      ],
    );
  }

  String _rating(ReviewRating r) => switch (r) {
    ReviewRating.again => 'Again',
    ReviewRating.hard => 'Hard',
    ReviewRating.good => 'Good',
    ReviewRating.easy => 'Easy',
  };

  Color _ratingColor(ReviewRating rating) => switch (rating) {
    ReviewRating.again => TomoColors.error,
    ReviewRating.hard => TomoColors.amber,
    ReviewRating.good => TomoColors.blue,
    ReviewRating.easy => TomoColors.success,
  };

  void _settings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TomoSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Learn Mode shows meanings immediately. Hide a meaning when you want to test yourself. Viewing and navigation do not record an answer.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Review Mode hides meanings first. Again, Hard, Good and Easy save a review after reveal. Automatic scheduling and audio are not available yet.',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
