// A page for creating or editing a timer.
//
// This widget allows the user to input a name, choose minutes and seconds,
// toggle whether the timer should alert until stopped, and save or update the
// timer. When editing an existing timer, the form is pre-filled and saving
// updates the existing entry.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../application/timer_list_provider.dart';
import '../../../domain/entities/timer_model.dart';

class AddTimerPage extends ConsumerStatefulWidget {
  const AddTimerPage({super.key, this.timerToEdit});

  final TimerModel? timerToEdit;

  @override
  ConsumerState<AddTimerPage> createState() => _AddTimerPageState();
}

class _AddTimerPageState extends ConsumerState<AddTimerPage> {
  final _formKey = GlobalKey<FormState>();
  String _timerName = '';
  int? _inputMinutes;
  int? _inputSeconds;
  bool _alertUntilStopped = false;
  final Uuid _uuid = const Uuid();
  TimerModel? _timerToEdit;

  @override
  void initState() {
    super.initState();
    _timerToEdit = widget.timerToEdit;
    if (_timerToEdit != null) {
      _cancelTimer(_timerToEdit!.id);
      _timerName = _timerToEdit!.name;
      _inputMinutes = _timerToEdit!.totalDuration.inMinutes;
      _inputSeconds = _timerToEdit!.totalDuration.inSeconds.remainder(60);
      _alertUntilStopped = _timerToEdit!.alertUntilStopped;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_timerToEdit != null ? 'Edit Timer' : 'Add New Timer'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.95),
                colorScheme.tertiaryContainer.withOpacity(0.75),
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
              colorScheme.surfaceVariant.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: colorScheme.surface.withOpacity(0.85),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timer details',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          initialValue: _timerName,
                          decoration: InputDecoration(
                            labelText: 'Timer Name',
                            hintText: 'E.g., Focus Session',
                            filled: true,
                            fillColor: colorScheme.surfaceVariant.withOpacity(0.35),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a timer name';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _timerName = value!;
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                initialValue: _inputMinutes?.toString(),
                                decoration: InputDecoration(
                                  labelText: 'Minutes',
                                  hintText: '0',
                                  filled: true,
                                  fillColor:
                                      colorScheme.surfaceVariant.withOpacity(0.35),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onSaved: (value) {
                                  _inputMinutes = int.tryParse(value ?? '');
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _inputSeconds?.toString(),
                                decoration: InputDecoration(
                                  labelText: 'Seconds',
                                  hintText: '0',
                                  filled: true,
                                  fillColor:
                                      colorScheme.surfaceVariant.withOpacity(0.35),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final int? seconds = int.tryParse(value);
                                    if (seconds == null || seconds < 0 || seconds > 59) {
                                      return '0-59';
                                    }
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _inputSeconds = int.tryParse(value ?? '');
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SwitchListTile.adaptive(
                          title: const Text('Alert until stopped'),
                          subtitle: const Text(
                            'Keeps playing sound and vibration until you manually stop it.',
                          ),
                          value: _alertUntilStopped,
                          onChanged: (bool newValue) {
                            setState(() {
                              _alertUntilStopped = newValue;
                            });
                          },
                          activeColor: colorScheme.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _timerToEdit == null ? 'Save Timer' : 'Update Timer',
                      style: textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final int minutes = _inputMinutes ?? 0;
      final int seconds = _inputSeconds ?? 0;
      final totalDuration = Duration(minutes: minutes, seconds: seconds);
      final notifier = ref.read(timerListProvider.notifier);
      if (_timerToEdit == null) {
        final newTimer = TimerModel(
          id: _uuid.v4(),
          name: _timerName,
          totalDuration: totalDuration,
          alertUntilStopped: _alertUntilStopped,
        );
        notifier.addTimer(newTimer);
      } else {
        final updatedTimer = _timerToEdit!.copyWith(
          name: _timerName,
          totalDuration: totalDuration,
          alertUntilStopped: _alertUntilStopped,
        );
        notifier.editTimer(updatedTimer);
      }
      Navigator.of(context).pop();
    }
  }

  void _cancelTimer(String timerId) {
    final notifier = ref.read(timerListProvider.notifier);
    if (_timerToEdit!.isRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.pauseTimer(_timerToEdit!.id);
      });
    } else if (_timerToEdit!.isAlerting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.resetTimer(_timerToEdit!.id);
      });
    }
  }
}