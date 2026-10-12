import 'package:equatable/equatable.dart';

enum Priority { low, medium, high }

enum TaskStatusFilter { all, open, done, overdue }

enum TaskSort { dueDate, priority, title, created }

const taskCategories = <String>['Work', 'Personal', 'Learning'];

class TaskItem extends Equatable {
  const TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.category,
    required this.createdAt,
    this.notes = '',
    this.dueDate,
    this.labels = const [],
    this.completed = false,
  });

  final String id;
  final String title;
  final String notes;
  final Priority priority;
  final DateTime? dueDate;
  final String category;
  final List<String> labels;
  final bool completed;
  final DateTime createdAt;

  TaskItem copyWith({
    String? title,
    String? notes,
    Priority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? category,
    List<String>? labels,
    bool? completed,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      category: category ?? this.category,
      labels: labels ?? this.labels,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'priority': priority.name,
    'dueDate': dueDate == null ? null : _formatDate(dueDate!),
    'category': category,
    'labels': labels,
    'completed': completed,
    'createdAt': _formatDate(createdAt),
  };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final due = json['dueDate'];
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String? ?? '',
      priority: Priority.values.byName(json['priority'] as String),
      dueDate: due is String ? _parseDate(due) : null,
      category: json['category'] as String,
      labels: (json['labels'] as List<dynamic>? ?? const []).cast<String>(),
      completed: json['completed'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    notes,
    priority,
    dueDate,
    category,
    labels,
    completed,
    createdAt,
  ];
}

class TaskFilter {
  const TaskFilter({
    this.query = '',
    this.status = TaskStatusFilter.all,
    this.sort = TaskSort.dueDate,
  });

  final String query;
  final TaskStatusFilter status;
  final TaskSort sort;

  TaskFilter copyWith({
    String? query,
    TaskStatusFilter? status,
    TaskSort? sort,
  }) {
    return TaskFilter(
      query: query ?? this.query,
      status: status ?? this.status,
      sort: sort ?? this.sort,
    );
  }
}

class TaskStats {
  const TaskStats({
    required this.open,
    required this.completed,
    required this.overdue,
  });

  final int open;
  final int completed;
  final int overdue;
}

class TaskRules {
  static bool isOverdue(TaskItem task, DateTime now) {
    final due = task.dueDate;
    if (task.completed || due == null) {
      return false;
    }
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    return dueDay.isBefore(today);
  }

  static TaskStats stats(List<TaskItem> tasks, DateTime now) {
    var open = 0;
    var completed = 0;
    var overdue = 0;
    for (final task in tasks) {
      if (task.completed) {
        completed++;
      } else {
        open++;
      }
      if (isOverdue(task, now)) {
        overdue++;
      }
    }
    return TaskStats(open: open, completed: completed, overdue: overdue);
  }

  static List<TaskItem> apply({
    required List<TaskItem> tasks,
    required TaskFilter filter,
    required DateTime now,
  }) {
    final needle = filter.query.trim().toLowerCase();
    final visible = tasks.where((task) {
      if (!_matchesStatus(task, filter.status, now)) {
        return false;
      }
      if (needle.isEmpty) {
        return true;
      }
      final haystack = [
        task.title,
        task.notes,
        task.category,
        ...task.labels,
      ].join(' ').toLowerCase();
      return haystack.contains(needle);
    }).toList();

    visible.sort((a, b) => _compare(a, b, filter.sort));
    return visible;
  }

  static String? validate({required String title, required String notes}) {
    if (title.trim().isEmpty) {
      return 'Enter a title.';
    }
    if (title.trim().length > 80) {
      return 'Title is too long.';
    }
    if (notes.trim().length > 280) {
      return 'Notes are too long.';
    }
    return null;
  }

  static List<String> parseLabels(String raw) {
    final labels = raw
        .split(',')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();
    if (labels.length > 6) {
      return labels.sublist(0, 6);
    }
    return labels;
  }
}

bool _matchesStatus(TaskItem task, TaskStatusFilter status, DateTime now) {
  switch (status) {
    case TaskStatusFilter.all:
      return true;
    case TaskStatusFilter.open:
      return !task.completed;
    case TaskStatusFilter.done:
      return task.completed;
    case TaskStatusFilter.overdue:
      return TaskRules.isOverdue(task, now);
  }
}

int _compare(TaskItem a, TaskItem b, TaskSort sort) {
  switch (sort) {
    case TaskSort.dueDate:
      return _compareDue(a, b);
    case TaskSort.priority:
      final byPriority = b.priority.index.compareTo(a.priority.index);
      if (byPriority != 0) {
        return byPriority;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    case TaskSort.title:
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    case TaskSort.created:
      return b.createdAt.compareTo(a.createdAt);
  }
}

int _compareDue(TaskItem a, TaskItem b) {
  if (a.dueDate == null && b.dueDate == null) {
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
  if (a.dueDate == null) {
    return 1;
  }
  if (b.dueDate == null) {
    return -1;
  }
  final byDate = a.dueDate!.compareTo(b.dueDate!);
  if (byDate != 0) {
    return byDate;
  }
  return a.title.toLowerCase().compareTo(b.title.toLowerCase());
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime _parseDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw FormatException('Invalid date: $value');
  }
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
