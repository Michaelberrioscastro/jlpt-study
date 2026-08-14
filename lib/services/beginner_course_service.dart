import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/beginner_course.dart';

class BeginnerCourseService {
  BeginnerCourseService._();

  static BeginnerCourse? _cache;

  static Future<BeginnerCourse> load() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString('assets/data/beginner_course.json');

    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = BeginnerCourse.fromJson(json);
    return _cache!;
  }
}
