import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/task.dart';
import '../providers.dart';
import 'task_sheet.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow'),
        actions: [
          IconButton(
            tooltip: 'Switch theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: const Icon(Icons.brightness_6),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) async {
              if (value == 'restore') {
                await _restore(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'restore',
                child: Text('Restore sample tasks'),
              ),
            ],
          ),
        ],
      ),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _ErrorBody(onRetry: () => ref.invalidate(taskListProvider)),
        data: (items) => _TaskBody(tasks: items),
      ),
      floatingActionButton: tasks.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => showTaskSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore sample tasks?'),
        content: const Text(
          'This replaces the tasks stored on this device. Nothing is sent to a server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final error = await ref.read(taskListProvider.notifier).restoreSample();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load tasks.'),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('retry-load'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskBody extends ConsumerWidget {
  const _TaskBody({required this.tasks});

  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final now = ref.watch(clockProvider)();
    final visible = TaskRules.apply(tasks: tasks, filter: filter, now: now);
    final stats = TaskRules.stats(tasks, now);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            'Tasks stay in a JSON file on this device. The app does not sync.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _Stat(label: 'Open', value: '${stats.open}'),
              _Stat(label: 'Done', value: '${stats.completed}'),
              _Stat(label: 'Overdue', value: '${stats.overdue}'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            key: const Key('task-search'),
            decoration: const InputDecoration(
              hintText: 'Search title, notes, or labels',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: ref.read(taskFilterProvider.notifier).setQuery,
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final status in TaskStatusFilter.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(_statusLabel(status)),
                    selected: filter.status == status,
                    onSelected: (_) =>
                        ref.read(taskFilterProvider.notifier).setStatus(status),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Text('Sort', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 8),
              DropdownButton<TaskSort>(
                value: filter.sort,
                items: const [
                  DropdownMenuItem(
                    value: TaskSort.dueDate,
                    child: Text('Due date'),
                  ),
                  DropdownMenuItem(
                    value: TaskSort.priority,
                    child: Text('Priority'),
                  ),
                  DropdownMenuItem(value: TaskSort.title, child: Text('Title')),
                  DropdownMenuItem(
                    value: TaskSort.created,
                    child: Text('Created'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref.read(taskFilterProvider.notifier).setSort(value);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('No tasks match this filter.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                  itemCount: visible.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _TaskTile(task: visible[index], now: now);
                  },
                ),
        ),
      ],
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task, required this.now});

  final TaskItem task;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdue = TaskRules.isOverdue(task, now);
    final scheme = Theme.of(context).colorScheme;
    final due = task.dueDate == null
        ? 'No due date'
        : 'Due ${task.dueDate!.day}/${task.dueDate!.month}';
    return ListTile(
      leading: Checkbox(
        value: task.completed,
        onChanged: (_) =>
            ref.read(taskListProvider.notifier).toggleCompleted(task.id),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        [
          task.category,
          task.priority.name,
          due,
          if (overdue) 'overdue',
          if (task.labels.isNotEmpty) task.labels.join(', '),
        ].join(' · '),
      ),
      trailing: IconButton(
        tooltip: 'Delete ${task.title}',
        onPressed: () => _confirmDelete(context, ref),
        icon: Icon(Icons.delete_outline, color: scheme.error),
      ),
      onTap: () => showTaskSheet(context, existing: task),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${task.title}” will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final error = await ref.read(taskListProvider.notifier).deleteTask(task.id);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(TaskStatusFilter status) {
  switch (status) {
    case TaskStatusFilter.all:
      return 'All';
    case TaskStatusFilter.open:
      return 'Open';
    case TaskStatusFilter.done:
      return 'Done';
    case TaskStatusFilter.overdue:
      return 'Overdue';
  }
}
