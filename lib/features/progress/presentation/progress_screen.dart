import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/tomo_scaffold.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';
import 'progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesControllerProvider);
    return TomoScaffold(
      title: 'Progress',
      child: preferences.when(
        loading: () => const CircularProgressIndicator(),
        error: (_, _) => const Text('Could not load settings.'),
        data: (settings) => ref
            .watch(levelContentProvider(settings.level))
            .when(
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const Text('No local content is available.'),
              data: (snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${settings.level.label} · Chapter progress',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...snapshot.content.decks.map(
                    (deck) => ref
                        .watch(
                          chapterProgressProvider((
                            level: settings.level,
                            deckId: deck.id,
                          )),
                        )
                        .when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) =>
                              const Text('Could not load chapter progress.'),
                          data: (progress) => ListTile(
                            title: Text(
                              deck.title.isEmpty ? deck.category : deck.title,
                            ),
                            subtitle: LinearProgressIndicator(
                              value: progress.fraction,
                            ),
                            trailing: Text(
                              '${progress.learned} / ${progress.total}',
                            ),
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
