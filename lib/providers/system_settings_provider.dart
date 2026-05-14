import 'package:flutter/material.dart';
import '../models/system_settings.dart';
import '../services/database_service.dart';

class SystemSettingsProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  AppSystemSettings _settings = AppSystemSettings();
  bool _isLoading = true;

  SystemSettingsProvider() {
    _init();
  }

  AppSystemSettings get settings => _settings;
  bool get isLoading => _isLoading;

  void _init() {
    _db.getSystemSettings().listen((newSettings) {
      _settings = newSettings;
      _isLoading = false;
      notifyListeners();
    });
  }
}
