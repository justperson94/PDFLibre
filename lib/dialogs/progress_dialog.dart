import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';

/// Cancel token -- checked periodically by the task to abort
class CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// Shows a progress dialog and runs the task.
///
/// Returns true on completion, false on cancel/error.
Future<bool> runWithProgressDialog({
  required BuildContext context,
  required String title,
  required Future<void> Function(
    void Function(int current, int total) onProgress,
    CancelToken cancelToken,
  )
  task,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProgressDialog(title: title, task: task),
  );
  return result ?? false;
}

class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({required this.title, required this.task});

  final String title;
  final Future<void> Function(
    void Function(int current, int total) onProgress,
    CancelToken cancelToken,
  )
  task;

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  int _current = 0;
  int _total = 1;
  final _cancelToken = CancelToken();
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runTask());
  }

  Future<void> _runTask() async {
    try {
      await widget.task((current, total) {
        if (mounted && !_cancelling) {
          setState(() {
            _current = current;
            _total = total;
          });
        }
      }, _cancelToken);
      if (mounted) {
        Navigator.of(context).pop(!_cancelToken.isCancelled);
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  void _onCancel() {
    _cancelToken.cancel();
    setState(() => _cancelling = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final progress = _total > 0 ? _current / _total : 0.0;
    final percent = (progress * 100).round();

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: context.colors.surfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.roundedXl),
          side: BorderSide(color: context.colors.borderSubtle),
        ),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.colors.foregroundPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.roundedSm,
                            ),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: context.colors.borderSubtle,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.colors.accentPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colors.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      _cancelling
                          ? s.cancelling
                          : s.progressText(_current, _total),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.foregroundMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.colors.borderSubtle),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                    ),
                    side: BorderSide(color: context.colors.borderSubtle),
                  ),
                  onPressed: _cancelling ? null : _onCancel,
                  child: Text(
                    _cancelling ? s.cancelling : s.cancel,
                    style: TextStyle(color: context.colors.foregroundSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
