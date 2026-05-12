import 'package:flutter/widgets.dart';

import '../dialogs/password_dialog.dart';
import '../providers/pdf_provider.dart';

/// Open a PDF through [PdfProvider.loadPdf], prompting the user for a
/// password whenever pdfrx reports the file is encrypted.
///
/// pdfrx invokes the password provider callback in a loop: each returned
/// non-null password is tried; null aborts the open. We surface a dialog
/// each time and flag the second-onward prompt as a retry so the UI can
/// show "incorrect password".
Future<bool> loadPdfInteractive(
  BuildContext context,
  PdfProvider provider,
  String path,
) {
  final fileName = Uri.file(path).pathSegments.last;
  var attempts = 0;
  return provider.loadPdf(
    path,
    passwordProvider: () async {
      if (!context.mounted) return null;
      final password = await showPasswordDialog(
        context,
        fileName: fileName,
        retry: attempts > 0,
      );
      attempts++;
      return password;
    },
  );
}
