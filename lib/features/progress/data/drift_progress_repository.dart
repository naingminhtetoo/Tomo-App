import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/progress_repository.dart';
import '../../level_selection/domain/jlpt_level.dart';

class DriftProgressRepository implements ProgressRepository {
  DriftProgressRepository(this.database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final AppDatabase database;
  final DateTime Function() _clock;
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;
  Future<void> close() => _changes.close();
  void _changed() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<List<QueryRow>> _rows(
    String sql, [
    List<Variable> variables = const [],
  ]) => database.customSelect(sql, variables: variables).get();
  int _time(DateTime date) => date.millisecondsSinceEpoch;
  DateTime? _date(QueryRow r, String key) => r.readNullable<int>(key) == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(r.read<int>(key));
  StudyProgress _progress(QueryRow r) => StudyProgress(
    contentId: r.read<String>('content_id'),
    contentType: ContentType.values.byName(r.read<String>('content_type')),
    status: switch (r.read<String>('status')) {
      'learning' => LearningStatus.learning,
      'mastered' => LearningStatus.mastered,
      _ => LearningStatus.newItem,
    },
    masteryLevel: r.read<int>('mastery_level'),
    correctCount: r.read<int>('correct_count'),
    incorrectCount: r.read<int>('incorrect_count'),
    favorite: r.read<int>('favorite') == 1,
    difficult: r.read<int>('difficult') == 1,
    firstLearnedAt: _date(r, 'first_learned_at'),
    lastReviewedAt: _date(r, 'last_reviewed_at'),
    nextReviewAt: _date(r, 'next_review_at'),
    reviewInterval: r.read<int>('review_interval'),
    easeFactor: r.read<double>('ease_factor'),
    updatedAt: _date(r, 'updated_at')!,
    syncStatus: r.read<String>('sync_status'),
  );
  void _id(String id) {
    if (id.trim().isEmpty) throw ArgumentError('Content ID must not be empty.');
  }

  @override
  Future<StudyActivity> activity({
    DateTime? now,
    Set<String>? contentIds,
  }) async {
    final current = now ?? _clock();
    DateTime day(DateTime d) => current.isUtc
        ? DateTime.utc(d.year, d.month, d.day)
        : DateTime(d.year, d.month, d.day);
    final today = day(current);
    final days = List.generate(
      7,
      (i) => current.isUtc
          ? DateTime.utc(today.year, today.month, today.day - 6 + i)
          : DateTime(today.year, today.month, today.day - 6 + i),
    );
    final counts = List.filled(7, 0);
    final studiedDays = <DateTime>{};
    var reviewed = 0, correct = 0;
    final rows = await _rows(
      'SELECT content_id,rating,reviewed_at FROM review_history WHERE reviewed_at <= ?',
      [Variable(_time(current))],
    );
    for (final row in rows) {
      if (contentIds != null &&
          !contentIds.contains(row.read<String>('content_id'))) {
        continue;
      }
      final time = DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('reviewed_at'),
        isUtc: current.isUtc,
      );
      final date = day(time);
      studiedDays.add(date);
      final index = days.indexOf(date);
      if (index >= 0) {
        counts[index]++;
        reviewed++;
        if (row.read<String>('rating') != 'again') correct++;
      }
    }
    var cursor = today;
    if (!studiedDays.contains(cursor)) {
      cursor = current.isUtc
          ? DateTime.utc(today.year, today.month, today.day - 1)
          : DateTime(today.year, today.month, today.day - 1);
    }
    var streak = 0;
    while (studiedDays.contains(cursor)) {
      streak++;
      cursor = current.isUtc
          ? DateTime.utc(cursor.year, cursor.month, cursor.day - 1)
          : DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return StudyActivity(
      days: List.unmodifiable(days),
      reviewCounts: List.unmodifiable(counts),
      reviewed: reviewed,
      correct: correct,
      streak: streak,
    );
  }

  @override
  Future<StudyProgress?> findByCardId(
    String id, {
    ContentType type = ContentType.vocabulary,
  }) async {
    final rows = await _rows(
      'SELECT * FROM study_progress WHERE content_id = ? AND content_type = ?',
      [Variable(id), Variable(type.name)],
    );
    return rows.isEmpty ? null : _progress(rows.single);
  }

  @override
  Future<void> save(StudyProgress p) async {
    _id(p.contentId);
    if (p.masteryLevel < 0 ||
        p.correctCount < 0 ||
        p.incorrectCount < 0 ||
        p.reviewInterval < 0 ||
        !p.easeFactor.isFinite ||
        p.easeFactor <= 0) {
      throw ArgumentError('Invalid learning state.');
    }
    await database.customStatement(
      '''INSERT INTO study_progress
      (content_id,content_type,status,mastery_level,correct_count,incorrect_count,favorite,difficult,
       first_learned_at,last_reviewed_at,next_review_at,review_interval,ease_factor,updated_at,sync_status)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(content_id,content_type) DO UPDATE SET
      status=excluded.status,mastery_level=excluded.mastery_level,correct_count=excluded.correct_count,
      incorrect_count=excluded.incorrect_count,favorite=excluded.favorite,difficult=excluded.difficult,
      first_learned_at=excluded.first_learned_at,last_reviewed_at=excluded.last_reviewed_at,next_review_at=excluded.next_review_at,
      review_interval=excluded.review_interval,ease_factor=excluded.ease_factor,updated_at=excluded.updated_at,sync_status='pending' ''',
      [
        p.contentId,
        p.contentType.name,
        p.status == LearningStatus.newItem ? 'new' : p.status.name,
        p.masteryLevel,
        p.correctCount,
        p.incorrectCount,
        p.favorite ? 1 : 0,
        p.difficult ? 1 : 0,
        p.firstLearnedAt?.millisecondsSinceEpoch,
        p.lastReviewedAt?.millisecondsSinceEpoch,
        p.nextReviewAt?.millisecondsSinceEpoch,
        p.reviewInterval,
        p.easeFactor,
        _time(p.updatedAt),
        'pending',
      ],
    );
    _changed();
  }

  Future<bool> _toggle(String id, ContentType type, String flag) async {
    _id(id);
    final value = await database.transaction(() async {
      await database.customStatement(
        '''INSERT INTO study_progress(content_id,content_type,$flag,updated_at) VALUES(?,?,1,?)
        ON CONFLICT(content_id,content_type) DO UPDATE SET $flag=1-$flag,updated_at=excluded.updated_at,sync_status='pending' ''',
        [id, type.name, _time(_clock())],
      );
      return flag == 'favorite'
          ? (await findByCardId(id, type: type))!.favorite
          : (await findByCardId(id, type: type))!.difficult;
    });
    _changed();
    return value;
  }

  @override
  Future<bool> toggleFavorite(
    String id, {
    ContentType type = ContentType.vocabulary,
  }) => _toggle(id, type, 'favorite');
  @override
  Future<bool> toggleDifficult(
    String id, {
    ContentType type = ContentType.vocabulary,
  }) => _toggle(id, type, 'difficult');
  Future<List<StudyProgress>> _list(
    String clause, [
    List<Variable> vars = const [],
  ]) async => List.unmodifiable(
    (await _rows('SELECT * FROM study_progress $clause', vars)).map(_progress),
  );
  @override
  Future<List<StudyProgress>> getFavorites() =>
      _list('WHERE favorite=1 ORDER BY updated_at DESC');
  @override
  Future<List<StudyProgress>> getDifficultItems() =>
      _list('WHERE difficult=1 ORDER BY updated_at DESC');
  @override
  Future<List<StudyProgress>> getDueItems({DateTime? now}) => _list(
    'WHERE next_review_at <= ? ORDER BY next_review_at',
    [Variable(_time(now ?? _clock()))],
  );
  @override
  Future<List<StudyProgress>> getRecentlyLearned() => _list(
    'WHERE first_learned_at IS NOT NULL ORDER BY first_learned_at DESC',
  );
  @override
  Future<List<StudyProgress>> getCommonMistakes() => _list(
    'WHERE incorrect_count > 0 ORDER BY incorrect_count DESC, last_reviewed_at DESC',
  );
  @override
  Future<List<StudyProgress>> getWeakItems() => _list(
    '''WHERE difficult=1 OR (incorrect_count > 0 AND incorrect_count >= correct_count)
    OR EXISTS (SELECT 1 FROM review_history h WHERE h.content_id=study_progress.content_id
      AND h.content_type=study_progress.content_type AND h.rating IN ('again','hard')
      AND h.id=(SELECT MAX(latest.id) FROM review_history latest
        WHERE latest.content_id=h.content_id AND latest.content_type=h.content_type))
    ORDER BY incorrect_count DESC, updated_at DESC''',
  );
  @override
  Future<void> recordReview(
    String id,
    ReviewRating rating, {
    ContentType type = ContentType.vocabulary,
    int? newInterval,
    DateTime? nextReviewAt,
    int? responseTimeMs,
    String? sessionId,
    bool advanceActiveSession = false,
  }) async {
    _id(id);
    if ((newInterval != null && newInterval < 0) ||
        (responseTimeMs != null && responseTimeMs < 0)) {
      throw ArgumentError('Invalid review values.');
    }
    final now = _clock();
    final correct = rating != ReviewRating.again;
    await database.transaction(() async {
      if (sessionId != null) {
        final sessions = await _rows(
          'SELECT id FROM study_sessions WHERE id=? AND ended_at IS NULL',
          [Variable(sessionId)],
        );
        if (sessions.isEmpty) throw StateError('Review session is not active.');
      }
      final active = advanceActiveSession ? await loadActiveSession() : null;
      if (advanceActiveSession &&
          (active == null ||
              active.sessionId != sessionId ||
              active.contentIds[active.currentIndex] != id)) {
        throw StateError('Review does not match the active card.');
      }
      final previous = await findByCardId(id, type: type);
      final interval = newInterval ?? previous?.reviewInterval ?? 0;
      await database.customStatement(
        '''INSERT INTO study_progress(content_id,content_type,status,correct_count,incorrect_count,
          first_learned_at,last_reviewed_at,next_review_at,review_interval,updated_at)
        VALUES(?,?,'learning',?,?,?,?,?,?,?) ON CONFLICT(content_id,content_type) DO UPDATE SET
        status=CASE WHEN status='new' THEN 'learning' ELSE status END,
        correct_count=correct_count+excluded.correct_count,incorrect_count=incorrect_count+excluded.incorrect_count,
        first_learned_at=COALESCE(first_learned_at,excluded.first_learned_at),last_reviewed_at=excluded.last_reviewed_at,
        next_review_at=excluded.next_review_at,review_interval=excluded.review_interval,updated_at=excluded.updated_at,sync_status='pending' ''',
        [
          id,
          type.name,
          correct ? 1 : 0,
          correct ? 0 : 1,
          _time(now),
          _time(now),
          (nextReviewAt ?? previous?.nextReviewAt)?.millisecondsSinceEpoch,
          interval,
          _time(now),
        ],
      );
      await database.customStatement(
        '''INSERT INTO review_history(content_id,content_type,rating,reviewed_at,previous_interval,new_interval,
        response_time_ms,session_id,updated_at) VALUES(?,?,?,?,?,?,?,?,?)''',
        [
          id,
          type.name,
          rating.name,
          _time(now),
          previous?.reviewInterval ?? 0,
          interval,
          responseTimeMs,
          sessionId,
          _time(now),
        ],
      );
      if (sessionId != null) {
        await database.customStatement(
          'UPDATE study_sessions SET reviewed_count=reviewed_count+1,correct_count=correct_count+?,updated_at=?,sync_status=\'pending\' WHERE id=?',
          [correct ? 1 : 0, _time(now), sessionId],
        );
      }
      if (active != null) {
        if (active.currentIndex + 1 >= active.contentIds.length) {
          await database.customStatement(
            'UPDATE study_sessions SET ended_at=? WHERE id=?',
            [_time(now), active.sessionId],
          );
          await database.customStatement(
            'DELETE FROM active_session WHERE singleton=1',
          );
        } else {
          await database.customStatement(
            'UPDATE active_session SET current_index=current_index+1,updated_at=? WHERE singleton=1',
            [_time(now)],
          );
        }
      }
    });
    _changed();
  }

  @override
  Future<List<ReviewRecord>> getReviewHistory(
    String id, {
    ContentType type = ContentType.vocabulary,
  }) async => List.unmodifiable(
    (await _rows(
      'SELECT * FROM review_history WHERE content_id=? AND content_type=? ORDER BY reviewed_at,id',
      [Variable(id), Variable(type.name)],
    )).map(
      (r) => ReviewRecord(
        id: r.read<int>('id'),
        contentId: r.read<String>('content_id'),
        contentType: ContentType.values.byName(r.read<String>('content_type')),
        rating: ReviewRating.values.byName(r.read<String>('rating')),
        reviewedAt: _date(r, 'reviewed_at')!,
        previousInterval: r.read<int>('previous_interval'),
        newInterval: r.read<int>('new_interval'),
        responseTimeMs: r.readNullable<int>('response_time_ms'),
        sessionId: r.readNullable<String>('session_id'),
      ),
    ),
  );
  @override
  Future<ProgressSummaryData> summary({
    Set<String>? contentIds,
    DateTime? now,
  }) async {
    final date = now ?? _clock();
    final start = date.isUtc
        ? DateTime.utc(date.year, date.month, date.day)
        : DateTime(date.year, date.month, date.day);
    final end = date.isUtc
        ? DateTime.utc(date.year, date.month, date.day + 1)
        : DateTime(date.year, date.month, date.day + 1);
    bool includes(String id) => contentIds == null || contentIds.contains(id);
    final progress = (await _list(
      '',
    )).where((p) => includes(p.contentId)).toList();
    final history = (await _rows(
      'SELECT * FROM review_history WHERE reviewed_at >= ? AND reviewed_at < ?',
      [Variable(_time(start)), Variable(_time(end))],
    )).where((r) => includes(r.read<String>('content_id'))).toList();
    return ProgressSummaryData(
      reviewedToday: history.length,
      totalReviews: history.length,
      correctReviews: history
          .where((r) => r.read<String>('rating') != 'again')
          .length,
      learnedToday: progress
          .where(
            (p) =>
                p.firstLearnedAt != null &&
                !p.firstLearnedAt!.isBefore(start) &&
                p.firstLearnedAt!.isBefore(end),
          )
          .length,
      learned: progress.where((p) => p.firstLearnedAt != null).length,
      learning: progress
          .where((p) => p.status == LearningStatus.learning)
          .length,
      mastered: progress
          .where((p) => p.status == LearningStatus.mastered)
          .length,
      dueCount: progress
          .where(
            (p) => p.nextReviewAt != null && !p.nextReviewAt!.isAfter(date),
          )
          .length,
    );
  }

  @override
  Future<DeckProgress> deckProgress(
    Iterable<String> contentIds, {
    ContentType type = ContentType.vocabulary,
  }) async {
    final ids = contentIds.toSet();
    final learned = (await _list(
      'WHERE content_type=? AND first_learned_at IS NOT NULL',
      [Variable(type.name)],
    )).where((p) => ids.contains(p.contentId)).length;
    return DeckProgress(learned: learned, total: ids.length);
  }

  @override
  Future<void> saveActiveSession(ActiveStudySession s) async {
    if (JlptLevel.tryParse(s.level) == null ||
        s.studyMode.trim().isEmpty ||
        s.updatedAt.isBefore(s.startedAt) ||
        s.contentIds.toSet().length != s.contentIds.length ||
        s.sessionId.isEmpty ||
        s.deckId.isEmpty ||
        s.contentIds.isEmpty ||
        s.currentIndex < 0 ||
        s.currentIndex >= s.contentIds.length ||
        s.contentIds.any((id) => id.trim().isEmpty)) {
      throw ArgumentError('Invalid active study session.');
    }
    await database.transaction(() async {
      final previous = await loadActiveSession();
      if (previous != null && previous.sessionId != s.sessionId) {
        throw StateError('Complete or clear the previous study session first.');
      }
      final old = await _rows('SELECT * FROM study_sessions WHERE id=?', [
        Variable(s.sessionId),
      ]);
      if (old.isNotEmpty &&
          (old.single.readNullable<int>('ended_at') != null ||
              old.single.read<String>('deck_id') != s.deckId ||
              old.single.read<String>('level') != s.level)) {
        throw StateError('Session identity cannot change or reopen.');
      }
      await database.customStatement(
        'INSERT INTO study_sessions(id,deck_id,level,mode,started_at,updated_at) VALUES(?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET updated_at=excluded.updated_at',
        [
          s.sessionId,
          s.deckId,
          s.level,
          s.studyMode,
          _time(s.startedAt),
          _time(s.updatedAt),
        ],
      );
      await database.customStatement(
        '''INSERT INTO active_session(singleton,session_id,deck_id,level,current_index,study_mode,
        shuffle_enabled,content_ids,started_at,updated_at) VALUES(1,?,?,?,?,?,?,?,?,?) ON CONFLICT(singleton) DO UPDATE SET
        session_id=excluded.session_id,deck_id=excluded.deck_id,level=excluded.level,current_index=excluded.current_index,
        study_mode=excluded.study_mode,shuffle_enabled=excluded.shuffle_enabled,content_ids=excluded.content_ids,
        started_at=excluded.started_at,updated_at=excluded.updated_at''',
        [
          s.sessionId,
          s.deckId,
          s.level,
          s.currentIndex,
          s.studyMode,
          s.shuffleEnabled ? 1 : 0,
          jsonEncode(s.contentIds),
          _time(s.startedAt),
          _time(s.updatedAt),
        ],
      );
    });
    _changed();
  }

  @override
  Future<ActiveStudySession?> loadActiveSession() async {
    final rows = await _rows('SELECT * FROM active_session WHERE singleton=1');
    if (rows.isEmpty) return null;
    final r = rows.single;
    return ActiveStudySession(
      sessionId: r.read<String>('session_id'),
      deckId: r.read<String>('deck_id'),
      level: r.read<String>('level'),
      currentIndex: r.read<int>('current_index'),
      studyMode: r.read<String>('study_mode'),
      shuffleEnabled: r.read<int>('shuffle_enabled') == 1,
      contentIds: List<String>.from(
        jsonDecode(r.read<String>('content_ids')) as List,
      ),
      startedAt: _date(r, 'started_at')!,
      updatedAt: _date(r, 'updated_at')!,
    );
  }

  Future<void> _finish() async {
    await database.transaction(() async {
      final active = await loadActiveSession();
      if (active == null) return;
      await database.customStatement(
        'UPDATE study_sessions SET ended_at=?,updated_at=?,sync_status=\'pending\' WHERE id=?',
        [_time(_clock()), _time(_clock()), active.sessionId],
      );
      await database.customStatement(
        'DELETE FROM active_session WHERE singleton=1',
      );
    });
    _changed();
  }

  @override
  Future<void> completeActiveSession() => _finish();
  @override
  Future<void> clearActiveSession() => _finish();
  @override
  Future<List<StudySession>> getStudySessions() async => List.unmodifiable(
    (await _rows('SELECT * FROM study_sessions ORDER BY started_at DESC')).map(
      (r) => StudySession(
        id: r.read<String>('id'),
        deckId: r.read<String>('deck_id'),
        level: r.read<String>('level'),
        mode: r.read<String>('mode'),
        startedAt: _date(r, 'started_at')!,
        endedAt: _date(r, 'ended_at'),
        reviewedCount: r.read<int>('reviewed_count'),
        correctCount: r.read<int>('correct_count'),
      ),
    ),
  );
}
