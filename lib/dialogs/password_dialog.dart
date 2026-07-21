import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// Prompt the user for a PDF password.
///
/// Returns the typed password, or null if the user cancels.
/// [fileName] is shown so the user knows which file is being opened.
/// [retry] flips on after a wrong password; the title gets a red error line.
Future<String?> showPasswordDialog(
  BuildContext context, {
  required String fileName,
  bool retry = false,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PasswordDialog(fileName: fileName, retry: retry),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.fileName, required this.retry});

  final String fileName;
  final bool retry;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;

    return Dialog(
      backgroundColor: c.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.roundedXl),
        side: BorderSide(color: c.borderSubtle, width: 1),
      ),
      child: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.accentPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.lock,
                          color: c.accentPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.passwordDialogTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.foregroundPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: c.foregroundMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    s.passwordDialogSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.foregroundSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    obscureText: _obscure,
                    autofocus: true,
                    onSubmitted: (_) => _submit(),
                    inputFormatters: [
                      // Prevent newlines via paste.
                      FilteringTextInputFormatter.deny(RegExp(r'[\r\n]')),
                    ],
                    decoration: InputDecoration(
                      labelText: s.passwordLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                      ),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? s.passwordShow : s.passwordHide,
                        icon: Icon(
                          _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (widget.retry) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          size: 14,
                          color: c.danger,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            s.passwordWrong,
                            style: TextStyle(fontSize: 12, color: c.danger),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Divider(height: 1, color: c.borderSubtle),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(90, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                      ),
                      side: BorderSide(color: c.borderSubtle),
                      foregroundColor: c.foregroundSecondary,
                    ),
                    child: Text(s.cancel),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accentPrimary,
                      foregroundColor: c.surfacePrimary,
                      minimumSize: const Size(90, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                      ),
                    ),
                    child: Text(
                      s.passwordOpen,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
