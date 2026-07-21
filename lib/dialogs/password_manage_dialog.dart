import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// Result of [showSetPasswordDialog] — the chosen password, or null on
/// cancel.
typedef SetPasswordResult = String?;

/// Prompt the user for a new password to apply to the current PDF.
///
/// Used by both "set password" (file was not encrypted) and
/// "change password" (file already encrypted; we already have the old
/// password cached internally).
Future<SetPasswordResult> showSetPasswordDialog(
  BuildContext context, {
  required bool isChange,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SetPasswordDialog(isChange: isChange),
  );
}

/// Confirm dialog before removing the password.
Future<bool> showRemovePasswordConfirm(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _RemovePasswordDialog(),
  );
  return result == true;
}

class _SetPasswordDialog extends StatefulWidget {
  const _SetPasswordDialog({required this.isChange});

  final bool isChange;

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final _newCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  final _newFocus = FocusNode();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _newFocus.requestFocus(),
    );
  }

  @override
  void dispose() {
    _newCtl.dispose();
    _confirmCtl.dispose();
    _newFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final s = context.s;
    final nw = _newCtl.text;
    final cf = _confirmCtl.text;
    if (nw.isEmpty) {
      setState(() => _error = s.passwordEmpty);
      return;
    }
    if (nw != cf) {
      setState(() => _error = s.passwordMismatch);
      return;
    }
    Navigator.of(context).pop(nw);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = context.colors;
    final title = s.passwordSetTitle;
    final subtitle = s.passwordSetSubtitle;

    return Dialog(
      backgroundColor: c.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.roundedXl),
        side: BorderSide(color: c.borderSubtle, width: 1),
      ),
      child: SizedBox(
        width: 460,
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
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.foregroundPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
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
                  _PasswordField(
                    label: s.passwordNew,
                    controller: _newCtl,
                    focusNode: _newFocus,
                    obscure: _obscureNew,
                    onToggleObscure: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    onSubmitted: (_) {
                      FocusScope.of(context).nextFocus();
                    },
                    showHint: s.passwordShow,
                    hideHint: s.passwordHide,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _PasswordField(
                    label: s.passwordConfirm,
                    controller: _confirmCtl,
                    obscure: _obscureConfirm,
                    onToggleObscure: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onSubmitted: (_) => _submit(),
                    showHint: s.passwordShow,
                    hideHint: s.passwordHide,
                  ),
                  if (_error != null) ...[
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
                            _error!,
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
                      s.passwordApply,
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

class _RemovePasswordDialog extends StatelessWidget {
  const _RemovePasswordDialog();

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
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c.accentPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.unlock,
                      color: c.accentPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    s.passwordRemoveTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    s.passwordRemoveSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.foregroundSecondary,
                      height: 1.5,
                    ),
                  ),
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
                    onPressed: () => Navigator.of(context).pop(false),
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
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accentPrimary,
                      foregroundColor: c.surfacePrimary,
                      minimumSize: const Size(90, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                      ),
                    ),
                    child: Text(
                      s.passwordApply,
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmitted,
    required this.showHint,
    required this.hideHint,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onSubmitted;
  final String showHint;
  final String hideHint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      onSubmitted: onSubmitted,
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[\r\n]'))],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.roundedMd),
        ),
        suffixIcon: IconButton(
          tooltip: obscure ? showHint : hideHint,
          icon: Icon(obscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}
