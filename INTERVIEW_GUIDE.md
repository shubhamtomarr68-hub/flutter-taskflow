# TaskFlow interview guide

## Architecture decisions

1. **The JSON file is the source of truth.** `FileTaskRepository` reads and writes `taskflow_tasks.json`. There is no network data source and no outbox. Offline behavior is "the device file is the app."

2. **Two notifiers.** `TaskListController` owns the saved tasks. `TaskFilterController` owns search, status, and sort. Search does not call `load()` again.

3. **Overdue is a calendar comparison.** `TaskRules.isOverdue` ignores the clock time. Completed tasks and tasks without a due date are not overdue. The same function feeds the badge, the filter, and the tile label.

4. **Save failure does not drop the list.** `_persist` writes first. On failure it returns `Could not save changes.` and leaves the previous `AsyncData` in place.

5. **Riverpod overrides instead of a service locator.** `TaskFlowApp` overrides `taskRepositoryProvider`. Production `main` passes the file repository. Tests pass `MemoryTaskRepository`.

## Questions

**Why Riverpod here and Cubit in FinFlow?**
They are separate repositories so each example stays consistent. TaskFlow's list is an async value plus a derived filter, which fits `AsyncNotifier` and a second `Notifier`. FinFlow's screen state is one cubit because the month, query, and ledger change together.

**What is not implemented in "offline-first"?**
Conflict resolution, sync, and retries against a server. Saying those exist would be false. The README states the file is the only store.

**How are labels stored?**
A JSON list of strings. The form accepts a comma-separated line. `parseLabels` trims, drops empties, de-duplicates, and keeps at most six.

**Why rewrite the whole file?**
The list is small and the format is versioned (`version: 1`). A row update would matter after a database exists. The repository interface does not have to change for the UI when that happens.

**How does theme persistence work?**
`ThemeController.load` reads the preference file after the first frame. `toggle` flips light/dark and writes the file. A bad preference file falls back to system theme.

## A hard bug, and the fix

`saveTask` used to call `firstWhere` for the existing task before checking that the id was still in the list. A missing id threw `StateError` instead of the message the UI shows.

The controller now finds the index first and returns `That task is no longer on this device.` when it is gone. The draft keeps the old `completed` flag and `createdAt` when the id exists.

## Error handling

- Missing file: write the sample list.
- Bad version or broken JSON: `FormatException`, then the page shows `Could not load tasks.` and Retry.
- Invalid title or notes: returned to the sheet, no write.
- Failed save: snackbar or sheet message, previous list kept.
- The raw exception is not rendered, so a file path does not land on screen.

## Testing

- `TaskRules` for overdue, stacked filters, due-date sort, and labels
- `TaskListController` in a `ProviderContainer` for failed save, toggle, and delete
- `FileTaskRepository` with a temp file
- Widget tests for the sample task, empty-title validation, retry, and dark theme

## Trade-offs

- Rewriting the JSON file is simple and will not scale to a large shared database.
- Filter state is in memory only.
- Sample tasks are generated from "today", so the overdue row moves with the date. Tests pass a fixed clock.

## What would change in production

- A real account and a sync repository with a tested conflict policy
- Encrypted storage if tasks were private work data
- Keep a database if the list needs queries
- Show a message when labels are truncated
- Device screenshots and a measured coverage report
