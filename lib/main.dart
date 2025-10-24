import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/timer_list_provider.dart';
import 'domain/entities/timer_model.dart';
import 'domain/entities/timer_status.dart';
import 'presentation/screens/add_timer_page.dart';
import 'presentation/widgets/timer_card_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiuno Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // 建議使用 Material 3
      ),
      home: const TimerListPage(),
    );
  }
}

class TimerListPage extends ConsumerWidget {
  const TimerListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TimerModel> timers = ref.watch(timerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timers'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: timers.isEmpty ? const Center(
        child: Text('No Timer yet. Press + to add one!'),
      ) : ListView.builder(
        itemCount: timers.length,
        itemBuilder: (context, index) {
          final timer = timers[index];
          return TimerCardWidget(timer: timer);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddTimerPage()),
          );
        },
        tooltip: 'Add Timer',
        child: const Icon(Icons.add),
      ),
    );
  }
}
