class JlptPracticeOption {
  final int id;
  final String text;

  const JlptPracticeOption({required this.id, required this.text});

  factory JlptPracticeOption.fromJson(Map<String, dynamic> json) {
    return JlptPracticeOption(
      id: (json['id'] as num).toInt(),
      text: (json['text'] ?? '').toString(),
    );
  }
}

class JlptPracticeQuestion {
  final String id;
  final int number;
  final int mondai;
  final String subtype;
  final String prompt;
  final List<JlptPracticeOption> options;
  final int correctOption;

  const JlptPracticeQuestion({
    required this.id,
    required this.number,
    required this.mondai,
    required this.subtype,
    required this.prompt,
    required this.options,
    required this.correctOption,
  });

  factory JlptPracticeQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List?) ?? const [];

    return JlptPracticeQuestion(
      id: (json['id'] ?? '').toString(),
      number: (json['number'] as num?)?.toInt() ?? 0,
      mondai: (json['mondai'] as num?)?.toInt() ?? 0,
      subtype: (json['subtype'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      options: rawOptions
          .map(
            (e) => JlptPracticeOption.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      correctOption: (json['correct_option'] as num).toInt(),
    );
  }
}

class JlptPracticeTest {
  final String id;
  final String title;
  final String level;
  final String section;
  final int timeMinutes;
  final List<JlptPracticeQuestion> questions;

  const JlptPracticeTest({
    required this.id,
    required this.title,
    required this.level,
    required this.section,
    required this.timeMinutes,
    required this.questions,
  });

  factory JlptPracticeTest.fromJson(Map<String, dynamic> json) {
    final rawQuestions = (json['questions'] as List?) ?? const [];

    return JlptPracticeTest(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      level: (json['level'] ?? '').toString(),
      section: (json['section'] ?? '').toString(),
      timeMinutes: (json['time_minutes'] as num?)?.toInt() ?? 0,
      questions: rawQuestions
          .map(
            (e) => JlptPracticeQuestion.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}
