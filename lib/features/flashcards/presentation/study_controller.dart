import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../progress/domain/progress_repository.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../../study_menu/domain/study_catalog.dart';
import '../../vocabulary/domain/entities/deck_category.dart';
import '../../vocabulary/domain/entities/level_content.dart';
import '../../vocabulary/domain/entities/vocabulary_card.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';

typedef StudyRequest = ({
  JlptLevel level,
  DeckCategory? category,
  String? deckId,
  String? source,
  String? reviewFilter,
  String? contentId,
  bool resume,
  bool autoStart,
});
StudyRequest studyRequest({
  required JlptLevel level,
  DeckCategory? category,
  String? deckId,
  String? source,
  String? reviewFilter,
  String? contentId,
  bool resume = false,
  bool autoStart = false,
}) => (
  level: level,
  category: category,
  deckId: deckId,
  source: source,
  reviewFilter: reviewFilter,
  contentId: contentId,
  resume: resume,
  autoStart: autoStart,
);
final studyRandomProvider = Provider<Random>((ref) => Random());
final studyControllerProvider = AsyncNotifierProvider.autoDispose
    .family<StudyController, StudyView, StudyRequest>(StudyController.new);

enum FlashcardMode { learn, review }

class StudyView {
  StudyView({
    required this.content,
    required List<String> baselineIds,
    required this.deckId,
    required this.title,
    required this.mode,
    this.active,
    this.conflict,
    this.flipped = false,
    this.shuffle = false,
    this.busy = false,
    this.completed = false,
  }) : baselineIds = List.unmodifiable(baselineIds);
  final LevelContent content;
  final List<String> baselineIds;
  final String deckId, title;
  final FlashcardMode mode;
  final ActiveStudySession? active, conflict;
  final bool flipped, shuffle, busy, completed;
  bool get isReview => mode == FlashcardMode.review;
  List<String> get ids => active?.contentIds ?? baselineIds;
  int get index => active?.currentIndex ?? 0;
  VocabularyCard? get card =>
      completed || ids.isEmpty ? null : content.vocabulary[ids[index]];
  StudyView copyWith({
    ActiveStudySession? active,
    bool clearActive = false,
    bool? flipped,
    bool? shuffle,
    bool? busy,
    bool? completed,
    bool clearConflict = false,
  }) => StudyView(
    content: content,
    baselineIds: baselineIds,
    deckId: deckId,
    title: title,
    mode: mode,
    active: clearActive ? null : active ?? this.active,
    conflict: clearConflict ? null : conflict,
    flipped: flipped ?? this.flipped,
    shuffle: shuffle ?? this.shuffle,
    busy: busy ?? this.busy,
    completed: completed ?? this.completed,
  );
}

