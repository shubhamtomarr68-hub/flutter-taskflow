import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/app.dart';
import 'package:taskflow/data/sample_tasks.dart';
import 'package:taskflow/data/stores.dart';

void main() {
  final now = DateTime(2026, 10, 12);

  testWidgets('shows sample tasks and blocks an empty title', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      TaskFlowApp(
        tasks: MemoryTaskRepository(sampleTasks(now)),
        preferences: MemoryPreferenceStore(),
        clock: () => now,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prepare interview notes'), findsOneWidget);
    expect(find.textContaining('does not sync'), findsOneWidget);
    expect(find.text('Overdue'), findsWidgets);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title.'), findsOneWidget);
  });

  testWidgets('failed load can be retried', (tester) async {
    final repository = MemoryTaskRepository(sampleTasks(now), failLoad: true);
    await tester.pumpWidget(
      TaskFlowApp(
        tasks: repository,
        preferences: MemoryPreferenceStore(),
        clock: () => now,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load tasks.'), findsOneWidget);

    repository.failLoad = false;
    await tester.tap(find.byKey(const Key('retry-load')));
    await tester.pumpAndSettle();
    expect(find.text('Prepare interview notes'), findsOneWidget);
  });

  testWidgets('theme toggle switches to dark', (tester) async {
    await tester.pumpWidget(
      TaskFlowApp(
        tasks: MemoryTaskRepository(sampleTasks(now)),
        preferences: MemoryPreferenceStore(),
        clock: () => now,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch theme'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
