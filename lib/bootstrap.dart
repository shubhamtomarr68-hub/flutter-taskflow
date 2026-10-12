import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'data/stores.dart';
import 'domain/stores.dart';

/// Wires the on-device JSON files. Tests do not call this.
Future<({TaskRepository tasks, PreferenceStore preferences})>
createDeviceStores() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationDocumentsDirectory();
  return (
    tasks: FileTaskRepository(
      file: File('${directory.path}/taskflow_tasks.json'),
      clock: DateTime.now,
    ),
    preferences: FilePreferenceStore(
      file: File('${directory.path}/taskflow_preferences.json'),
    ),
  );
}
