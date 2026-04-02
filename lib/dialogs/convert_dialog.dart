import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../providers/pdf_provider.dart';
import '../services/file_service.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Image conversion result
class ConvertResult {
  const ConvertResult({
    required this.pageIndices,
    required this.format,
    required this.dpi,
    required this.quality,
    required this.outputDir,
  });
  final List<int> pageIndices;
  final String format;
  final int dpi;
  final int quality;
  final String outputDir;
}

/// Image conversion dialog
Future<ConvertResult?> showConvertDialog(BuildContext context) {
  return showDialog<ConvertResult>(
    context: context,
    builder: (context) => const _ConvertDialog(),
  );
}

class _ConvertDialog extends StatefulWidget {
  const _ConvertDialog();

  @override
  State<_ConvertDialog> createState() => _ConvertDialogState();
}

class _ConvertDialogState extends State<_ConvertDialog> {
  int _pageSelection = 0; // 0: all, 1: current, 2: range
  int _formatSelection = 0; // index into supportedImageFormats
  int _dpiSelection = 2; // index: 0=72, 1=150, 2=300, 3=600, 4=custom
  double _quality = 85;
  final _rangeController = TextEditingController();
  final _customDpiController = TextEditingController(text: '300');

  static const _dpiPresets = [72, 150, 300, 600];

  @override
  void dispose() {
    _rangeController.dispose();
    _customDpiController.dispose();
    super.dispose();
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

  int _getDpi() {
    if (_dpiSelection < _dpiPresets.length) {
      return _dpiPresets[_dpiSelection];
    }
    return int.tryParse(_customDpiController.text) ?? 300;
  }

  Future<void> _onConvert() async {
    // Validate page range
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
      _showError('변환할 페이지를 선택해주세요');
      return;
    }

    // Validate DPI
    final dpi = _getDpi();
    if (dpi < 1 || dpi > 2400) {
      _showError('DPI는 1~2400 사이의 값을 입력해주세요');
      return;
    }

    // Pick save directory
    final dir = await FileService.pickSaveDirectory();
    if (dir == null || !mounted) return;

    Navigator.of(context).pop(
      ConvertResult(
        pageIndices: indices,
        format: AppConstants.supportedImageFormats[_formatSelection],
        dpi: dpi,
        quality: _quality.round(),
        outputDir: dir,
      ),
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
        height: 620,
        child: Column(
          children: [
            // Header (60px)
            _buildHeader(),
            const Divider(height: 1, color: AppTheme.borderSubtle),

            // Body (scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageSelection(),
                    const SizedBox(height: AppTheme.spacingXl),
                    _buildFormatSelection(),
                    const SizedBox(height: AppTheme.spacingXl),
                    _buildDpiSelection(),
                    const SizedBox(height: AppTheme.spacingXl),
                    _buildQualitySlider(),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: AppTheme.borderSubtle),
            // Footer (59px)
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
            '이미지로 변환',
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
                onTap: () => setState(() => _pageSelection = i),
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
        if (_pageSelection == 2) ...[
          const SizedBox(height: AppTheme.spacingSm),
          TextField(
            controller: _rangeController,
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
      ],
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '출력 포맷',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children: List.generate(AppConstants.supportedImageFormats.length, (
            i,
          ) {
            final selected = _formatSelection == i;
            return GestureDetector(
              onTap: () => setState(() => _formatSelection = i),
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
                  AppConstants.supportedImageFormats[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? AppTheme.surfacePrimary
                        : AppTheme.foregroundSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDpiSelection() {
    final labels = [..._dpiPresets.map((d) => '$d'), '직접 입력'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '해상도 (DPI)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.foregroundPrimary,
              ),
            ),
            const Spacer(),
            Text(
              _dpiSelection < _dpiPresets.length
                  ? '${_dpiPresets[_dpiSelection]}'
                  : '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.foregroundSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children: List.generate(labels.length, (i) {
            final selected = _dpiSelection == i;
            return GestureDetector(
              onTap: () => setState(() => _dpiSelection = i),
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
            );
          }),
        ),
        if (_dpiSelection >= _dpiPresets.length) ...[
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _customDpiController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'DPI 값',
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
          ),
        ],
      ],
    );
  }

  Widget _buildQualitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '품질',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.foregroundPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${_quality.round()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.foregroundSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.accentPrimary,
            inactiveTrackColor: AppTheme.borderSubtle,
            thumbColor: AppTheme.accentPrimary,
            overlayColor: AppTheme.accentPrimary.withValues(alpha: 0.15),
            trackHeight: 4,
          ),
          child: Slider(
            min: 1,
            max: 100,
            value: _quality,
            onChanged: (v) => setState(() => _quality = v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '낮음',
              style: TextStyle(fontSize: 12, color: AppTheme.foregroundMuted),
            ),
            Text(
              '높음',
              style: TextStyle(fontSize: 12, color: AppTheme.foregroundMuted),
            ),
          ],
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
            onPressed: _onConvert,
            icon: const Icon(LucideIcons.image, size: 16),
            label: const Text(
              '변환하기',
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