class StudyController extends AsyncNotifier<StudyView> {
  StudyController(this.request);
  final StudyRequest request;
  ProgressRepository get _repository => ref.read(progressRepositoryProvider);
  @override
  Future<StudyView> build() async {
    final content = (await ref.watch(
      levelContentProvider(request.level).future,
    )).content;
    final preferences = await ref.read(preferencesControllerProvider.future);
    final saved = await _repository.loadActiveSession();
    final mode = request.resume
        ? saved?.studyMode == 'review'
              ? FlashcardMode.review
              : FlashcardMode.learn
        : request.reviewFilter == null
        ? FlashcardMode.learn
        : FlashcardMode.review;
    var deckId = request.deckId;
    var title = 'Study session';
    List<String> ids = [];
    if (request.resume) {
      if (saved == null || saved.level != request.level.name) {
        throw StateError('No unfinished session is available for this level.');
      }
      deckId = saved.deckId;
      final original = content.decks.where((d) => d.id == deckId).firstOrNull;
      if (original != null) {
        ids = original.contentIds
            .where(content.vocabulary.containsKey)
            .toSet()
            .toList();
      } else if (deckId.startsWith('all:')) {
        final source = deckId.substring(4);
        ids = content.decks
            .where((d) => (d.source ?? d.category) == source)
            .expand((d) => d.contentIds)
            .where(content.vocabulary.containsKey)
            .toSet()
            .toList();
      } else if (deckId.startsWith('review:')) {
        ids = await _reviewIds(content, deckId.substring(7));
      } else {
        ids = saved.contentIds;
      }
      title =
          content.decks
              .where((d) => d.id == deckId)
              .map(StudyCatalog.deckTitle)
              .firstOrNull ??
          _smartTitle(deckId);
    } else if (request.contentId != null) {
      ids = content.vocabulary.containsKey(request.contentId)
          ? [request.contentId!]
          : [];
      deckId = 'word:${request.contentId}';
      title = 'Word practice';
    } else if (request.reviewFilter != null) {
      deckId = 'review:${request.reviewFilter}';
      title = _smartTitle(deckId);
      ids = await _reviewIds(content, request.reviewFilter!);
    } else {
      final decks = content.decks
          .where(
            (d) =>
                (request.category == null ||
                    (DeckCategory.tryParse(d.category) ?? DeckCategory.other) ==
                        request.category) &&
                (request.source == null ||
                    (d.source ?? d.category) == request.source),
          )
          .toList();
      if (deckId != null && deckId.startsWith('all:')) {
        ids = decks
            .expand((d) => d.contentIds)
            .where(content.vocabulary.containsKey)
            .toSet()
            .toList();
        title = 'All chapters';
      } else {
        final matches = decks.where((d) => deckId == null || d.id == deckId);
        final deck = matches.firstOrNull;
        if (deck != null) {
          deckId = deck.id;
          title = StudyCatalog.deckTitle(deck);
          ids = deck.contentIds
              .where(content.vocabulary.containsKey)
              .toSet()
              .toList();
        }
      }
    }
    deckId ??= 'empty';
    final matching =
        saved != null &&
        saved.deckId == deckId &&
        saved.level == request.level.name;
    if (matching &&
        saved.contentIds.any((id) => !content.vocabulary.containsKey(id))) {
      throw StateError(
        'Saved session content is unavailable. End this session from Home before starting again.',
      );
    }
    if (matching) {
      // Freeze membership as well as saved order until an explicit new session.
      final savedIds = saved.contentIds.toSet();
      ids = {...ids.where(savedIds.contains), ...saved.contentIds}.toList();
    }
    final active = matching ? saved : null;
    var view = StudyView(
      content: content,
      baselineIds: ids,
      deckId: deckId,
      title: title,
      mode: mode,
      active: active,
      conflict: matching ? null : saved,
      shuffle: active?.shuffleEnabled ?? preferences.shuffle,
      flipped: mode == FlashcardMode.learn,
    );
    if (request.autoStart &&
        view.active == null &&
        view.conflict == null &&
        view.ids.isNotEmpty) {
      final session = await _newSession(view);
      view = view.copyWith(active: session);
    }
    return view;
  }

  Future<List<String>> _reviewIds(LevelContent content, String filter) async {
    final items = await switch (filter) {
      'due' => _repository.getDueItems(),
      'weak' => _repository.getWeakItems(),
      'favorites' => _repository.getFavorites(),
      'recent' => _repository.getRecentlyLearned(),
      'mistakes' => _repository.getCommonMistakes(),
      _ => throw ArgumentError('Unknown review collection.'),
    };
    return items
        .where(
          (p) =>
              p.contentType == ContentType.vocabulary &&
              content.vocabulary.containsKey(p.contentId),
        )
        .map((p) => p.contentId)
        .toList();
  }

  String _smartTitle(String id) => switch (id) {
    'review:due' => 'Due Today',
    'review:weak' => 'Weak Words',
    'review:favorites' => 'Favorites',
    'review:recent' => 'Recently Learned',
    'review:mistakes' => 'Common Mistakes',
    _ when id.startsWith('all:') => 'All chapters',
    _ when id.startsWith('word:') => 'Word practice',
    _ => 'Saved session',
  };
  Future<ActiveStudySession> _newSession(StudyView view) async {
    final order = view.baselineIds.toList();
    if (view.shuffle) order.shuffle(ref.read(studyRandomProvider));
    final now = DateTime.now();
    final session = ActiveStudySession(
      sessionId:
          'session_${now.microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
      deckId: view.deckId,
      level: request.level.name,
      currentIndex: 0,
      studyMode: view.isReview ? 'review' : 'learn',
      shuffleEnabled: view.shuffle,
      startedAt: now,
      updatedAt: now,
      contentIds: order,
    );
    await _repository.saveActiveSession(session);
    return session;
  }

