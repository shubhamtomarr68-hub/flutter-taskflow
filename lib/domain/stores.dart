import 'package:flutter/material.dart';

import 'task.dart';

abstract class TaskRepository {
  Future<List<TaskItem>> load();

  Future<void> save(List<TaskItem> tasks);
}

abstract class PreferenceStore {
  Future<ThemeMode> readTheme();

  Future<void> writeTheme(ThemeMode mode);
}
