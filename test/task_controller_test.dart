import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/data/sample_tasks.dart';
import 'package:taskflow/data/stores.dart';
import 'package:taskflow/domain/task.dart';
import 'package:taskflow/providers.dart';

void main() {
  final now = DateTime(2026, 10, 12);

  test('save failure keeps the previous tasks', () async {
    final repository = MemoryTaskRepository(sampleTasks(now));
    final container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    await container.read(taskListProvider.future);
    repository.failSave = true;
    final error = await container
        .read(taskListProvider.notifier)
        .saveTask(
          title: 'New task',
          notes: '',
          priority: Priority.low,
          dueDate: null,
          category: 'Work',
          labelsText: '',
        );
    expect(error, 'Could not save changes.');
    expect(container.read(taskListProvider).value, hasLength(5));
    expect(repository.tasks.any((task) => task.title == 'New task'), isFalse);
  });

  test('toggle and delete update the file-backed list in memory', () async {
    final repository = MemoryTaskRepository(sampleTasks(now));
    final container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    await container.read(taskListProvider.future);
    expect(
      await container.read(taskListProvider.notifier).toggleCompleted('task-1'),
      isNull,
    );
    expect(
      repository.tasks.firstWhere((task) => task.id == 'task-1').completed,
      isTrue,
    );
    expect(
      await container.read(taskListProvider.notifier).deleteTask('task-2'),
      isNull,
    );
    expect(repository.tasks.any((task) => task.id == 'task-2'), isFalse);
  });

  test('file repository round-trips and rejects a bad version', () async {
    final directory = await Directory.systemTemp.createTemp('taskflow');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/tasks.json');
    final repository = FileTaskRepository(file: file, clock: () => now);
    expect(await repository.load(), isNotEmpty);
    await repository.save(const []);
    expect(await repository.load(), isEmpty);
    await file.writeAsString('{"version": 9, "tasks": []}');
    expect(repository.load(), throwsA(isA<FormatException>()));
  });
}
