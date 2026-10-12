import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  final stores = await createDeviceStores();
  runApp(TaskFlowApp(tasks: stores.tasks, preferences: stores.preferences));
}
