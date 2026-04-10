import 'package:flutter_test/flutter_test.dart';
import 'package:pdflibre/providers/settings_provider.dart';

void main() {
  group('SettingsProvider.applyFilenameRule', () {
    test('replaces {원본} token', () {
      expect(
        SettingsProvider.applyFilenameRule('{원본}_편집', originalBase: 'invoice'),
        'invoice_편집',
      );
    });

    test('replaces {페이지} token', () {
      expect(
        SettingsProvider.applyFilenameRule(
          '{원본}_{페이지}',
          originalBase: 'report',
          pageNumber: 5,
        ),
        'report_5',
      );
    });

    test('replaces {날짜} token with YYYY-MM-DD', () {
      final result = SettingsProvider.applyFilenameRule(
        '{날짜}_{원본}',
        originalBase: 'doc',
      );
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}_doc$').hasMatch(result), true);
    });

    test('missing page number becomes empty string', () {
      expect(
        SettingsProvider.applyFilenameRule('{원본}_{페이지}', originalBase: 'doc'),
        'doc_',
      );
    });

    test('combines all tokens', () {
      final result = SettingsProvider.applyFilenameRule(
        '{원본}_page{페이지}_{날짜}',
        originalBase: 'scan',
        pageNumber: 12,
      );
      expect(RegExp(r'^scan_page12_\d{4}-\d{2}-\d{2}$').hasMatch(result), true);
    });
  });

  group('SettingsProvider.sanitizeFilename', () {
    test('replaces Windows-unsafe characters with underscore', () {
      expect(
        SettingsProvider.sanitizeFilename('a\\b/c:d*e?f"g<h>i|j'),
        'a_b_c_d_e_f_g_h_i_j',
      );
    });

    test('strips trailing dots and spaces', () {
      expect(SettingsProvider.sanitizeFilename('name... '), 'name');
    });

    test('returns untitled for empty input', () {
      expect(SettingsProvider.sanitizeFilename(''), 'untitled');
      expect(SettingsProvider.sanitizeFilename('   '), 'untitled');
    });

    test('preserves Korean characters and digits', () {
      expect(SettingsProvider.sanitizeFilename('인보이스_123_편집'), '인보이스_123_편집');
    });

    test('strips control characters', () {
      expect(SettingsProvider.sanitizeFilename('a\u0001b\u001Fc'), 'a_b_c');
    });
  });
}
