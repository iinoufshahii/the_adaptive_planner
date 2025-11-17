/// Task list screen with filtering, sorting, and category selection.
/// Displays tasks from Firestore with ability to filter by completion status and category.
/// Uses reusable card widgets from card_widget.dart for consistent UI design.
// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dialogs/app_dialogs.dart';
import '../models/task.dart';
import '../Service/category_service.dart';
import '../Service/task_service.dart';
import '../Theme/App_Theme.dart';
import '../Widgets/Responsive_widget.dart';
import '../Widgets/Card_Widget.dart';
import 'add_edit_task_screen.dart';
import 'task_detail_page.dart';

enum TaskCompletionFilter { All, Incomplete, Completed, Overdue, DueToday }

class TaskListScreen extends StatefulWidget {
  final TaskService taskService;
  final TaskCompletionFilter? initialFilter;
  const TaskListScreen(
      {super.key, required this.taskService, this.initialFilter});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String? _selectedCategory;
  late TaskCompletionFilter _filter;
  final CategoryService _categoryService = CategoryService();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? TaskCompletionFilter.All;
  }

  String _label(Enum e) => e.toString().split('.').last;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isWeb = ResponsiveUtils.isWeb(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final iconSize = ResponsiveUtils.getIconSize(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _titleForFilter(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: titleFontSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              size: iconSize,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showFilterSheet,
          )
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view tasks.'))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWeb ? 1200 : double.infinity,
                ),
                child: StreamBuilder<List<Task>>(
                  stream: widget.taskService.getTasks(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    var tasks = snapshot.data ?? [];
                    if (_selectedCategory != null) {
                      tasks = tasks
                          .where((t) => t.category == _selectedCategory)
                          .toList();
                    }
                    if (_filter == TaskCompletionFilter.Incomplete) {
                      tasks = tasks.where((t) => !t.isCompleted).toList();
                    } else if (_filter == TaskCompletionFilter.Completed) {
                      tasks = tasks.where((t) => t.isCompleted).toList();
                    } else if (_filter == TaskCompletionFilter.Overdue) {
                      final now = DateTime.now();
                      tasks = tasks
                          .where(
                              (t) => !t.isCompleted && t.deadline.isBefore(now))
                          .toList();
                    } else if (_filter == TaskCompletionFilter.DueToday) {
                      final now = DateTime.now();
                      final todayMidnight =
                          DateTime(now.year, now.month, now.day);
                      final tomorrowMidnight =
                          todayMidnight.add(const Duration(days: 1));
                      tasks = tasks
                          .where((t) =>
                              !t.isCompleted &&
                              !t.deadline.isBefore(todayMidnight) &&
                              t.deadline.isBefore(tomorrowMidnight))
                          .toList();
                    }
                    tasks.sort((a, b) {
                      if (a.isCompleted != b.isCompleted) {
                        return a.isCompleted ? 1 : -1;
                      }
                      return a.deadline.compareTo(b.deadline);
                    });
                    if (tasks.isEmpty) {
                      final msg = (_selectedCategory != null ||
                              _filter != TaskCompletionFilter.All)
                          ? 'No tasks match your current filters.'
                          : 'No tasks yet. Tap + to add your first task.';
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.55)),
                            const SizedBox(height: 12),
                            Text(
                              msg,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8)),
                            )
                          ],
                        ),
                      );
                    }
                    return RepaintBoundary(
                      child: ListView.builder(
                        padding: EdgeInsets.all(
                            ResponsiveUtils.getDefaultPadding(context)
                                .toDouble()),
                        itemCount: tasks.length,
                        itemBuilder: (c, i) => _dismissible(tasks[i]),
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              onPressed: _showAddSheet,
              child: Icon(Icons.add_rounded,
                  color: Theme.of(context).colorScheme.onSecondary, size: 30),
            ),
    );
  }

  String _titleForFilter() {
    switch (_filter) {
      case TaskCompletionFilter.Incomplete:
        return 'My Active Tasks';
      case TaskCompletionFilter.Completed:
        return 'Completed Tasks';
      case TaskCompletionFilter.Overdue:
        return 'Overdue Tasks';
      case TaskCompletionFilter.DueToday:
        return 'Tasks Due Today';
      case TaskCompletionFilter.All:
        return 'All Tasks';
    }
  }

  void resetFilter() {
    setState(() {
      _filter = TaskCompletionFilter.All;
      _selectedCategory = null;
    });
  }

  void _showFilterSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).dialogLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort & Filter Tasks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filter by Status:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskCompletionFilter.values.map((f) {
                      final sel = _filter == f;
                      return ChoiceChip(
                        label: Text(_label(f)),
                        selected: sel,
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.8),
                        onSelected: (v) {
                          if (v) {
                            setDialogState(() => _filter = f);
                            setState(() => _filter = f);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Filter by Category:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<String>>(
                    stream: _categoryService.getUserCategories(),
                    builder: (context, snapshot) {
                      final categories = snapshot.data ?? [];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String?>(
                          value: _selectedCategory,
                          hint: const Text('All Categories'),
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ...categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setDialogState(() => _selectedCategory = value);
                            setState(() => _selectedCategory = value);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(scale: anim1, child: child);
      },
    );
  }

  Widget _dismissible(Task task) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 0,
          vertical: ResponsiveUtils.getColumnSpacing(context) * 0.5,
        ),
        child: Dismissible(
          key: ValueKey<String>(task.id ?? ''),
          direction: DismissDirection.horizontal,
          background: Container(
            decoration: BoxDecoration(
              color: task.isCompleted ? softBlue : mintGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(
              task.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
              color: const Color.fromARGB(255, 29, 222, 7),
              size: ResponsiveUtils.getIconSize(context) * 0.9,
            ),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(
              Icons.delete_forever_rounded,
              color: Colors.white,
              size: ResponsiveUtils.getIconSize(context) * 0.9,
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Left swipe - toggle complete without dismissing
              try {
                await widget.taskService
                    .updateTask(task.copyWith(isCompleted: !task.isCompleted));
                if (!mounted) return false;
                await showFloatingBottomDialog(
                  context,
                  message: task.isCompleted
                      ? 'Task marked incomplete.'
                      : 'Task completed! 🎉',
                  type: AppMessageType.success,
                );
              } catch (e) {
                if (mounted) {
                  await showFloatingBottomDialog(
                    context,
                    message: 'Failed to update task: $e',
                    type: AppMessageType.error,
                  );
                }
              }
              return false; // Don't dismiss after toggle
            } else if (direction == DismissDirection.endToStart) {
              // Right swipe - show delete confirmation
              final confirmed = await showConfirmationDialog(
                context,
                title: 'Delete Task?',
                message: 'Are you sure you want to delete "${task.title}"?',
                confirmButtonLabel: 'Delete',
                cancelButtonLabel: 'Cancel',
                confirmButtonColor: Colors.red,
              );
              return confirmed ?? false;
            }
            return false;
          },
          onDismissed: (dir) async {
            // Only called if confirmDismiss returned true (for delete only)
            if (dir == DismissDirection.endToStart) {
              final title = task.title;
              try {
                if (task.id != null) {
                  await widget.taskService.deleteTask(task.id!);
                }
                if (!mounted) return;
                await showFloatingBottomDialog(
                  context,
                  message: 'Task "$title" deleted.',
                  type: AppMessageType.success,
                );
              } catch (e) {
                if (mounted) {
                  await showFloatingBottomDialog(
                    context,
                    message: 'Failed to delete task: $e',
                    type: AppMessageType.error,
                  );
                }
              }
            }
          },
          child: _card(task),
        ),
      );

  Widget _card(Task task) {
    return TaskCard(
      title: task.title,
      deadline: task.deadline,
      priority: task.priority.name,
      energy: task.requiredEnergy.name,
      category: task.category,
      isCompleted: task.isCompleted,
      subtasks: task.subtasks
          .map((s) => {
                'id': s.id,
                'title': s.title,
                'isCompleted': s.isCompleted,
              })
          .toList(),
      onCheckChange: (v) async {
        if (v != null) {
          await widget.taskService.updateTask(task.copyWith(isCompleted: v));
        }
      },
      onSubtaskCheckChange: (subtaskId, isCompleted) async {
        final updatedSubtasks = task.subtasks
            .map((s) =>
                s.id == subtaskId ? s.copyWith(isCompleted: isCompleted) : s)
            .toList();
        await widget.taskService
            .updateTask(task.copyWith(subtasks: updatedSubtasks));
      },
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) =>
                TaskDetailPage(task: task, taskService: widget.taskService)),
      ),
    );
  }

  void _showAddSheet() {
    // Navigate to a full-screen add/edit task form instead of a bottom sheet
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddEditTaskScreen(
          task: null,
          taskService: widget.taskService,
        ),
      ),
    );
  }
}
