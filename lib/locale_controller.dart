import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale _locale = const Locale('sq');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}

final localeController = LocaleController();
