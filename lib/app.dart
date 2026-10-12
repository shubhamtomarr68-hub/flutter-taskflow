import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/stores.dart';
import 'presentation/home_page.dart';
import 'providers.dart';
import 'theme.dart';

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({
    super.key,
    required this.tasks,
    required this.preferences,
    this.clock,
  });

  final TaskRepository tasks;
  final PreferenceStore preferences;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        taskRepositoryProvider.overrideWithValue(tasks),
        preferenceStoreProvider.overrideWithValue(preferences),
        if (clock != null) clockProvider.overrideWithValue(clock!),
      ],
      child: const TaskFlowRoot(),
    );
  }
}

class TaskFlowRoot extends ConsumerStatefulWidget {
  const TaskFlowRoot({super.key});

  @override
  ConsumerState<TaskFlowRoot> createState() => _TaskFlowRootState();
}

class _TaskFlowRootState extends ConsumerState<TaskFlowRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeModeProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: buildTaskFlowTheme(Brightness.light),
      darkTheme: buildTaskFlowTheme(Brightness.dark),
      themeMode: mode,
      home: const HomePage(),
    );
  }
}
