import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_page.dart';

enum PdfPageSize { a4, letter, fitImage }

enum PdfMargin { none, small, normal }

enum ScanQuality { low, medium, high }

extension PdfPageSizeLabel on PdfPageSize {
  String get label => const {
        PdfPageSize.a4: 'A4',
        PdfPageSize.letter: 'Letter',
        PdfPageSize.fitImage: 'Fit to image',
      }[this]!;
}

extension PdfMarginLabel on PdfMargin {
  String get label => const {
        PdfMargin.none: 'None',
        PdfMargin.small: 'Small',
        PdfMargin.normal: 'Normal',
      }[this]!;

  double get points => const {
        PdfMargin.none: 0.0,
        PdfMargin.small: 12.0,
        PdfMargin.normal: 28.0,
      }[this]!;
}

extension ScanQualityLabel on ScanQuality {
  String get label => const {
        ScanQuality.low: 'Low (smaller files)',
        ScanQuality.medium: 'Medium',
        ScanQuality.high: 'High',
      }[this]!;

  int get jpegQuality => const {
        ScanQuality.low: 60,
        ScanQuality.medium: 75,
        ScanQuality.high: 90,
      }[this]!;
}

class SettingsStore extends ChangeNotifier {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  late SharedPreferences _prefs;

  ThemeMode themeMode = ThemeMode.system;
  PdfPageSize pageSize = PdfPageSize.a4;
  PdfMargin margin = PdfMargin.small;
  ScanQuality quality = ScanQuality.high;
  PageFilter defaultFilter = PageFilter.original;
  bool confirmDelete = true;
  bool onboardingDone = false;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values[_prefs.getInt('themeMode') ?? 0];
    pageSize = PdfPageSize.values[_prefs.getInt('pageSize') ?? 0];
    margin = PdfMargin.values[_prefs.getInt('margin') ?? 1];
    quality = ScanQuality.values[_prefs.getInt('quality') ?? 2];
    defaultFilter = PageFilter.values[_prefs.getInt('defaultFilter') ?? 0];
    confirmDelete = _prefs.getBool('confirmDelete') ?? true;
    onboardingDone = _prefs.getBool('onboardingDone') ?? false;
  }

  void setThemeMode(ThemeMode value) {
    themeMode = value;
    _prefs.setInt('themeMode', value.index);
    notifyListeners();
  }

  void setPageSize(PdfPageSize value) {
    pageSize = value;
    _prefs.setInt('pageSize', value.index);
    notifyListeners();
  }

  void setMargin(PdfMargin value) {
    margin = value;
    _prefs.setInt('margin', value.index);
    notifyListeners();
  }

  void setQuality(ScanQuality value) {
    quality = value;
    _prefs.setInt('quality', value.index);
    notifyListeners();
  }

  void setDefaultFilter(PageFilter value) {
    defaultFilter = value;
    _prefs.setInt('defaultFilter', value.index);
    notifyListeners();
  }

  void setConfirmDelete(bool value) {
    confirmDelete = value;
    _prefs.setBool('confirmDelete', value);
    notifyListeners();
  }

  void finishOnboarding() {
    onboardingDone = true;
    _prefs.setBool('onboardingDone', true);
  }

  Future<void> reset() async {
    await _prefs.clear();
    await load();
    onboardingDone = true;
    _prefs.setBool('onboardingDone', true);
    notifyListeners();
  }
}
