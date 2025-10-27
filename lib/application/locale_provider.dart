import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentLocaleProvider = StateProvider<Locale>((ref) => const Locale('en'));
