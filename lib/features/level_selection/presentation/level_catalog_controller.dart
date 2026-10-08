import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/jlpt_level.dart';

final levelCatalogProvider = FutureProvider<Set<JlptLevel>>(
  (ref) => ref.watch(levelCatalogRepositoryProvider).availableLevels(),
);
