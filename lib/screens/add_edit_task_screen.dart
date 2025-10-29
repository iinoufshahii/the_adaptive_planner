// Clean, theme-aware implementation

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart'; // For softBlue, mintGreen accents

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  final TaskService taskService;

  const AddEditTaskScreen({super.key, this.task, required this.taskService});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _selectedDeadline;
  late TaskPriority _selectedPriority;
  late TaskCategory _selectedCategory;
  late TaskEnergyLevel _selectedEnergy;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController.text = task?.title ?? '';
    _descriptionController.text = task?.description ?? '';
    _selectedDeadline = task?.deadline ?? DateTime.now().add(const Duration(hours: 1));
    _selectedPriority = task?.priority ?? TaskPriority.low;
    _selectedCategory = task?.category ?? TaskCategory.personal;
    _selectedEnergy = task?.requiredEnergy ?? TaskEnergyLevel.low;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final theme = Theme.of(context);
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        // Light wrap customization while respecting current brightness
        final base = theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(primary: softBlue),
        );
        return Theme(data: base, child: child!);
      },
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDeadline),
      builder: (context, child) {
        final base = theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(primary: softBlue),
        );
        return Theme(data: base, child: child!);
      },
    );
    if (time == null) return;
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

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to save a task.')),
        );
      }
      return;
    }

    final task = Task(
      id: widget.task?.id,
      userId: user.uid,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      deadline: _selectedDeadline,
      priority: _selectedPriority,
      category: _selectedCategory,
      requiredEnergy: _selectedEnergy,
      isCompleted: widget.task?.isCompleted ?? false,
    );

    try {
      if (widget.task == null) {
        await widget.taskService.addTask(task);
      } else {
        await widget.taskService.updateTask(task);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isEditing = widget.task != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Task' : 'New Task',
          style: theme.textTheme.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextInput(context: context, controller: _titleController, label: 'Title', validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a title.';
                return null;
              }),
              const SizedBox(height: 20),
              _buildTextInput(
                context: context,
                controller: _descriptionController,
                label: 'Description (Optional)',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildDeadlinePicker(context),
              const SizedBox(height: 20),
              _buildDropdown<TaskPriority>(
                context: context,
                label: 'Priority',
                value: _selectedPriority,
                items: TaskPriority.values,
                onChanged: (val) => setState(() => _selectedPriority = val!),
              ),
              const SizedBox(height: 20),
              _buildDropdown<TaskCategory>(
                context: context,
                label: 'Category',
                value: _selectedCategory,
                items: TaskCategory.values,
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 20),
              _buildDropdown<TaskEnergyLevel>(
                context: context,
                label: 'Required Energy',
                value: _selectedEnergy,
                items: TaskEnergyLevel.values,
                onChanged: (val) => setState(() => _selectedEnergy = val!),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isEditing ? 'Update Task' : 'Create Task',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
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
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: onSurface.withOpacity(0.7)),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.8), width: 2),
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
            style: TextStyle(fontSize: 16, color: onSurface.withOpacity(0.9)),
          ),
        ),
        ElevatedButton(
          onPressed: _selectDateTime,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface.withOpacity(0.9)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: onSurface.withOpacity(0.15)),
            ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              style: TextStyle(color: onSurface, fontSize: 16),
              dropdownColor: theme.colorScheme.surface,
              onChanged: onChanged,
              items: items.map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(formatEnum(e), style: TextStyle(color: onSurface)),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }
}