/// Form screen for adding new tasks or editing existing tasks.
/// Supports priority, category, energy level, and deadline selection with datetime picker.
/// Uses glass-effect card styling to match journal screen aesthetic with dark mode support.
library;

import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dialogs/app_dialogs.dart';
import '../models/task.dart';
import '../Service/category_service.dart';
import '../Service/task_service.dart';
import '../Theme/App_Theme.dart';
import '../Widgets/Responsive_widget.dart';

/// StatefulWidget for task form with optional editing mode.
class AddEditTaskScreen extends StatefulWidget {
  /// Existing task if editing, null if creating new task
  final Task? task;

  /// Service to handle task persistence operations
  final TaskService taskService;

  const AddEditTaskScreen({super.key, this.task, required this.taskService});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

/// State managing form fields, validation, and task submission.
class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  /// Form key for validation before submission
  final _formKey = GlobalKey<FormState>();

  /// Controller for task title input field
  final _titleController = TextEditingController();

  /// Controller for task description input field
  final _descriptionController = TextEditingController();

  /// Selected deadline from datetime picker
  late DateTime _selectedDeadline;

  /// Selected priority level (high/medium/low)
  late TaskPriority _selectedPriority;

  /// Selected category as string (supports custom categories from Firestore)
  late String _selectedCategory;

  /// Selected required energy level (high/medium/low)
  late TaskEnergyLevel _selectedEnergy;

