import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';

import '../dialogs/password_dialog.dart';
import '../providers/pdf_provider.dart';

/// In-memory cache of passwords that successfully unlocked a PDF in this
/// session. Keyed by file path so the user does not have to re-enter a
/// password when the same encrypted PDF is reopened by a different flow
/// (e.g. main viewer → merge screen → page-mix mode). The cache lives
/// only in RAM and is gone when the process exits.
class PdfPasswordCache {
  PdfPasswordCache._();

  static final Map<String, String> _store = {};

  static String? get(String key) => _store[key];
  static void put(String key, String value) => _store[key] = value;
  static void remove(String key) => _store.remove(key);
  static void clear() => _store.clear();
}

/// Mutable signal an open flow can read after [makePasswordProvider]
/// returned, to tell whether the user cancelled the password dialog.
class PasswordPromptOutcome {
  bool cancelled = false;
}

/// Result of [loadPdfInteractive].
enum PdfOpenResult {
  /// PDF opened successfully.
  success,

  /// The user cancelled the password dialog. Callers should treat this as
  /// a no-op (no error message, no recent-files cleanup).
  cancelled,

  /// The open failed for some other reason (corrupted, missing, etc.).
  error,
}

/// Build a [PdfPasswordProvider] that prompts the user with a password
/// dialog and tracks retry attempts so the second-onward prompt can flag
/// "incorrect password".
///
/// pdfrx invokes the provider in a loop: each non-null return is tried,
/// null aborts the open. Returns null itself once the user cancels.
///
/// When [cacheKey] is given (typically the file path), the first call
/// returns any cached password from [PdfPasswordCache] without prompting;
/// if pdfrx asks again the cache is invalidated and the dialog appears.
/// Successful prompts also cache the entered password.
///
/// Pass an [outcome] to be notified when the user cancels so callers can
/// suppress error UI for that case.
PdfPasswordProvider makePasswordProvider(
  BuildContext context, {
  required String fileName,
  String? cacheKey,
  PasswordPromptOutcome? outcome,
}) {
  var attempts = 0;
  return () async {
    // Attempt 0: try the cache.
    if (attempts == 0 && cacheKey != null) {
      final cached = PdfPasswordCache.get(cacheKey);
      if (cached != null) {
        attempts++;
        return cached;
      }
    }
    // Cache was tried (or unavailable) and failed — drop it before
    // prompting the user so we never resurrect a known-bad password.
    if (cacheKey != null && attempts > 0) {
      PdfPasswordCache.remove(cacheKey);
    }

    if (!context.mounted) {
      outcome?.cancelled = true;
      return null;
    }
    final password = await showPasswordDialog(
      context,
      fileName: fileName,
      retry: attempts > 0,
    );
    attempts++;
    if (password == null) {
      outcome?.cancelled = true;
    } else if (cacheKey != null) {
      PdfPasswordCache.put(cacheKey, password);
    }
    return password;
  };
}

/// Open a PDF through [PdfProvider.loadPdf], prompting the user for a
/// password whenever pdfrx reports the file is encrypted. Returns a
/// tri-state result so callers can distinguish a user cancellation from
/// a real load failure.
Future<PdfOpenResult> loadPdfInteractive(
  BuildContext context,
  PdfProvider provider,
  String path,
) async {
  final fileName = Uri.file(path).pathSegments.last;
  final outcome = PasswordPromptOutcome();
  final success = await provider.loadPdf(
    path,
    passwordProvider: makePasswordProvider(
      context,
      fileName: fileName,
      cacheKey: path,
      outcome: outcome,
    ),
  );
  if (success) return PdfOpenResult.success;
  return outcome.cancelled ? PdfOpenResult.cancelled : PdfOpenResult.error;
}
