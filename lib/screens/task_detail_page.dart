/// Task detail view screen showing task info with AI-powered subtask generation.
/// Displays task metadata (priority, deadline, category, energy level).
/// Integrates with AiService to suggest subtasks via LLM for complex tasks.
/// Allows selecting and saving suggested subtasks to the task record.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../dialogs/app_dialogs.dart';
import '../models/task.dart';
import '../Service/ai_service.dart';
import '../Service/task_service.dart';
import '../Widgets/Responsive_widget.dart';
import 'add_edit_task_screen.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;
  final TaskService taskService;

  const TaskDetailPage(
      {super.key, required this.task, required this.taskService});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final AiService _aiService = AiService();
  bool _isGeneratingSubtasks = false;
  List<String> _suggestedSubtasks = [];
  Set<int> _selectedSubtasks = {};

  Future<void> _generateSubtasks() async {
    if (_isGeneratingSubtasks) return;

    setState(() => _isGeneratingSubtasks = true);

    try {
      // Create a prompt for subtask generation
      final prompt = '''
Task: ${widget.task.title}
${widget.task.description != null ? 'Description: ${widget.task.description}' : ''}
Priority: ${widget.task.priority.name}
Category: ${widget.task.category}

Break this task into 3-5 actionable subtasks. Each subtask should be:
- Specific and clear
- Completable in 15-60 minutes  
- Logically ordered
- Action-oriented (start with verbs)

Respond with only a JSON array of subtask strings.
''';

      final result = await _aiService.analyzeJournalEntry(prompt);
      final subtasks = result['actionableSteps'] as List<String>? ?? [];

      if (mounted) {
        setState(() {
          _suggestedSubtasks = subtasks;
          _isGeneratingSubtasks = false;
        });
        await showFloatingBottomDialog(
          context,
          message: 'Subtasks generated successfully!',
          type: AppMessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingSubtasks = false);
        await showFloatingBottomDialog(
          context,
          message: 'Failed to generate subtasks: $e',
          type: AppMessageType.error,
        );
      }
    }
  }

  Future<void> _saveSubtasks() async {
    final selectedSubtasks =
        _selectedSubtasks.map((index) => _suggestedSubtasks[index]).toList();

    if (selectedSubtasks.isEmpty || widget.task.id == null) {
      await showFloatingBottomDialog(
        context,
        message: 'Please select at least one subtask',
        type: AppMessageType.warning,
      );
      return;
    }

    try {
      await widget.taskService.updateTaskSubtasks(
        widget.task.id!,
        selectedSubtasks,
      );

      if (mounted) {
        await showFloatingBottomDialog(
          context,
          message: 'Subtasks saved successfully!',
          type: AppMessageType.success,
        );
        // Clear the suggestions and selection after saving
        setState(() {
          _suggestedSubtasks.clear();
          _selectedSubtasks.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        await showFloatingBottomDialog(
          context,
          message: 'Failed to save subtasks: $e',
          type: AppMessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.task.id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const Center(child: Text('Task not found')),
      );
    }

    return StreamBuilder<Task?>(
      stream: widget.taskService.getTaskById(widget.task.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final task = snapshot.data ?? widget.task;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Task Details',
              style: theme.appBarTheme.titleTextStyle,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditTaskScreen(
                        task: task,
                        taskService: widget.taskService,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getDefaultPadding(context).toDouble(),
              vertical: ResponsiveUtils.getColumnSpacing(context).toDouble(),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      ResponsiveUtils.isWeb(context) ? 1000 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Info Card with glass effect
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getCardBorderRadius(context)
                              .toDouble()),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey.shade900.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getCardBorderRadius(context)
                                    .toDouble()),
                            border: Border.all(
                              color: theme.brightness == Brightness.dark
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
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(
                            ResponsiveUtils.getCardPadding(context).toDouble() *
                                1.2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      ResponsiveUtils.getTitleFontSize(context),
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.grey.shade900,
                                ),
                              ),
                              if (task.description != null) ...[
                                SizedBox(
                                    height: ResponsiveUtils.getColumnSpacing(
                                            context) *
                                        0.75),
                                Text(
                                  task.description!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: ResponsiveUtils.getBodyFontSize(
                                        context),
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                              SizedBox(
                                  height: ResponsiveUtils.getColumnSpacing(
                                      context)),
                              _buildInfoRow(
                                  'Priority',
                                  task.priority.name.toUpperCase(),
                                  _getPriorityColor(task.priority)),
                              SizedBox(
                                  height: ResponsiveUtils.getColumnSpacing(
                                          context) *
                                      0.5),
                              _buildInfoRow(
                                  'Category',
                                  task.category.toUpperCase(),
                                  theme.colorScheme.primary),
                              SizedBox(
                                  height: ResponsiveUtils.getColumnSpacing(
                                          context) *
                                      0.5),
                              _buildInfoRow(
                                  'Energy Level',
                                  task.requiredEnergy.name.toUpperCase(),
                                  const Color.fromARGB(255, 74, 254, 24)),
                              SizedBox(
                                  height: ResponsiveUtils.getColumnSpacing(
                                          context) *
                                      0.5),
                              _buildInfoRow(
                                  'Due',
                                  _formatDeadline(task.deadline),
                                  Colors.orange),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                        height:
                            ResponsiveUtils.getSectionSpacing(context) * 1.2),

                    // Existing Subtasks Section
                    if (task.subtasks.isNotEmpty) ...[
                      Text(
                        'Current Subtasks',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.getTitleFontSize(context),
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.grey.shade900,
                        ),
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getColumnSpacing(context) * 0.8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getCardBorderRadius(context)
                                .toDouble()),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey.shade900.withValues(alpha: 0.9)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(
                                  ResponsiveUtils.getCardBorderRadius(context)
                                      .toDouble()),
                              border: Border.all(
                                color: theme.brightness == Brightness.dark
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
                                ResponsiveUtils.getCardPadding(context)
                                        .toDouble() *
                                    1.2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...List.generate(task.subtasks.length, (index) {
                                  final subtask = task.subtasks[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: subtask.isCompleted
                                              ? theme.colorScheme.outline
                                              : theme.colorScheme.primary
                                                  .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: subtask.isCompleted,
                                            onChanged: (value) async {
                                              if (value != null) {
                                                await widget.taskService
                                                    .toggleSubtaskCompletion(
                                                  task.id!,
                                                  subtask.id,
                                                );
                                              }
                                            },
                                            activeColor:
                                                theme.colorScheme.primary,
                                            checkColor:
                                                theme.colorScheme.onPrimary,
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0,
                                                      horizontal: 4),
                                              child: Text(
                                                subtask.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15,
                                                  color: subtask.isCompleted
                                                      ? theme
                                                          .colorScheme.onSurface
                                                          .withValues(
                                                              alpha: 0.5)
                                                      : theme.colorScheme
                                                          .onSurface,
                                                  decoration:
                                                      subtask.isCompleted
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : TextDecoration.none,
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 20),
                                            onPressed: () async {
                                              await widget.taskService
                                                  .deleteSubtask(
                                                task.id!,
                                                subtask.id,
                                              );
                                            },
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final buildContext = context;
                                    try {
                                      // Clear existing subtasks
                                      await widget.taskService
                                          .updateTaskSubtasks(
                                        widget.task.id!,
                                        [],
                                      );
                                      if (mounted) {
                                        await showFloatingBottomDialog(
                                          buildContext,
                                          message: 'Subtasks cleared',
                                          type: AppMessageType.success,
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        await showFloatingBottomDialog(
                                          buildContext,
                                          message:
                                              'Failed to clear subtasks: $e',
                                          type: AppMessageType.error,
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Clear All Subtasks'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.getSectionSpacing(context) * 1.2),
                    ],

                    // AI Subtasks Section
                    Text(
                      task.subtasks.isEmpty
                          ? 'AI-Powered Task Breakdown'
                          : 'Generate New Subtasks',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(
                        height:
                            ResponsiveUtils.getColumnSpacing(context) * 0.8),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getCardBorderRadius(context)
                              .toDouble()),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey.shade900.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getCardBorderRadius(context)
                                    .toDouble()),
                            border: Border.all(
                              color: theme.brightness == Brightness.dark
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
                              ResponsiveUtils.getCardPadding(context)
                                      .toDouble() *
                                  1.2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Break this complex task into smaller, manageable steps using AI assistance.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isGeneratingSubtasks
                                      ? null
                                      : _generateSubtasks,
                                  icon: _isGeneratingSubtasks
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.auto_awesome),
                                  label: Text(_isGeneratingSubtasks
                                      ? 'Generating Subtasks...'
                                      : 'Break into Subtasks (AI)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              if (_suggestedSubtasks.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Suggested Subtasks:',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...List.generate(_suggestedSubtasks.length,
                                    (index) {
                                  final isSelected =
                                      _selectedSubtasks.contains(index);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                                .withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.outline,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: CheckboxListTile(
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedSubtasks.add(index);
                                            } else {
                                              _selectedSubtasks.remove(index);
                                            }
                                          });
                                        },
                                        title: Text(
                                          _suggestedSubtasks[index],
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        checkColor: theme.colorScheme.onPrimary,
                                        activeColor: theme.colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _suggestedSubtasks.clear();
                                            _selectedSubtasks.clear();
                                          });
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Regenerate'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          await _saveSubtasks();
                                        },
                                        icon: const Icon(Icons.save),
                                        label: Text(
                                          'Save (${_selectedSubtasks.length})',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Builder(
      builder: (context) => Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getColumnSpacing(context) * 0.5,
              vertical: ResponsiveUtils.getColumnSpacing(context) * 0.25,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveUtils.getSmallFontSize(context) * 0.9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.getColumnSpacing(context) * 0.75),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveUtils.getBodyFontSize(context) * 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.blue;
    }
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else {
      return '${difference.inDays} days';
    }
  }
}
