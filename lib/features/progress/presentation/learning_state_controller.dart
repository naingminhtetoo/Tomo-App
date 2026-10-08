import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';

final learningStateControllerProvider =
    NotifierProvider<LearningStateController, bool>(
      LearningStateController.new,
    );

class LearningStateController extends Notifier<bool> {
  @override
  bool build() => false;
  Future<void> endActiveSession() => _run(() async {
    await ref.read(progressRepositoryProvider).clearActiveSession();
    return null;
  });
  Future<void> toggleFavorite(String id) =>
      _run(() => ref.read(progressRepositoryProvider).toggleFavorite(id));
  Future<void> toggleDifficult(String id) =>
      _run(() => ref.read(progressRepositoryProvider).toggleDifficult(id));
  Future<void> _run(Future<Object?> Function() operation) async {
    if (state) return;
    state = true;
    try {
      await operation();
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
