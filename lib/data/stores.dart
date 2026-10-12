import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../domain/stores.dart';
import '../domain/task.dart';
import 'sample_tasks.dart';

class MemoryTaskRepository implements TaskRepository {
  MemoryTaskRepository(
    this.tasks, {
    this.failLoad = false,
    this.failSave = false,
  });

  List<TaskItem> tasks;
  bool failLoad;
  bool failSave;

  @override
  Future<List<TaskItem>> load() async {
    if (failLoad) {
      throw StateError('storage unavailable');
    }
    return tasks;
  }

  @override
  Future<void> save(List<TaskItem> next) async {
    if (failSave) {
      throw StateError('storage unavailable');
    }
    tasks = next;
  }
}

class MemoryPreferenceStore implements PreferenceStore {
  MemoryPreferenceStore({this.mode = ThemeMode.system});

  ThemeMode mode;

  @override
  Future<ThemeMode> readTheme() async => mode;

  @override
  Future<void> writeTheme(ThemeMode next) async {
    mode = next;
  }
}

/// The task list lives in one JSON file. There is no network client.
/// Offline means this file is the source of truth, including after a restart.
class FileTaskRepository implements TaskRepository {
  FileTaskRepository({required this.file, required this.clock});

  final File file;
  final DateTime Function() clock;

  @override
  Future<List<TaskItem>> load() async {
    if (!await file.exists()) {
      final sample = sampleTasks(clock());
      await save(sample);
      return sample;
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Task file is not a JSON object');
    }
    if (decoded['version'] != 1) {
      throw FormatException(
        'Unsupported task file version: ${decoded['version']}',
      );
    }
    final raw = decoded['tasks'];
    if (raw is! List) {
      throw const FormatException('Missing tasks');
    }
    return raw.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid task');
      }
      return TaskItem.fromJson(item);
    }).toList();
  }

  @override
  Future<void> save(List<TaskItem> tasks) async {
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      encoder.convert({
        'version': 1,
        'tasks': tasks.map((task) => task.toJson()).toList(),
      }),
    );
  }
}

class FilePreferenceStore implements PreferenceStore {
  FilePreferenceStore({required this.file});

  final File file;

  @override
  Future<ThemeMode> readTheme() async {
    if (!await file.exists()) {
      return ThemeMode.system;
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> || decoded['theme'] is! String) {
      throw const FormatException('Preference file is invalid');
    }
    return ThemeMode.values.byName(decoded['theme'] as String);
  }

  @override
  Future<void> writeTheme(ThemeMode mode) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'theme': mode.name}));
  }
}
