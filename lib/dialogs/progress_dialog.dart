import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 취소 토큰 — 작업에서 주기적으로 확인하여 중단
class CancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// 작업 진행률 다이얼로그를 표시하고 작업 실행
///
/// 작업 완료 시 true, 취소/에러 시 false 반환
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
  ) task;

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
    final progress = _total > 0 ? _current / _total : 0.0;
    final percent = (progress * 100).round();

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.roundedXl),
          side: const BorderSide(color: AppTheme.borderSubtle),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foregroundPrimary,
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
                              backgroundColor: AppTheme.borderSubtle,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.accentPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      _cancelling
                          ? '취소 중...'
                          : '$_current / $_total 페이지 처리 중',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.foregroundMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderSubtle),
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
                    side: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                  onPressed: _cancelling ? null : _onCancel,
                  child: Text(
                    _cancelling ? '취소 중...' : '취소',
                    style: const TextStyle(color: AppTheme.foregroundSecondary),
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
