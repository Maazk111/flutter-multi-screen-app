import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/api_course_model.dart';

/// Service layer for all JSONPlaceholder /posts API calls.
/// Keeps HTTP logic fully isolated from the UI layer.
///
/// ⚠️ JSONPlaceholder Note:
/// POST/PUT/DELETE do NOT persist data server-side.
/// The caller is responsible for updating local state after each operation.
class CourseService {
  // Prevent instantiation — static service class only
  CourseService._();

  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  static const String _endpoint = '/posts';
  static const Duration _timeout = Duration(seconds: 10);

  /// Fetches the first 20 courses. Throws descriptive [Exception] on failure.
  static Future<List<ApiCourseModel>> fetchCourses() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$_endpoint?_limit=20'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data =
            jsonDecode(response.body) as List<dynamic>;
        return data
            .map((json) =>
                ApiCourseModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Server error (${response.statusCode})');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on FormatException {
      throw Exception('Invalid data received from server.');
    }
  }

  /// Creates a new course via POST. Returns the server response object.
  /// ⚠️ JSONPlaceholder always returns id: 101 — caller must assign a local ID.
  static Future<ApiCourseModel> createCourse({
    required String title,
    required String body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_endpoint'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'userId': 1,
              'title': title,
              'body': body,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return ApiCourseModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to create course (${response.statusCode})');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on FormatException {
      throw Exception('Invalid data received from server.');
    }
  }

  /// Updates an existing course via PUT. Returns the updated object.
  static Future<ApiCourseModel> updateCourse(ApiCourseModel course) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl$_endpoint/${course.id}'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(course.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ApiCourseModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to update course (${response.statusCode})');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on FormatException {
      throw Exception('Invalid data received from server.');
    }
  }

  /// Deletes a course by ID via DELETE. Throws on non-200 response.
  static Future<void> deleteCourse(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl$_endpoint/$id'))
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete course (${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    }
  }
}