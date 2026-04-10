import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// 정보 section — app metadata, GitHub link, open-source licenses.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  static const _githubUrl = 'https://github.com/hwsong/PDFLibre';
  static const _buildNumber = 1;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        children: [
          _buildBrand(),
          const SizedBox(height: AppTheme.spacingLg),
          _buildInfoCard(context),
          const SizedBox(height: AppTheme.spacingMd),
          const Text(
            '© 2026 hwsong · MIT License',
            style: TextStyle(fontSize: 11, color: AppTheme.foregroundMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.accentPrimary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            LucideIcons.fileText,
            size: 40,
            color: AppTheme.surfacePrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'PDF',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.brandBlue,
              ),
            ),
            Text(
              'Libre',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXs),
        const Text(
          '빠르고 가벼운 데스크톱 PDF 도구',
          style: TextStyle(fontSize: 12, color: AppTheme.foregroundMuted),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      width: 440,
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        border: Border.all(color: AppTheme.borderSubtle),
        borderRadius: BorderRadius.circular(AppTheme.roundedMd),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: '버전',
            value: '${AppConstants.appVersion} (build $_buildNumber)',
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          _InfoRow(label: '플랫폼', value: _platformLabel()),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          _InfoRow(
            label: 'GitHub',
            valueWidget: InkWell(
              onTap: () async {
                await Clipboard.setData(const ClipboardData(text: _githubUrl));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GitHub 주소를 클립보드에 복사했습니다'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'github.com/hwsong/PDFLibre',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.brandBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(LucideIcons.copy, size: 12, color: AppTheme.brandBlue),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          _InfoRow(
            label: '오픈소스 라이선스',
            valueWidget: InkWell(
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
                applicationLegalese: '© 2026 hwsong · MIT License',
              ),
              borderRadius: BorderRadius.circular(AppTheme.roundedSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfacePrimary,
                  border: Border.all(color: AppTheme.borderSubtle),
                  borderRadius: BorderRadius.circular(AppTheme.roundedSm),
                ),
                child: const Text(
                  '라이선스 보기',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foregroundPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _platformLabel() {
    if (Platform.isMacOS) return 'macOS ${Platform.operatingSystemVersion}';
    if (Platform.isWindows) return 'Windows ${Platform.operatingSystemVersion}';
    if (Platform.isLinux) return 'Linux ${Platform.operatingSystemVersion}';
    return Platform.operatingSystem;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.valueWidget})
    : assert(value != null || valueWidget != null);

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.foregroundSecondary,
            ),
          ),
          const Spacer(),
          valueWidget ??
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foregroundPrimary,
                ),
              ),
        ],
      ),
    );
  }
}
