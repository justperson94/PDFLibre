import 'dart:io';

import 'package:path/path.dart' as p;

/// Wraps the bundled `qpdf` CLI to add or remove passwords on a PDF.
///
/// pdfrx exposes [PdfPasswordProvider] for reading encrypted PDFs but does
/// not provide any write-side encryption API, so we ship qpdf as a sidecar
/// binary inside each platform's release artifact and invoke it via
/// [Process.run].
///
/// Layout per platform (set by the release workflow):
///
///   macOS:   PDFLibre.app/Contents/Resources/qpdf
///   Windows: \[exe_dir]/data/qpdf.exe
///   Linux:   \[exe_dir]/qpdf
class QpdfService {
  QpdfService._();

  static String? _resolvedPath;
  static bool? _isAvailable;

  /// Absolute path to the bundled qpdf binary, or null if not located.
  static String? get binaryPath {
    if (_resolvedPath != null) return _resolvedPath;
    final exe = Platform.resolvedExecutable;
    if (Platform.isMacOS) {
      // resolvedExecutable = ".../PDFLibre.app/Contents/MacOS/PDFLibre"
      final contents = p.dirname(p.dirname(exe));
      _resolvedPath = p.join(contents, 'Resources', 'qpdf');
    } else if (Platform.isWindows) {
      final dir = p.dirname(exe);
      _resolvedPath = p.join(dir, 'data', 'qpdf.exe');
    } else if (Platform.isLinux) {
      final dir = p.dirname(exe);
      _resolvedPath = p.join(dir, 'qpdf');
    }
    return _resolvedPath;
  }

  /// Returns true if the bundled binary exists and runs.
  static Future<bool> isAvailable() async {
    if (_isAvailable != null) return _isAvailable!;
    final path = binaryPath;
    if (path == null) return _isAvailable = false;
    final file = File(path);
    if (!file.existsSync()) return _isAvailable = false;
    try {
      final result = await Process.run(path, ['--version']);
      return _isAvailable = result.exitCode == 0;
    } catch (_) {
      return _isAvailable = false;
    }
  }

  /// Encrypt [inputPath] to [outputPath] with [userPassword].
  ///
  /// [ownerPassword] gates permission changes (printing, copying, etc.);
  /// if omitted it defaults to the user password so behaviour matches
  /// most consumer "password-protect" features.
  ///
  /// [currentPassword] is required when the input is already encrypted.
  /// Throws [QpdfException] on failure.
  static Future<void> setPassword({
    required String inputPath,
    required String outputPath,
    required String userPassword,
    String? ownerPassword,
    String? currentPassword,
  }) async {
    final owner = ownerPassword ?? userPassword;
    final args = <String>[
      if (currentPassword != null && currentPassword.isNotEmpty)
        '--password=$currentPassword',
      '--encrypt',
      userPassword,
      owner,
      '256',
      '--',
      inputPath,
      outputPath,
    ];
    await _run(args);
  }

  /// Decrypt [inputPath] to [outputPath] using [currentPassword].
  ///
  /// Throws [QpdfException] on failure (bad password, unsupported file).
  static Future<void> removePassword({
    required String inputPath,
    required String outputPath,
    required String currentPassword,
  }) async {
    final args = <String>[
      '--password=$currentPassword',
      '--decrypt',
      inputPath,
      outputPath,
    ];
    await _run(args);
  }

  static Future<void> _run(List<String> args) async {
    final path = binaryPath;
    if (path == null) {
      throw const QpdfException(QpdfError.notFound, 'qpdf binary not located');
    }
    if (!File(path).existsSync()) {
      throw QpdfException(QpdfError.notFound, 'qpdf not found at $path');
    }
    final result = await Process.run(path, args);
    // qpdf exit codes: 0 ok, 3 ok-with-warnings, anything else is an error.
    if (result.exitCode == 0 || result.exitCode == 3) return;
    final stderr = (result.stderr as String?)?.trim() ?? '';
    throw QpdfException(_classifyError(stderr), stderr);
  }

  static QpdfError _classifyError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid password') ||
        lower.contains('incorrect password')) {
      return QpdfError.badPassword;
    }
    if (lower.contains('no such file') ||
        lower.contains('cannot open input')) {
      return QpdfError.inputMissing;
    }
    return QpdfError.unknown;
  }
}

enum QpdfError { notFound, badPassword, inputMissing, unknown }

class QpdfException implements Exception {
  const QpdfException(this.code, this.message);
  final QpdfError code;
  final String message;

  @override
  String toString() => 'QpdfException($code): $message';
}
