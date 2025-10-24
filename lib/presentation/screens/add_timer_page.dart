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
      appBar: AppBar(
        title: Text(_timerToEdit != null ? 'Edit Timer' : 'Add New Timer'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _timerName,
                decoration: const InputDecoration(
                  labelText: 'Timer Name',
                  border: OutlineInputBorder(),
                  hintText: 'E.g., Kitchen Timer',
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
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      initialValue: _inputMinutes?.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      onSaved: (value) {
                        _inputMinutes = int.tryParse(value ?? '');
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: _inputSeconds?.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Seconds',
                        border: OutlineInputBorder(),
                        hintText: '0',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
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
              const SizedBox(height: 20),
              CheckboxListTile(
                title: const Text('Alert until stopped'),
                subtitle: const Text(
                  'Plays sound and vibrates repeatedly until manually stopped.',
                ),
                value: _alertUntilStopped,
                onChanged: (bool? newValue) {
                  setState(() {
                    _alertUntilStopped = newValue ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: colorScheme.primary,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                onPressed: _submitForm,
                child: Text(
                  'Save Timer',
                  style: textTheme.titleMedium,
                ),
              ),
            ],
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