import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../domain/entities/level_content.dart';

/// Read-only view model for Phase 1. Refresh orchestration arrives in Phase 3.
final levelContentProvider = FutureProvider.autoDispose
    .family<ContentSnapshot, JlptLevel>(
      (ref, level) => ref.watch(vocabularyRepositoryProvider).loadLocal(level),
    );
