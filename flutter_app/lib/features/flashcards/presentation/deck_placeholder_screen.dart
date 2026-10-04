import 'package:flutter/material.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../vocabulary/domain/entities/deck_category.dart';

class DeckPlaceholderScreen extends StatelessWidget {
  const DeckPlaceholderScreen({
    super.key,
    required this.level,
    required this.category,
  });
  final JlptLevel level;
  final DeckCategory category;
  @override
  Widget build(BuildContext context) => FeaturePlaceholder(
    title: '${level.label} · ${category.label}',
    message:
        'Your collection is ready. Flashcard practice will be added in a later phase.',
  );
}
