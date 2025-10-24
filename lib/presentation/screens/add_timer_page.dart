// lib/presentation/screens/add_timer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../application/timer_list_provider.dart';
import '../../../../../domain/entities/timer_model.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_timerToEdit != null ? 'Edit Timer' : 'Add New Timer'),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // 將 Column 替換為 ListView 以防止內容溢出，特別是添加新控件後
          child: ListView(
            children: <Widget>[
              // 計時器名稱輸入框
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

              // 時間輸入 (分鐘和秒)
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
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      // 移除 validator，在 _saveTimer 中統一校驗總時長
                      onSaved: (value) {
                        _inputMinutes = int.tryParse(value ?? "");
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
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (value) { // 可以保留對秒數的基礎驗證 (0-59)
                        if (value != null && value.isNotEmpty) {
                          final int? seconds = int.tryParse(value);
                          if (seconds == null || seconds < 0 || seconds > 59) {
                            return '0-59';
                          }
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _inputSeconds = int.tryParse(value ?? "");
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // 調整間距

              // --- 新增 CheckboxListTile ---
              CheckboxListTile(
                title: const Text("Alert until stopped"),
                subtitle: const Text("Plays sound and vibrates repeatedly until manually stopped."),
                value: _alertUntilStopped,
                onChanged: (bool? newValue) {
                  setState(() { // 使用 StatefulWidget 的 setState 來更新 UI
                    _alertUntilStopped = newValue ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                // Checkbox 在左邊
                contentPadding: EdgeInsets.zero,
                // 移除預設 padding 使其更緊湊
                activeColor: Theme
                    .of(context)
                    .colorScheme
                    .primary,
              ),
              // --- CheckboxListTile 結束 ---

              const SizedBox(height: 30),

              // 保存按鈕
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  foregroundColor: Theme
                      .of(context)
                      .colorScheme
                      .onPrimary,
                ),
                onPressed: _submitForm,
                child: const Text('Save Timer', style: TextStyle(fontSize: 16)),
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

      if (_timerToEdit == null) {
        final newTimer = TimerModel(
          id: _uuid.v4(),
          name: _timerName,
          totalDuration: Duration(minutes: minutes, seconds: seconds),
          alertUntilStopped: _alertUntilStopped,
        );
        ref.read(timerListProvider.notifier).addTimer(newTimer);
      } else {
        final updatedTimer = _timerToEdit!.copyWith(
          name: _timerName,
          totalDuration: Duration(minutes: minutes, seconds: seconds),
          alertUntilStopped: _alertUntilStopped,
        );
        ref.read(timerListProvider.notifier).editTimer(updatedTimer);
      }
      Navigator.of(context).pop();
    }
  }

  void _cancelTimer(String timerId) {
    if (_timerToEdit!.isRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(timerListProvider.notifier).pauseTimer(_timerToEdit!.id);
      });
    } else if (_timerToEdit!.isAlerting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(timerListProvider.notifier).resetTimer(_timerToEdit!.id);
      });
    }
  }
}