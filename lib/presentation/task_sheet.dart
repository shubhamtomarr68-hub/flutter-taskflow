import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/task.dart';
import '../providers.dart';

Future<void> showTaskSheet(BuildContext context, {TaskItem? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => TaskSheet(existing: existing),
  );
}

class TaskSheet extends ConsumerStatefulWidget {
  const TaskSheet({super.key, this.existing});

  final TaskItem? existing;

  @override
  ConsumerState<TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends ConsumerState<TaskSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.existing?.notes ?? '',
  );
  late final TextEditingController _labels = TextEditingController(
    text: widget.existing?.labels.join(', ') ?? '',
  );
  late Priority _priority = widget.existing?.priority ?? Priority.medium;
  late String _category = widget.existing?.category ?? taskCategories.first;
  DateTime? _dueDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.existing?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _labels.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Add task' : 'Edit task',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('task-title'),
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Priority>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: Priority.low, child: Text('Low')),
                DropdownMenuItem(value: Priority.medium, child: Text('Medium')),
                DropdownMenuItem(value: Priority.high, child: Text('High')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _priority = value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in taskCategories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(
                          () => _dueDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          ),
                        );
                      }
                    },
                    child: Text(
                      _dueDate == null
                          ? 'Add due date'
                          : 'Due ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                    ),
                  ),
                ),
                if (_dueDate != null)
                  IconButton(
                    tooltip: 'Clear due date',
                    onPressed: () => setState(() => _dueDate = null),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labels,
              decoration: const InputDecoration(
                labelText: 'Labels',
                hintText: 'interview, study',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('task-save'),
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final error = await ref
        .read(taskListProvider.notifier)
        .saveTask(
          id: widget.existing?.id,
          title: _title.text,
          notes: _notes.text,
          priority: _priority,
          dueDate: _dueDate,
          category: _category,
          labelsText: _labels.text,
        );
    if (!mounted) {
      return;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }
}
