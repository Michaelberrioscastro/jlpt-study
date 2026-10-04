import 'knowledge_state.dart';

enum ExerciseType {
  recognitionChoice,
  meaningChoice,
  readingChoice,
  production,
  contextChoice,
  kanjiMeaning,
}

enum LessonPhase {
  review,
  newContent,
  reinforcement,
  challenge,
  complete,
}

class LessonExercise {
  final String id;
  final String itemType;
  final int itemId;
  final ExerciseType type;
  final KnowledgeDimension dimension;
  final String prompt;
  final String answer;
  final List<String> options;
  final String? explanation;
  final int difficulty;
  final bool isReview;

  const LessonExercise({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.type,
    required this.dimension,
    required this.prompt,
    required this.answer,
    this.options = const [],
    this.explanation,
    this.difficulty = 2,
    this.isReview = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'item_type': itemType,
        'item_id': itemId,
        'type': type.name,
        'dimension': dimension.name,
        'prompt': prompt,
        'answer': answer,
        'options': options,
        'explanation': explanation,
        'difficulty': difficulty,
        'is_review': isReview,
      };
}

class LessonSession {
  final String id;
  final String level;
  final LessonPhase phase;
  final List<LessonExercise> exercises;
  final DateTime createdAt;

  const LessonSession({
    required this.id,
    required this.level,
    required this.phase,
    required this.exercises,
    required this.createdAt,
  });

  int get total => exercises.length;
}
