import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(l10n.timerListTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.95),
                colorScheme.secondaryContainer.withOpacity(0.75),
              ],
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceVariant.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.welcomeBack,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.timerCount(timers.length),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: timers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Container(
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: colorScheme.surface.withOpacity(0.75),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withOpacity(0.4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withOpacity(0.05),
                                    blurRadius: 24,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    size: 68,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.emptyStateTitle,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.emptyStateDescription,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 20),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const AddTimerPage(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: Text(l10n.emptyStateAction),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: timers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final timer = timers[index];
                            return Dismissible(
                              key: ValueKey(timer.id),
                              background: _buildDismissBackground(
                                alignment: Alignment.centerLeft,
                                color: Colors.red.shade400,
                                icon: Icons.delete,
                              ),
                              secondaryBackground: _buildDismissBackground(
                                alignment: Alignment.centerRight,
                                color: colorScheme.primary.withOpacity(0.8),
                                icon: Icons.edit,
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(l10n.deleteTimerTitle),
                                      content: Text(l10n.deleteTimerMessage(timer.name)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text(l10n.cancelButton),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: Text(l10n.deleteButton),
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
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTimerPage()),
          );
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(l10n.newTimerButton),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDismissBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignment == Alignment.centerLeft
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: alignment == Alignment.centerLeft
              ? Alignment.centerRight
              : Alignment.centerLeft,
          colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
        ),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon, color: Colors.white),
    );
  }
}