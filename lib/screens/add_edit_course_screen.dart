import 'package:flutter/material.dart';

import '../models/api_course_model.dart';
import '../services/course_service.dart';   // ← THIS LINE — check it exists
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';

class AddEditCourseScreen extends StatefulWidget {
  /// Pass [course] to enter Edit mode (pre-fills form and sends PUT).
  /// Leave null for Add mode (sends POST).
  final ApiCourseModel? course;

  const AddEditCourseScreen({super.key, this.course});

  @override
  State<AddEditCourseScreen> createState() => _AddEditCourseScreenState();
}

class _AddEditCourseScreenState extends State<AddEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.course != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if in edit mode
    _titleController =
        TextEditingController(text: widget.course?.title ?? '');
    _bodyController =
        TextEditingController(text: widget.course?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      ApiCourseModel result;

      if (_isEditMode) {
        // Preserve the original id — JSONPlaceholder echoes back correctly for
        // real IDs (1-100), but for locally-generated IDs (≥1000) we enforce it.
        final toUpdate = widget.course!.copyWith(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
        );
        result = await CourseService.updateCourse(toUpdate);
        result = result.copyWith(id: widget.course!.id);
      } else {
        result = await CourseService.createCourse(
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Course' : 'Add Course'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                _isEditMode ? Icons.edit_note : Icons.add_circle_outline,
                size: 72,
                color: Colors.indigo,
              ),
              const SizedBox(height: 24),

              // Title field
              CustomTextField(
                controller: _titleController,
                labelText: 'Course Title',
                hintText: 'Enter course title',
                validator: Validators.validateCourseTitle,
              ),

              // Description / body field (multiline)
              CustomTextField(
                controller: _bodyController,
                labelText: 'Description',
                hintText: 'Enter course description',
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                validator: Validators.validateCourseBody,
              ),

              const SizedBox(height: 8),

              // Submit button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditMode ? 'Update Course' : 'Add Course',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}