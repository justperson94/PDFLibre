import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/pdf_provider.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

/// PDF split result
class SplitResult {
  const SplitResult({required this.pageIndices, required this.splitIndividual});

  /// 0-based page indices
  final List<int> pageIndices;

  /// true: individual PDF per page, false: extract as single PDF
  final bool splitIndividual;
}

/// PDF split dialog
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
  int _pageSelection = 0; // 0: all, 1: current, 2: range
  int _splitMethod = 0; // 0: single PDF, 1: individual PDFs
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
      _showError(S.of(context).selectPagesForSplit);
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
      backgroundColor: context.colors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.roundedXl),
        side: BorderSide(color: context.colors.borderSubtle),
      ),
      child: SizedBox(
        width: 520,
        height: 560,
        child: Column(
          children: [
            _buildHeader(),
            Divider(height: 1, color: context.colors.borderSubtle),
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
            Divider(height: 1, color: context.colors.borderSubtle),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final s = context.s;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Row(
        children: [
          Text(
            s.splitTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.colors.foregroundPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x, size: 20),
            color: context.colors.foregroundSecondary,
            tooltip: s.close,
          ),
        ],
      ),
    );
  }

  Widget _buildPageSelection() {
    final pdf = context.read<PdfProvider>();
    final s = context.s;
    final labels = [s.allPages, s.currentPage, s.pageRange];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              s.pageSelection,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.foregroundPrimary,
              ),
            ),
            const Spacer(),
            Text(
              s.totalPages(pdf.pageCount),
              style: TextStyle(
                fontSize: 12,
                color: context.colors.foregroundMuted,
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
                        ? context.colors.accentPrimary
                        : context.colors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppTheme.roundedMd),
                    border: Border.all(
                      color: selected
                          ? context.colors.accentPrimary
                          : context.colors.borderSubtle,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? context.colors.surfacePrimary
                          : context.colors.foregroundSecondary,
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
            hintText: s.rangeHint,
            hintStyle: TextStyle(
              color: context.colors.foregroundMuted,
              fontSize: 13,
            ),
            filled: true,
            fillColor: context.colors.surfaceSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              borderSide: BorderSide(color: context.colors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              borderSide: BorderSide(color: context.colors.borderSubtle),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              borderSide: BorderSide(color: context.colors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              borderSide: BorderSide(color: context.colors.accentPrimary),
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
    final s = context.s;
    return RadioGroup<int>(
      groupValue: _splitMethod,
      onChanged: (v) {
        if (v != null) setState(() => _splitMethod = v);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.splitMethod,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.colors.foregroundPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildRadioOption(
            value: 0,
            title: s.splitSinglePdf,
            description: s.splitSinglePdfDesc,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildRadioOption(
            value: 1,
            title: s.splitPerPage,
            description: s.splitPerPageDesc,
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
              activeColor: context.colors.accentPrimary,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colors.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.foregroundMuted,
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
    final s = context.s;
    final baseName = pdf.fileName.replaceAll('.pdf', '').replaceAll('.PDF', '');
    final outputName = _splitMethod == 0
        ? s.splitDefaultName(baseName)
        : s.splitPerPageName(baseName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.outputFile,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.colors.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: context.colors.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppTheme.roundedMd),
            border: Border.all(color: context.colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.fileText,
                    size: 18,
                    color: context.colors.foregroundSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    outputName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colors.foregroundPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 14,
                    color: context.colors.foregroundMuted,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    s.originalUnchanged,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.foregroundMuted,
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
    final s = context.s;
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
              side: BorderSide(color: context.colors.borderSubtle),
              foregroundColor: context.colors.foregroundSecondary,
            ),
            child: Text(s.cancel),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          FilledButton.icon(
            onPressed: _onSplit,
            icon: const Icon(LucideIcons.scissors, size: 16),
            label: Text(
              s.splitAction,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.accentPrimary,
              foregroundColor: context.colors.surfacePrimary,
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
