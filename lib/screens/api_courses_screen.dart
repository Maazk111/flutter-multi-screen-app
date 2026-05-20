import 'package:flutter/material.dart';

import '../enums/enums.dart';
import '../models/api_course_model.dart';
import '../services/course_service.dart';   // ← THIS LINE — check it exists
import 'add_edit_course_screen.dart';

class ApiCoursesScreen extends StatefulWidget {
  const ApiCoursesScreen({super.key});

  @override
  State<ApiCoursesScreen> createState() => _ApiCoursesScreenState();
}

class _ApiCoursesScreenState extends State<ApiCoursesScreen> {
  LoadState _loadState = LoadState.loading;
  List<ApiCourseModel> _courses = [];
  String _errorMessage = '';

  /// Local ID counter for newly created courses.
  /// JSONPlaceholder POST always returns id: 101 (not persisted).
  /// Starting at 1000 avoids collision with fetched posts (1–100).
  int _nextLocalId = 1000;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  // ── API Operations ──────────────────────────────────────────────────────────

  Future<void> _fetchCourses() async {
    setState(() {
      _loadState = LoadState.loading;
      _errorMessage = '';
    });

    try {
      final courses = await CourseService.fetchCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _loadState = LoadState.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _loadState = LoadState.error;
      });
    }
  }

  Future<void> _navigateToAddCourse() async {
    final result = await Navigator.push<ApiCourseModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditCourseScreen()),
    );

    if (result == null) return;

    // Assign a unique local ID since JSONPlaceholder returns id: 101 for all POSTs
    final newCourse = result.copyWith(id: _nextLocalId++);
    setState(() => _courses.insert(0, newCourse));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Course added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _navigateToEditCourse(ApiCourseModel course) async {
    final result = await Navigator.push<ApiCourseModel>(
      context,
      MaterialPageRoute(builder: (_) => AddEditCourseScreen(course: course)),
    );

    if (result == null) return;

    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index == -1) return;

    setState(() => _courses[index] = result);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Course updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _confirmAndDelete(ApiCourseModel course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text(
          'Are you sure you want to delete\n"${course.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await CourseService.deleteCourse(course.id);
      setState(() => _courses.removeWhere((c) => c.id == course.id));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course deleted.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Courses'),
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: _loadState == LoadState.success
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddCourse,
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Course'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_loadState) {
      case LoadState.loading:
        return const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        );
      case LoadState.error:
        return _buildErrorState();
      case LoadState.success:
        return _buildCourseList();
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchCourses,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    if (_courses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_books_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No courses found.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      // Bottom padding prevents last card from hiding behind FAB
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: _courses.length,
      itemBuilder: (context, index) => _buildCourseCard(_courses[index]),
    );
  }

  Widget _buildCourseCard(ApiCourseModel course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ID badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${course.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Title
                Expanded(
                  child: Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Edit button
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.indigo,
                    size: 20,
                  ),
                  tooltip: 'Edit',
                  onPressed: () => _navigateToEditCourse(course),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                // Delete button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: 'Delete',
                  onPressed: () => _confirmAndDelete(course),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Body / description
            Text(
              course.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}