  /// Service to fetch and manage custom categories
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    // Initialize form fields from existing task or defaults
    final task = widget.task;
    _titleController.text = task?.title ?? '';
    _descriptionController.text = task?.description ?? '';
    _selectedDeadline =
        task?.deadline ?? DateTime.now().add(const Duration(hours: 1));
    _selectedPriority = task?.priority ?? TaskPriority.low;
    // Initialize category as string (default to 'personal')
    _selectedCategory = task?.category ?? 'personal';
    _selectedEnergy = task?.requiredEnergy ?? TaskEnergyLevel.low;
  }

  @override
  void dispose() {
    // Clean up text controllers to prevent memory leaks
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Open datetime picker dialogs for date and time selection
  Future<void> _selectDateTime() async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    // Show date picker first, with theme customization
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline.isBefore(now) ? now : _selectedDeadline,
      firstDate: now,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        // Apply theme customization to date picker
        final base = theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(primary: softBlue),
        );
        return Theme(data: base, child: child!);
      },
    );
    // Exit if date not selected
    if (date == null) return;
    if (!mounted) return;
    // Show time picker second
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDeadline),
      builder: (context, child) {
        // Apply theme customization to time picker
        final base = theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(primary: softBlue),
        );
        return Theme(data: base, child: child!);
      },
    );
    // Exit if time not selected
    if (time == null) return;
    // Combine date and time, update state
    setState(() {
      _selectedDeadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// Validate form and submit task to Firestore
  Future<void> _saveTask() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) return;
    // Get current authenticated user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        await showFloatingBottomDialog(
          context,
          message: 'You must be logged in to save a task.',
          type: AppMessageType.error,
        );
      }
      return;
    }

    // Build task object from form fields
    final task = Task(
      id: widget.task?.id, // Null if new task, preserves ID if editing
      userId: user.uid,
      title: _titleController.text.trim(),
      // Only set description if provided and non-empty
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      deadline: _selectedDeadline,
      priority: _selectedPriority,
      category: _selectedCategory, // Category is now a string
      requiredEnergy: _selectedEnergy,
      isCompleted: widget.task?.isCompleted ??
          false, // Preserve completion state if editing
    );

    try {
      // Conditional: add new task or update existing
      if (widget.task == null) {
        await widget.taskService.addTask(task);
      } else {
        await widget.taskService.updateTask(task);
      }
      // Show success message and pop screen
      if (mounted) {
        final action = widget.task == null ? 'created' : 'updated';
        await showAutoDismissDialog(
          context,
          title: 'Success',
          message: 'Task $action successfully!',
          type: AppMessageType.success,
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      // Show error message on failure
      if (mounted) {
        await showAutoDismissDialog(
          context,
          title: 'Error',
          message: 'Failed to save task: $e',
          type: AppMessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isEditing = widget.task != null;
    final padding = ResponsiveUtils.getDefaultPadding(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final isWeb = ResponsiveUtils.isWeb(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Task' : 'New Task',
          style: TextStyle(
            fontSize: titleFontSize,
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: padding.toDouble(),
          vertical: padding.toDouble() * 0.5,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWeb ? 900 : double.infinity,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form title card with glass effect
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getCardBorderRadius(context)
                            .toDouble()),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getCardBorderRadius(context)
                                  .toDouble()),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(
                            ResponsiveUtils.getCardPadding(context).toDouble() *
                                1.2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing
                                  ? 'Edit this task'
                                  : 'Create a new task',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveUtils.getTitleFontSize(context) *
                                        0.8,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : Colors.grey.shade900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(
                                height:
                                    ResponsiveUtils.getColumnSpacing(context) *
                                        0.75),
                            _buildTextInput(
                              context: context,
                              controller: _titleController,
                              label: 'Task Title',
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter a title.';
                                }
                                return null;
                              },
                            ),
                            SizedBox(
                                height:
                                    ResponsiveUtils.getColumnSpacing(context) *
                                        0.75),
                            _buildTextInput(
                              context: context,
                              controller: _descriptionController,
                              label: 'Description (Optional)',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          ResponsiveUtils.getColumnSpacing(context).toDouble() *
                              1.2),
                  // Details card with glass effect
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getCardBorderRadius(context)
                            .toDouble()),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getCardBorderRadius(context)
                                  .toDouble()),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(
                            ResponsiveUtils.getCardPadding(context).toDouble() *
                                1.2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDeadlinePicker(context),
                            SizedBox(
                                height:
                                    ResponsiveUtils.getColumnSpacing(context) *
                                        0.75),
                            _buildDropdown<TaskPriority>(
                              context: context,
                              label: 'Priority',
                              value: _selectedPriority,
                              items: TaskPriority.values,
                              onChanged: (val) =>
                                  setState(() => _selectedPriority = val!),
                            ),
                            SizedBox(
                                height:
                                    ResponsiveUtils.getColumnSpacing(context) *
                                        0.75),
                            _buildCategoryDropdown(context),
                            SizedBox(
                                height:
                                    ResponsiveUtils.getColumnSpacing(context) *
                                        0.75),
                            _buildDropdown<TaskEnergyLevel>(
                              context: context,
                              label: 'Required Energy',
                              value: _selectedEnergy,
                              items: TaskEnergyLevel.values,
                              onChanged: (val) =>
                                  setState(() => _selectedEnergy = val!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          ResponsiveUtils.getColumnSpacing(context).toDouble() *
                              1.5),
                  // Submit button with glass effect
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getCardBorderRadius(context)
                            .toDouble()),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getCardBorderRadius(context)
                                  .toDouble()),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(
                            ResponsiveUtils.getCardPadding(context).toDouble() *
                                1.2),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              isEditing ? 'Update Task' : 'Create Task',
                              style: TextStyle(
                                fontSize:
                                    ResponsiveUtils.getBodyFontSize(context) *
                                        1.15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          ResponsiveUtils.getColumnSpacing(context).toDouble()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: onSurface.withValues(alpha: 0.7)),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade800.withValues(alpha: 0.5)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.8),
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDeadlinePicker(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Due: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDeadline)}',
            style: TextStyle(
                fontSize: 16, color: onSurface.withValues(alpha: 0.9)),
          ),
        ),
        ElevatedButton(
          onPressed: _selectDateTime,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            'Change',
            style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T extends Enum>({
    required BuildContext context,
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    String formatEnum(T e) => e.name.toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.9)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: onSurface.withValues(alpha: 0.15)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              style: TextStyle(color: onSurface, fontSize: 16),
              dropdownColor: theme.colorScheme.surface,
              onChanged: onChanged,
              items: items
                  .map((e) => DropdownMenuItem<T>(
                        value: e,
                        child: Text(formatEnum(e),
                            style: TextStyle(color: onSurface)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// Build dynamic category dropdown that loads from Firestore
  Widget _buildCategoryDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return StreamBuilder<List<String>>(
      stream: _categoryService.getUserCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category:',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: onSurface.withValues(alpha: 0.15)),
                ),
                child: SizedBox(
                  height: 50,
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final categories = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: onSurface.withValues(alpha: 0.15)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: categories.contains(_selectedCategory)
                      ? _selectedCategory
                      : (categories.isNotEmpty ? categories.first : 'personal'),
                  isExpanded: true,
                  style: TextStyle(color: onSurface, fontSize: 16),
                  dropdownColor: theme.colorScheme.surface,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                  items: categories
                      .map((c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c, style: TextStyle(color: onSurface)),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
