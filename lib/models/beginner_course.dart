class BeginnerCourse {
  final String id;
  final String title;
  final String subtitle;
  final List<BeginnerUnit> units;

  const BeginnerCourse({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.units,
  });

  factory BeginnerCourse.fromJson(Map<String, dynamic> json) {
    return BeginnerCourse(
      id: (json['course_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      units: ((json['units'] as List?) ?? const [])
          .map((e) => BeginnerUnit.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class BeginnerUnit {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final List<BeginnerLesson> lessons;

  const BeginnerUnit({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.lessons,
  });

  factory BeginnerUnit.fromJson(Map<String, dynamic> json) {
    return BeginnerUnit(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      emoji: (json['emoji'] ?? '🌸').toString(),
      description: (json['description'] ?? '').toString(),
      lessons: ((json['lessons'] as List?) ?? const [])
          .map((e) => BeginnerLesson.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class BeginnerLesson {
  final String id;
  final String title;
  final String goal;
  final int estimatedMinutes;
  final List<LessonStep> steps;

  const BeginnerLesson({
    required this.id,
    required this.title,
    required this.goal,
    required this.estimatedMinutes,
    required this.steps,
  });

  factory BeginnerLesson.fromJson(Map<String, dynamic> json) {
    return BeginnerLesson(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      goal: (json['goal'] ?? '').toString(),
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 5,
      steps: ((json['steps'] as List?) ?? const [])
          .map((e) => LessonStep.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class LessonStep {
  final String type;
  final Map<String, dynamic> data;

  const LessonStep({required this.type, required this.data});

  String get japanese => (data['japanese'] ?? '').toString();
  String get reading => (data['reading'] ?? '').toString();
  String get romaji => (data['romaji'] ?? '').toString();
  String get meaning => (data['meaning'] ?? '').toString();

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    return LessonStep(type: (json['type'] ?? '').toString(), data: json);
  }
}
