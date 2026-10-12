import '../domain/task.dart';

List<TaskItem> sampleTasks(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    TaskItem(
      id: 'task-1',
      title: 'Prepare interview notes',
      notes: 'Explain the repository and the offline file',
      priority: Priority.high,
      dueDate: today,
      category: 'Work',
      labels: const ['interview'],
      createdAt: today.subtract(const Duration(days: 2)),
    ),
    TaskItem(
      id: 'task-2',
      title: 'Renew passport photos',
      notes: 'Carry two copies',
      priority: Priority.medium,
      dueDate: today.subtract(const Duration(days: 3)),
      category: 'Personal',
      labels: const ['errand'],
      createdAt: today.subtract(const Duration(days: 6)),
    ),
    TaskItem(
      id: 'task-3',
      title: 'Read Riverpod docs',
      notes: 'AsyncNotifier and ProviderScope overrides',
      priority: Priority.medium,
      dueDate: today.add(const Duration(days: 4)),
      category: 'Learning',
      labels: const ['study', 'flutter'],
      createdAt: today.subtract(const Duration(days: 1)),
    ),
    TaskItem(
      id: 'task-4',
      title: 'Close weekly review',
      notes: '',
      priority: Priority.low,
      dueDate: today.subtract(const Duration(days: 1)),
      category: 'Work',
      labels: const ['planning'],
      completed: true,
      createdAt: today.subtract(const Duration(days: 8)),
    ),
    TaskItem(
      id: 'task-5',
      title: 'Sketch the task filters',
      notes: 'Open, done, and overdue',
      priority: Priority.high,
      category: 'Learning',
      labels: const ['design'],
      createdAt: today,
    ),
  ];
}
