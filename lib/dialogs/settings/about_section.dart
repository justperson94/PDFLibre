import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// 정보 section — app metadata, GitHub link, open-source licenses.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  static const _githubUrl = 'https://github.com/justperson94/PDFLibre';
  static const _buildNumber = 1;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      child: Column(
        children: [
          _buildBrand(s),
          const SizedBox(height: AppTheme.spacingLg),
          _buildInfoCard(context, s),
          const SizedBox(height: AppTheme.spacingMd),
          const Text(
            '© 2026 justperson94 · MIT License',
            style: TextStyle(fontSize: 11, color: AppTheme.foregroundMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand(S s) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/app_icon.png',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
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
        Text(
          s.appTagline,
          style: const TextStyle(fontSize: 12, color: AppTheme.foregroundMuted),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, S s) {
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
            label: s.version,
            value: '${AppConstants.appVersion} (build $_buildNumber)',
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          _InfoRow(label: s.platform, value: _platformLabel()),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          _InfoRow(
            label: 'GitHub',
            valueWidget: InkWell(
              onTap: () async {
                await Clipboard.setData(const ClipboardData(text: _githubUrl));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.githubCopied),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'github.com/justperson94/PDFLibre',
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
            label: s.openSourceLicenses,
            valueWidget: InkWell(
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
                applicationLegalese: '© 2026 justperson94 · MIT License',
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
                child: Text(
                  s.viewLicenses,
                  style: const TextStyle(
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
