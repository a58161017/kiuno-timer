import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Simple localization class that provides English and Traditional Chinese
/// strings without relying on Flutter's generated localization tool.
class AppLocalizations {
  AppLocalizations._(this.locale);

  /// The locale that is actively used by this localization instance.
  final Locale locale;

  /// Delegate used by Flutter to load the localizations.
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Delegates consumed by [MaterialApp.localizationsDelegates].
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Locales supported by the application.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh', 'TW'),
  ];

  /// Lookup the closest [AppLocalizations] inside the widget tree.
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Resolves the locale that should be used by the app. Only locales using
  /// Traditional Chinese (Taiwan) are mapped to `zh_TW`; all other locales fall
  /// back to English.
  static Locale resolveLocale(Locale? locale, Iterable<Locale> supportedLocales) {
    final resolved = _resolveLocale(locale);
    return supportedLocales.firstWhere(
      (supported) =>
          supported.languageCode == resolved.languageCode &&
          (supported.countryCode ?? '') == (resolved.countryCode ?? ''),
      orElse: () => supportedLocales.first,
    );
  }

  /// Synchronously loads the localization data.
  static Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations._(_resolveLocale(locale)),
    );
  }

  static Locale _resolveLocale(Locale? locale) {
    if (locale == null) {
      return const Locale('en');
    }

    final languageCode = locale.languageCode.toLowerCase();
    final countryCode = (locale.countryCode ?? '').toUpperCase();
    final scriptCode = (locale.scriptCode ?? '').toLowerCase();

    if (languageCode == 'zh' && (countryCode == 'TW' || scriptCode == 'hant')) {
      return const Locale('zh', 'TW');
    }

    return const Locale('en');
  }

  String get _localeKey =>
      locale.languageCode == 'zh' ? 'zh_TW' : _fallbackLocaleKey;

  String get _fallbackLocaleKey => 'en';

  String _string(String key) {
    final values = _localizedValues[_localeKey];
    if (values != null && values.containsKey(key)) {
      return values[key]!;
    }
    final fallbackValues = _localizedValues[_fallbackLocaleKey]!;
    return fallbackValues[key] ?? '';
  }

  String get appTitle => _string('appTitle');
  String get timerListTitle => _string('timerListTitle');
  String get welcomeBack => _string('welcomeBack');
  String get emptyStateTitle => _string('emptyStateTitle');
  String get emptyStateDescription => _string('emptyStateDescription');
  String get emptyStateAction => _string('emptyStateAction');
  String get deleteTimerTitle => _string('deleteTimerTitle');
  String get cancelButton => _string('cancelButton');
  String get deleteButton => _string('deleteButton');
  String get newTimerButton => _string('newTimerButton');
  String get addTimerTitleNew => _string('addTimerTitleNew');
  String get addTimerTitleEdit => _string('addTimerTitleEdit');
  String get timerDetailsSection => _string('timerDetailsSection');
  String get timerNameLabel => _string('timerNameLabel');
  String get timerNameHint => _string('timerNameHint');
  String get timerNameEmptyError => _string('timerNameEmptyError');
  String get minutesLabel => _string('minutesLabel');
  String get secondsLabel => _string('secondsLabel');
  String get secondsRangeError => _string('secondsRangeError');
  String get alertUntilStoppedLabel => _string('alertUntilStoppedLabel');
  String get alertUntilStoppedDescription => _string('alertUntilStoppedDescription');
  String get saveTimer => _string('saveTimer');
  String get updateTimer => _string('updateTimer');
  String get singleAlertLabel => _string('singleAlertLabel');
  String get resumeAction => _string('resumeAction');
  String get startAction => _string('startAction');
  String get pauseAction => _string('pauseAction');
  String get stopAction => _string('stopAction');
  String get resetAction => _string('resetAction');
  String get editTimerTooltip => _string('editTimerTooltip');
  String get deleteTimerTooltip => _string('deleteTimerTooltip');
  String get timerStatusPending => _string('timerStatusPending');
  String get timerStatusRunning => _string('timerStatusRunning');
  String get timerStatusPaused => _string('timerStatusPaused');
  String get timerStatusFinished => _string('timerStatusFinished');
  String get timerStatusAlerting => _string('timerStatusAlerting');
  String get notificationTimerFinishedTicker =>
      _string('notificationTimerFinishedTicker');
  String get notificationTimerFinishedTitle =>
      _string('notificationTimerFinishedTitle');

  String timerCount(int count) {
    if (_localeKey == 'zh_TW') {
      return '您共有 $count 個計時器';
    }
    final suffix = count == 1 ? 'timer' : 'timers';
    return 'You have $count $suffix';
  }

  String deleteTimerMessage(String timerName) {
    if (_localeKey == 'zh_TW') {
      return '確定要刪除「$timerName」嗎？';
    }
    return 'Are you sure you want to delete "$timerName"?';
  }

  String notificationTimerFinishedBody(String timerName) {
    if (_localeKey == 'zh_TW') {
      return '$timerName 已經結束';
    }
    return '$timerName has completed';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    final resolved = AppLocalizations._resolveLocale(locale);
    return AppLocalizations.supportedLocales.any(
      (supported) =>
          supported.languageCode == resolved.languageCode &&
          (supported.countryCode ?? '') == (resolved.countryCode ?? ''),
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'appTitle': 'Kiuno Timer',
    'timerListTitle': 'My Timers',
    'welcomeBack': 'Welcome back',
    'emptyStateTitle': 'Create your first timer',
    'emptyStateDescription':
        'Organise workouts, focus sessions or reminders with beautifully crafted timers.',
    'emptyStateAction': 'Add timer',
    'deleteTimerTitle': 'Delete Timer',
    'cancelButton': 'Cancel',
    'deleteButton': 'Delete',
    'newTimerButton': 'New Timer',
    'addTimerTitleNew': 'Add New Timer',
    'addTimerTitleEdit': 'Edit Timer',
    'timerDetailsSection': 'Timer details',
    'timerNameLabel': 'Timer Name',
    'timerNameHint': 'E.g., Focus Session',
    'timerNameEmptyError': 'Please enter a timer name',
    'minutesLabel': 'Minutes',
    'secondsLabel': 'Seconds',
    'secondsRangeError': 'Enter a value between 0 and 59',
    'alertUntilStoppedLabel': 'Alert until stopped',
    'alertUntilStoppedDescription':
        'Keeps playing sound and vibration until you manually stop it.',
    'saveTimer': 'Save Timer',
    'updateTimer': 'Update Timer',
    'singleAlertLabel': 'Single alert',
    'resumeAction': 'Resume',
    'startAction': 'Start',
    'pauseAction': 'Pause',
    'stopAction': 'Stop',
    'resetAction': 'Reset',
    'editTimerTooltip': 'Edit Timer',
    'deleteTimerTooltip': 'Delete Timer',
    'timerStatusPending': 'Pending',
    'timerStatusRunning': 'Running',
    'timerStatusPaused': 'Paused',
    'timerStatusFinished': 'Finished',
    'timerStatusAlerting': 'Alerting',
    'notificationTimerFinishedTicker': 'Timer finished',
    'notificationTimerFinishedTitle': 'Timer finished',
  },
  'zh_TW': {
    'appTitle': 'Kiuno 計時器',
    'timerListTitle': '我的計時器',
    'welcomeBack': '歡迎回來',
    'emptyStateTitle': '建立第一個計時器',
    'emptyStateDescription': '運動、專注或提醒都可以用漂亮的計時器來管理。',
    'emptyStateAction': '新增計時器',
    'deleteTimerTitle': '刪除計時器',
    'cancelButton': '取消',
    'deleteButton': '刪除',
    'newTimerButton': '新增計時器',
    'addTimerTitleNew': '新增計時器',
    'addTimerTitleEdit': '編輯計時器',
    'timerDetailsSection': '計時器詳細資訊',
    'timerNameLabel': '計時器名稱',
    'timerNameHint': '例如：專注時段',
    'timerNameEmptyError': '請輸入計時器名稱',
    'minutesLabel': '分鐘',
    'secondsLabel': '秒',
    'secondsRangeError': '範圍需為 0-59',
    'alertUntilStoppedLabel': '持續提醒直到手動停止',
    'alertUntilStoppedDescription': '會持續播放聲音與震動，直到您手動停止。',
    'saveTimer': '儲存計時器',
    'updateTimer': '更新計時器',
    'singleAlertLabel': '提醒一次',
    'resumeAction': '繼續',
    'startAction': '開始',
    'pauseAction': '暫停',
    'stopAction': '停止',
    'resetAction': '重設',
    'editTimerTooltip': '編輯計時器',
    'deleteTimerTooltip': '刪除計時器',
    'timerStatusPending': '待開始',
    'timerStatusRunning': '進行中',
    'timerStatusPaused': '已暫停',
    'timerStatusFinished': '已完成',
    'timerStatusAlerting': '提醒中',
    'notificationTimerFinishedTicker': '計時完成',
    'notificationTimerFinishedTitle': '計時完成',
  },
};
