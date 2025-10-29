// Clean minimal TaskListScreen (fresh) - no hidden characters
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import 'add_edit_task_screen.dart';

enum TaskCompletionFilter { all, incomplete, completed, overdue }

class TaskListScreen extends StatefulWidget {
  final TaskService taskService;
  final TaskCompletionFilter? initialFilter;
  const TaskListScreen({super.key, required this.taskService, this.initialFilter});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskCategory? _selectedCategory;
  late TaskCompletionFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? TaskCompletionFilter.all;
  }

  String _label(Enum e) => e.toString().split('.').last;
  String _cat(TaskCategory c) => _label(c).toUpperCase();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_titleForFilter(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: _selectedCategory != null || _filter != TaskCompletionFilter.incomplete
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _showFilterSheet,
          )
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please log in to view tasks.'))
          : StreamBuilder<List<Task>>(
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
                  tasks = tasks.where((t) => t.category == _selectedCategory).toList();
                }
                if (_filter == TaskCompletionFilter.incomplete) {
                  tasks = tasks.where((t) => !t.isCompleted).toList();
                } else if (_filter == TaskCompletionFilter.completed) {
                  tasks = tasks.where((t) => t.isCompleted).toList();
                } else if (_filter == TaskCompletionFilter.overdue) {
                  final now = DateTime.now();
                  tasks = tasks.where((t) => !t.isCompleted && t.deadline.isBefore(now)).toList();
                }
                tasks.sort((a, b) {
                  if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
                  return a.deadline.compareTo(b.deadline);
                });
                if (tasks.isEmpty) {
                  final msg = (_selectedCategory != null || _filter != TaskCompletionFilter.all)
                      ? 'No tasks match your current filters.'
                      : 'No tasks yet. Tap + to add your first task.';
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.55)),
                        const SizedBox(height: 12),
                        Text(
                          msg,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                        )
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 8),
                  itemCount: tasks.length,
                  itemBuilder: (c, i) => _dismissible(tasks[i]),
                );
              },
            ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              onPressed: _showAddSheet,
              child: Icon(Icons.add_rounded, color: Theme.of(context).colorScheme.onSecondary, size: 30),
            ),
    );
  }

  String _titleForFilter() {
    switch (_filter) {
      case TaskCompletionFilter.incomplete:
        return 'My Active Tasks';
      case TaskCompletionFilter.completed:
        return 'Completed Tasks';
      case TaskCompletionFilter.overdue:
        return 'Overdue Tasks';
      case TaskCompletionFilter.all:
        return 'All Tasks';
    }
  }

  void resetFilter() {
    setState(() {
      _filter = TaskCompletionFilter.all;
      _selectedCategory = null;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Filters',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            const Divider(),
            const Text('Completion Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Wrap(
              spacing: 8,
              children: TaskCompletionFilter.values.map((f) {
                final sel = _filter == f;
                return ChoiceChip(
                  label: Text(_label(f)),
                  selected: sel,
                  selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  onSelected: (v) {
                    if (v) {
                      setState(() => _filter = f);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            DropdownButton<TaskCategory?>(
              value: _selectedCategory,
              isExpanded: true,
              hint: const Text('All Categories'),
              items: [
                const DropdownMenuItem<TaskCategory?>(value: null, child: Text('All Categories')),
                ...TaskCategory.values.map((c) => DropdownMenuItem<TaskCategory>(value: c, child: Text(_cat(c)))),
              ],
              onChanged: (v) {
                setState(() => _selectedCategory = v);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _dismissible(Task task) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Dismissible(
          key: Key(task.id ?? UniqueKey().toString()),
          direction: DismissDirection.horizontal,
          background: _swipeBg(
            color: task.isCompleted ? softBlue : mintGreen,
            icon: task.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
            alignment: Alignment.centerLeft,
          ),
          secondaryBackground: _swipeBg(
            color: Colors.red.shade400,
            icon: Icons.delete_forever_rounded,
            alignment: Alignment.centerRight,
          ),
          onDismissed: (dir) async {
            if (dir == DismissDirection.startToEnd) {
              await widget.taskService.updateTask(task.copyWith(isCompleted: !task.isCompleted));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(task.isCompleted ? 'Task marked incomplete.' : 'Task completed! 🎉')));
            } else if (dir == DismissDirection.endToStart) {
              final title = task.title;
              if (task.id != null) await widget.taskService.deleteTask(task.id!);
              if (!mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Task "$title" deleted.')));
            }
          },
          child: _card(task),
        ),
      );

  Widget _swipeBg({required Color color, required IconData icon, required Alignment alignment}) => Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(icon, color: Colors.white, size: 30),
      );

  Widget _card(Task task) {
    late final Color pColor;
    switch (task.priority) {
      case TaskPriority.high:
        pColor = Colors.redAccent;
        break;
      case TaskPriority.medium:
        pColor = Colors.orange;
        break;
      case TaskPriority.low:
        pColor = softBlue;
        break;
    }
    return Card(
      elevation: task.isCompleted ? 1 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: task.isCompleted
          ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)
          : Theme.of(context).cardTheme.color,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (v) async {
            if (v != null) {
              await widget.taskService.updateTask(task.copyWith(isCompleted: v));
            }
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          activeColor: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: task.isCompleted
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                : Theme.of(context).colorScheme.onSurface,
            decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Due: ${DateFormat('MMM dd, hh:mm a').format(task.deadline)}',
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 4),
            Row(children: [
              _chip(_label(task.priority), pColor.withOpacity(0.2), pColor.withOpacity(0.8)),
              const SizedBox(width: 8),
              _chip(
                  _label(task.category),
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.8)),
            ])
          ],
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).unselectedWidgetColor),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (c) => AddEditTaskScreen(task: task, taskService: widget.taskService)),
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
      );

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