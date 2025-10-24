import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/timer_list_provider.dart';
import '../../../domain/entities/timer_model.dart';
import '../widgets/timer_card_widget.dart';
import 'add_timer_page.dart';

/// Displays a scrollable list of timers with modern interactions.
///
/// This page uses `Dismissible` widgets to allow swipe actions for editing
/// or deleting timers. A `FloatingActionButton.extended` provides a clear
/// entry point for adding new timers. When the timer list is empty, a
/// friendly placeholder encourages users to create their first timer.
class TimerListPage extends ConsumerWidget {
  const TimerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TimerModel> timers = ref.watch(timerListProvider);
    final notifier = ref.read(timerListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timers'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: timers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_empty,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No timers yet',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the button below to add your first timer.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: timers.length,
              itemBuilder: (context, index) {
                final timer = timers[index];
                return Dismissible(
                  key: ValueKey(timer.id),
                  background: Container(
                    color: Colors.red.shade400,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.blueGrey.shade400,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      // Swipe right to delete.
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Timer'),
                          content: Text('Are you sure you want to delete "${timer.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (result == true) {
                        notifier.removeTimer(timer.id);
                        return true;
                      }
                      return false;
                    } else {
                      // Swipe left to edit.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddTimerPage(timerToEdit: timer),
                        ),
                      );
                      return false;
                    }
                  },
                  child: TimerCardWidget(timer: timer),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTimerPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Timer'),
      ),
    );
  }
}