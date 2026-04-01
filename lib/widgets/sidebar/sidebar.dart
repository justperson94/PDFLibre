import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../providers/pdf_provider.dart';
import '../../theme/app_theme.dart';
import 'page_thumbnail.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.pageCount,
    required this.selectedPage,
    required this.onPageSelected,
  });

  final int pageCount;
  final int selectedPage;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    final pdf = context.watch<PdfProvider>();
    final document = pdf.document;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(
          right: BorderSide(color: AppTheme.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '페이지',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foregroundPrimary,
                  ),
                ),
                Text(
                  '$pageCount 페이지',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.foregroundMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: document != null
                ? _buildPageList(document, pdf)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageList(PdfDocument document, PdfProvider pdf) {
    return ListView.builder(
      itemCount: pageCount,
      itemBuilder: (context, index) {
        final page = index + 1;
        return PageThumbnail(
          key: ValueKey('thumb_${index}_v${pdf.version}'),
          page: document.pages[index],
          pageNumber: page,
          selected: page == selectedPage,
          onTap: () => onPageSelected(page),
          rotation: pdf.getPageRotation(index),
        );
      },
    );
  }
}
