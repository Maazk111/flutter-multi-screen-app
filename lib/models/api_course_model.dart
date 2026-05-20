/// Represents a course fetched from the JSONPlaceholder /posts endpoint.
/// Fields map as: id → course ID, title → course title, body → description.
class ApiCourseModel {
  final int id;
  final int userId;
  final String title;
  final String body;

  const ApiCourseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory ApiCourseModel.fromJson(Map<String, dynamic> json) {
    return ApiCourseModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'title': title,
        'body': body,
      };

  ApiCourseModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
  }) {
    return ApiCourseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }
}