import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';

/// Theme mode preference.
enum AppThemeMode { system, light, dark }

/// Language preference.
enum AppLanguage { ko, en }

/// Where save dialogs should default to.
enum SaveLocationMode { askEveryTime, fixedFolder }

/// App-wide user settings persisted via `shared_preferences`.
///
/// Settings cover three sections:
/// - 일반: theme, language
/// - 파일 기본값: save location, filename rules per operation
/// - 정보: read-only (app metadata)
class SettingsProvider extends ChangeNotifier {
  SettingsProvider();

  // Storage keys
  static const _kThemeMode = 'settings.themeMode';
  static const _kLanguage = 'settings.language';
  static const _kSaveMode = 'settings.saveMode';
  static const _kSaveFolder = 'settings.saveFolder';
  static const _kFnRuleSave = 'settings.filenameRule.save';
  static const _kFnRuleSplit = 'settings.filenameRule.split';
  static const _kFnRuleConvert = 'settings.filenameRule.convert';

  // Defaults — mirror current app behavior so upgrading users see no change.
  static const String defaultFilenameRuleSave = '{원본}_편집';
  static const String defaultFilenameRuleSplit = '{원본}_{페이지}';
  static const String defaultFilenameRuleConvert = '{원본}_page{페이지}';

  AppThemeMode _themeMode = AppThemeMode.system;
  AppLanguage _language = AppLanguage.ko;
  SaveLocationMode _saveMode = SaveLocationMode.askEveryTime;
  String _saveFolder = '';
  String _filenameRuleSave = defaultFilenameRuleSave;
  String _filenameRuleSplit = defaultFilenameRuleSplit;
  String _filenameRuleConvert = defaultFilenameRuleConvert;
  bool _loaded = false;

  AppThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  SaveLocationMode get saveMode => _saveMode;
  String get saveFolder => _saveFolder;
  String get filenameRuleSave => _filenameRuleSave;
  String get filenameRuleSplit => _filenameRuleSplit;
  String get filenameRuleConvert => _filenameRuleConvert;
  bool get isLoaded => _loaded;

  /// Localized strings for the current language.
  S get s => S(_language);

  /// Load persisted settings from disk. Call once at app startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _decodeThemeMode(prefs.getString(_kThemeMode));
    _language = _decodeLanguage(prefs.getString(_kLanguage));
    _saveMode = _decodeSaveMode(prefs.getString(_kSaveMode));
    _saveFolder = prefs.getString(_kSaveFolder) ?? '';
    _filenameRuleSave =
        prefs.getString(_kFnRuleSave) ?? defaultFilenameRuleSave;
    _filenameRuleSplit =
        prefs.getString(_kFnRuleSplit) ?? defaultFilenameRuleSplit;
    _filenameRuleConvert =
        prefs.getString(_kFnRuleConvert) ?? defaultFilenameRuleConvert;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, lang.name);
  }

  Future<void> setSaveMode(SaveLocationMode mode) async {
    if (_saveMode == mode) return;
    _saveMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSaveMode, mode.name);
  }

  Future<void> setSaveFolder(String path) async {
    if (_saveFolder == path) return;
    _saveFolder = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSaveFolder, path);
  }

  Future<void> setFilenameRuleSave(String rule) async {
    if (_filenameRuleSave == rule) return;
    _filenameRuleSave = rule;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFnRuleSave, rule);
  }

  Future<void> setFilenameRuleSplit(String rule) async {
    if (_filenameRuleSplit == rule) return;
    _filenameRuleSplit = rule;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFnRuleSplit, rule);
  }

  Future<void> setFilenameRuleConvert(String rule) async {
    if (_filenameRuleConvert == rule) return;
    _filenameRuleConvert = rule;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFnRuleConvert, rule);
  }

  /// Reset output settings (save mode, folder, filename rules) to defaults.
  Future<void> resetOutputDefaults() async {
    _saveMode = SaveLocationMode.askEveryTime;
    _saveFolder = '';
    _filenameRuleSave = defaultFilenameRuleSave;
    _filenameRuleSplit = defaultFilenameRuleSplit;
    _filenameRuleConvert = defaultFilenameRuleConvert;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSaveMode);
    await prefs.remove(_kSaveFolder);
    await prefs.remove(_kFnRuleSave);
    await prefs.remove(_kFnRuleSplit);
    await prefs.remove(_kFnRuleConvert);
  }

  /// Apply a filename rule template with available tokens.
  ///
  /// Supported tokens:
  /// - `{원본}`: base filename without extension
  /// - `{페이지}`: 1-based page number (or empty string if not applicable)
  /// - `{날짜}`: today's date as `YYYY-MM-DD`
  ///
  /// The result is sanitized to strip characters that filesystems reject.
  static String applyFilenameRule(
    String template, {
    required String originalBase,
    int? pageNumber,
  }) {
    final now = DateTime.now();
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final pageStr = pageNumber?.toString() ?? '';
    final replaced = template
        .replaceAll('{원본}', originalBase)
        .replaceAll('{페이지}', pageStr)
        .replaceAll('{날짜}', dateStr);
    return sanitizeFilename(replaced);
  }

  /// Strip characters that are unsafe in filenames across platforms.
  static String sanitizeFilename(String name) {
    // Disallowed on Windows: \ / : * ? " < > |
    // Also strip control chars and trim trailing dots/spaces (Windows).
    final cleaned = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .trim()
        .replaceAll(RegExp(r'[\s.]+$'), '');
    return cleaned.isEmpty ? 'untitled' : cleaned;
  }

  AppThemeMode _decodeThemeMode(String? v) {
    switch (v) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  AppLanguage _decodeLanguage(String? v) {
    switch (v) {
      case 'en':
        return AppLanguage.en;
      case 'ko':
      default:
        return AppLanguage.ko;
    }
  }

  SaveLocationMode _decodeSaveMode(String? v) {
    switch (v) {
      case 'fixedFolder':
        return SaveLocationMode.fixedFolder;
      case 'askEveryTime':
      default:
        return SaveLocationMode.askEveryTime;
    }
  }
}
