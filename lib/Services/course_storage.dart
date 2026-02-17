import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';

class CourseStorage {
  static const String _coursesKey = 'courses';
  static const String _ramadanModeKey = 'ramadan_mode';

  // Save courses
  static Future<void> saveCourses(List<Course> courses) async {
    final prefs = await SharedPreferences.getInstance();
    final coursesJson = courses.map((c) => c.toJson()).toList();
    await prefs.setString(_coursesKey, jsonEncode(coursesJson));
  }

  // Load courses
  static Future<List<Course>> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final coursesString = prefs.getString(_coursesKey);

    if (coursesString == null) {
      return [];
    }

    final List<dynamic> coursesJson = jsonDecode(coursesString);
    return coursesJson.map((json) => Course.fromJson(json)).toList();
  }

  // Add a course
  static Future<void> addCourse(Course course) async {
    final courses = await loadCourses();
    courses.add(course);
    await saveCourses(courses);
  }

  // Update a course
  static Future<void> updateCourse(Course updatedCourse) async {
    final courses = await loadCourses();
    final index = courses.indexWhere((c) => c.id == updatedCourse.id);
    if (index != -1) {
      courses[index] = updatedCourse;
      await saveCourses(courses);
    }
  }

  // Delete a course
  static Future<void> deleteCourse(String courseId) async {
    final courses = await loadCourses();
    courses.removeWhere((c) => c.id == courseId);
    await saveCourses(courses);
  }

  // Get Ramadan mode status
  static Future<bool> isRamadanMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ramadanModeKey) ?? false;
  }

  // Set Ramadan mode
  static Future<void> setRamadanMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ramadanModeKey, enabled);
  }
}
