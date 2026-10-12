import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/domain/task.dart';

void main() {
  final today = DateTime(2026, 10, 12);
  final tasks = [
    TaskItem(
      id: 'task-1',
      title: 'Prepare interview notes',
      priority: Priority.high,
      category: 'Work',
      createdAt: today,
      dueDate: today,
      labels: const ['interview'],
    ),
    TaskItem(
      id: 'task-2',
      title: 'Renew passport photos',
      priority: Priority.low,
      category: 'Personal',
      createdAt: today,
      dueDate: today.subtract(const Duration(days: 2)),
    ),
    TaskItem(
      id: 'task-3',
      title: 'Close weekly review',
      priority: Priority.medium,
      category: 'Work',
      createdAt: today,
      dueDate: today.subtract(const Duration(days: 1)),
      completed: true,
    ),
    TaskItem(
      id: 'task-4',
      title: 'Sketch the task filters',
      notes: 'overdue should ignore this',
      priority: Priority.medium,
      category: 'Learning',
      createdAt: today,
    ),
  ];

  test('overdue ignores completed tasks and tasks without a due date', () {
    final stats = TaskRules.stats(tasks, today);
    expect(stats.overdue, 1);
    expect(stats.completed, 1);
    expect(stats.open, 3);
    expect(TaskRules.isOverdue(tasks[1], today), isTrue);
    expect(TaskRules.isOverdue(tasks[2], today), isFalse);
    expect(TaskRules.isOverdue(tasks[3], today), isFalse);
  });

  test('search matches labels and status filters stack', () {
    final found = TaskRules.apply(
      tasks: tasks,
      filter: const TaskFilter(
        query: 'interview',
        status: TaskStatusFilter.open,
      ),
      now: today,
    );
    expect(found.single.title, 'Prepare interview notes');
  });

  test('due-date sort puts missing dates last', () {
    final sorted = TaskRules.apply(
      tasks: tasks,
      filter: const TaskFilter(sort: TaskSort.dueDate),
      now: today,
    );
    expect(sorted.last.title, 'Sketch the task filters');
    expect(sorted.first.title, 'Renew passport photos');
  });

  test('validator and label parser', () {
    expect(TaskRules.validate(title: '  ', notes: ''), 'Enter a title.');
    expect(TaskRules.validate(title: 'Write tests', notes: ''), isNull);
    expect(TaskRules.parseLabels(' interview, study, interview '), [
      'interview',
      'study',
    ]);
  });
}
