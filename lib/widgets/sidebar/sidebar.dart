import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../models/edit_command.dart';
import '../../providers/history_provider.dart';
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
                ? _buildPageList(context, document, pdf)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageList(
      BuildContext context, PdfDocument document, PdfProvider pdf) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: pageCount,
      onReorder: (oldIndex, newIndex) {
        // ReorderableListView removes then inserts, so adjust the index
        if (newIndex > oldIndex) newIndex--;
        if (oldIndex == newIndex) return;
        context.read<HistoryProvider>().execute(
              ReorderPageCommand(oldIndex: oldIndex, newIndex: newIndex),
              context.read<PdfProvider>(),
            );
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 4,
          color: AppTheme.sidebarBg,
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final displayPage = index + 1;
        final originalIndex = pdf.getOriginalPageIndex(index);
        return PageThumbnail(
          key: ValueKey('thumb_${pdf.pageOrder[index]}'),
          page: document.pages[originalIndex],
          pageNumber: originalIndex + 1,
          selected: displayPage == selectedPage,
          onTap: () => onPageSelected(displayPage),
          rotation: pdf.getPageRotation(index),
          dragIndex: index,
        );
      },
    );
  }
}