  Future<void> _run(Future<StudyView> Function(StudyView) operation) async {
    final view = state.requireValue;
    if (view.busy) return;
    state = AsyncData(view.copyWith(busy: true));
    try {
      final next = await operation(view);
      if (ref.mounted) state = AsyncData(next.copyWith(busy: false));
    } catch (_) {
      if (ref.mounted) state = AsyncData(view.copyWith(busy: false));
      rethrow;
    }
  }

  Future<void> start({bool replaceCurrent = false}) => _run((view) async {
    if (view.active != null) return view;
    if (view.ids.isEmpty) throw StateError('No local words are available.');
    final previous = await _repository.loadActiveSession();
    if (previous != null && !replaceCurrent) {
      throw StateError('An unfinished session already exists.');
    }
    if (previous != null) await _repository.clearActiveSession();
    final active = await _newSession(view);
    return view.copyWith(
      active: active,
      clearConflict: true,
      flipped: !view.isReview,
      completed: false,
    );
  });
  void flip() {
    final view = state.requireValue;
    if (view.card == null || view.busy) return;
    state = AsyncData(view.copyWith(flipped: !view.flipped));
  }

  ActiveStudySession _session(
    ActiveStudySession s, {
    required int index,
    bool? shuffle,
    List<String>? ids,
  }) => ActiveStudySession(
    sessionId: s.sessionId,
    deckId: s.deckId,
    level: s.level,
    currentIndex: index,
    studyMode: s.studyMode,
    shuffleEnabled: shuffle ?? s.shuffleEnabled,
    startedAt: s.startedAt,
    updatedAt: DateTime.now(),
    contentIds: ids ?? s.contentIds,
  );
  Future<void> _requireCurrent(StudyView view) async {
    final saved = await _repository.loadActiveSession();
    final expected = view.active!;
    if (saved == null ||
        saved.sessionId != expected.sessionId ||
        saved.currentIndex != expected.currentIndex ||
        saved.shuffleEnabled != expected.shuffleEnabled ||
        saved.contentIds.length != expected.contentIds.length ||
        Iterable<int>.generate(
          expected.contentIds.length,
        ).any((i) => saved.contentIds[i] != expected.contentIds[i])) {
      ref.invalidateSelf();
      throw StateError('The saved session changed. It has been reloaded.');
    }
  }

  Future<void> move(int delta) => _run((view) async {
    final current = view.active;
    if (current == null) return view;
    await _requireCurrent(view);
    final index = (current.currentIndex + delta).clamp(
      0,
      current.contentIds.length - 1,
    );
    final next = _session(current, index: index);
    await _repository.saveActiveSession(next);
    return view.copyWith(active: next, flipped: !view.isReview);
  });
  Future<void> setShuffle(bool enabled) => _run((view) async {
    if (view.active == null) return view.copyWith(shuffle: enabled);
    await _requireCurrent(view);
    final order = view.baselineIds.toList();
    if (enabled) order.shuffle(ref.read(studyRandomProvider));
    final next = _session(view.active!, index: 0, shuffle: enabled, ids: order);
    await _repository.saveActiveSession(next);
    return view.copyWith(
      active: next,
      shuffle: enabled,
      flipped: !view.isReview,
    );
  });
  Future<void> rate(ReviewRating rating) => _run((view) async {
    if (!view.isReview ||
        !view.flipped ||
        view.active == null ||
        view.card == null) {
      throw StateError('Reveal the answer before rating.');
    }
    await _requireCurrent(view);
    await _repository.recordReview(
      view.card!.id,
      rating,
      sessionId: view.active!.sessionId,
      advanceActiveSession: true,
    );
    final next = await _repository.loadActiveSession();
    return view.copyWith(
      active: next,
      clearActive: next == null,
      completed: next == null,
      flipped: false,
    );
  });
  Future<void> toggleFavorite() => _flag(true);
  Future<void> toggleDifficult() => _flag(false);
  Future<void> _flag(bool favorite) => _run((view) async {
    final card = view.card;
    if (card == null) return view;
    if (favorite) {
      await _repository.toggleFavorite(card.id);
    } else {
      await _repository.toggleDifficult(card.id);
    }
    return view;
  });
  Future<void> end() => _run((view) async {
    if (view.active != null) {
      await _requireCurrent(view);
      await _repository.clearActiveSession();
    }
    return view.copyWith(
      clearActive: true,
      clearConflict: true,
      completed: true,
    );
  });
}
