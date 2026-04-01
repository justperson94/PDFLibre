import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/pdf_provider.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

/// PDF 분할 결과
class SplitResult {
  const SplitResult({required this.pageIndices, required this.splitIndividual});

  /// 0-based 페이지 인덱스
  final List<int> pageIndices;

  /// true: 페이지별로 개별 PDF, false: 하나의 PDF로 추출
  final bool splitIndividual;
}

/// PDF 분할 다이얼로그
Future<SplitResult?> showSplitDialog(BuildContext context) {
  return showDialog<SplitResult>(
    context: context,
    builder: (context) => const _SplitDialog(),
  );
}

class _SplitDialog extends StatefulWidget {
  const _SplitDialog();

  @override
  State<_SplitDialog> createState() => _SplitDialogState();
}

class _SplitDialogState extends State<_SplitDialog> {
  int _pageSelection = 0; // 0: 전체, 1: 현재, 2: 범위
  int _splitMethod = 0; // 0: 하나의 PDF, 1: 개별 PDF
  final _rangeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateRangeText();
  }

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }

  void _updateRangeText() {
    final pdf = context.read<PdfProvider>();
    switch (_pageSelection) {
      case 0:
        _rangeController.text = '1-${pdf.pageCount}';
      case 1:
        _rangeController.text = '${pdf.currentPage}';
    }
  }

  List<int> _getPageIndices() {
    final pdf = context.read<PdfProvider>();
    switch (_pageSelection) {
      case 0:
        return List.generate(pdf.pageCount, (i) => i);
      case 1:
        return [pdf.currentPage - 1];
      case 2:
        return PdfService.parsePageRange(_rangeController.text, pdf.pageCount);
      default:
        return [];
    }
  }

  void _onSplit() {
    List<int> indices;
    try {
      indices = _getPageIndices();
    } on FormatException catch (e) {
      _showError(e.message);
      return;
    } on RangeError catch (e) {
      _showError('${e.message}');
      return;
    }

    if (indices.isEmpty) {
      _showError('분할할 페이지를 선택해주세요');
      return;
    }

    Navigator.of(context).pop(
      SplitResult(pageIndices: indices, splitIndividual: _splitMethod == 1),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.roundedXl),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: SizedBox(
        width: 520,
        height: 560,
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppTheme.borderSubtle),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageSelection(),
                    const SizedBox(height: AppTheme.spacingXl),
                    _buildSplitMethod(),
                    const SizedBox(height: AppTheme.spacingXl),
                    _buildOutputFile(),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderSubtle),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Row(
        children: [
          const Text(
            'PDF 분할',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.foregroundPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x, size: 20),
            color: AppTheme.foregroundSecondary,
            tooltip: '닫기',
          ),
        ],
      ),
    );
  }

  Widget _buildPageSelection() {
    final pdf = context.read<PdfProvider>();
    const labels = ['전체 페이지', '현재 페이지', '범위 지정'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '페이지 선택',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.foregroundPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '총 ${pdf.pageCount} 페이지',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.foregroundMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: List.generate(3, (i) {
            final selected = _pageSelection == i;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSm),
              child: GestureDetector(
                onTap: () {
                  setState(() => _pageSelection = i);
                  if (i < 2) _updateRangeText();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.accentPrimary
                        : AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                    border: Border.all(
                      color: selected
                          ? AppTheme.accentPrimary
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? AppTheme.surfacePrimary
                          : AppTheme.foregroundSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextField(
          controller: _rangeController,
          enabled: _pageSelection == 2,
          decoration: InputDecoration(
            hintText: '예: 1-3, 5, 7-10',
            hintStyle: const TextStyle(
              color: AppTheme.foregroundMuted,
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppTheme.surfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              borderSide: const BorderSide(color: AppTheme.accentPrimary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitMethod() {
    return RadioGroup<int>(
      groupValue: _splitMethod,
      onChanged: (v) {
        if (v != null) setState(() => _splitMethod = v);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '분할 방식',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.foregroundPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildRadioOption(
            value: 0,
            title: '범위를 하나의 PDF로 추출',
            description: '선택한 페이지들을 하나의 새 PDF 파일로 만듭니다',
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildRadioOption(
            value: 1,
            title: '페이지별로 개별 PDF 생성',
            description: '각 페이지를 별도의 PDF 파일로 분리합니다',
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required int value,
    required String title,
    required String description,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.roundedMd),
      onTap: () => setState(() => _splitMethod = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<int>(
              value: value,
              activeColor: AppTheme.accentPrimary,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.foregroundMuted,
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

  Widget _buildOutputFile() {
    final pdf = context.read<PdfProvider>();
    final baseName = pdf.fileName.replaceAll('.pdf', '').replaceAll('.PDF', '');
    final outputName = _splitMethod == 0
        ? '${baseName}_분할.pdf'
        : '${baseName}_페이지별.pdf';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '출력 파일',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppTheme.roundedMd),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.fileText,
                    size: 18,
                    color: AppTheme.foregroundSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    outputName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foregroundPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: const [
                  Icon(
                    LucideIcons.info,
                    size: 14,
                    color: AppTheme.foregroundMuted,
                  ),
                  SizedBox(width: AppTheme.spacingXs),
                  Text(
                    '원본 파일은 변경되지 않습니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.foregroundMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 59,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(96, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              ),
              side: const BorderSide(color: AppTheme.borderSubtle),
              foregroundColor: AppTheme.foregroundSecondary,
            ),
            child: const Text('취소'),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          FilledButton.icon(
            onPressed: _onSplit,
            icon: const Icon(LucideIcons.scissors, size: 16),
            label: const Text(
              '분할하기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: AppTheme.surfacePrimary,
              minimumSize: const Size(120, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
