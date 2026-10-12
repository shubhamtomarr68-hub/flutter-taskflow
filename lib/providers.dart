import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/sample_tasks.dart';
import 'domain/stores.dart';
import 'domain/task.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  throw StateError('TaskRepository was not provided');
});

final preferenceStoreProvider = Provider<PreferenceStore>((ref) {
  throw StateError('PreferenceStore was not provided');
});

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final taskFilterProvider = NotifierProvider<TaskFilterController, TaskFilter>(
  TaskFilterController.new,
);

class TaskFilterController extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => const TaskFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setStatus(TaskStatusFilter status) =>
      state = state.copyWith(status: status);

  void setSort(TaskSort sort) => state = state.copyWith(sort: sort);

  void clearQuery() => state = state.copyWith(query: '');
}

final taskListProvider =
    AsyncNotifierProvider<TaskListController, List<TaskItem>>(
      TaskListController.new,
    );

class TaskListController extends AsyncNotifier<List<TaskItem>> {
  @override
  Future<List<TaskItem>> build() {
    return ref.watch(taskRepositoryProvider).load();
  }

  Future<String?> saveTask({
    String? id,
    required String title,
    required String notes,
    required Priority priority,
    required DateTime? dueDate,
    required String category,
    required String labelsText,
  }) async {
    final error = TaskRules.validate(title: title, notes: notes);
    if (error != null) {
      return error;
    }
    final current = [...?state.value];
    final existingIndex = id == null
        ? -1
        : current.indexWhere((task) => task.id == id);
    if (id != null && existingIndex == -1) {
      return 'That task is no longer on this device.';
    }
    final existing = existingIndex == -1 ? null : current[existingIndex];
    final draft = TaskItem(
      id: id ?? _nextId(current),
      title: title.trim(),
      notes: notes.trim(),
      priority: priority,
      dueDate: dueDate,
      category: category,
      labels: TaskRules.parseLabels(labelsText),
      completed: existing?.completed ?? false,
      createdAt: existing?.createdAt ?? ref.read(clockProvider)(),
    );
    if (existingIndex == -1) {
      current.add(draft);
    } else {
      current[existingIndex] = draft;
    }
    return _persist(current);
  }

  Future<String?> toggleCompleted(String id) async {
    final current = [...?state.value];
    final index = current.indexWhere((task) => task.id == id);
    if (index == -1) {
      return 'That task is no longer on this device.';
    }
    final task = current[index];
    current[index] = task.copyWith(completed: !task.completed);
    return _persist(current);
  }

  Future<String?> deleteTask(String id) {
    final current = state.value?.where((task) => task.id != id).toList() ?? [];
    return _persist(current);
  }

  Future<String?> restoreSample() {
    return _persist(sampleTasks(ref.read(clockProvider)()));
  }

  Future<String?> _persist(List<TaskItem> tasks) async {
    try {
      await ref.read(taskRepositoryProvider).save(tasks);
    } catch (_) {
      return 'Could not save changes.';
    }
    state = AsyncData(tasks);
    return null;
  }

  String _nextId(List<TaskItem> tasks) {
    var max = 0;
    for (final task in tasks) {
      final match = RegExp(r'^task-(\d+)$').firstMatch(task.id);
      if (match == null) {
        continue;
      }
      final value = int.parse(match.group(1)!);
      if (value > max) {
        max = value;
      }
    }
    return 'task-${max + 1}';
  }
}

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  Future<void> load() async {
    try {
      state = await ref.read(preferenceStoreProvider).readTheme();
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    try {
      await ref.read(preferenceStoreProvider).writeTheme(next);
    } catch (_) {
      // Keep the choice for this session if the preference file cannot be written.
    }
  }
}
