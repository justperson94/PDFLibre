import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
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
    final s = context.s;
    final pdf = context.watch<PdfProvider>();
    final document = pdf.document;

    final colors = context.colors;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colors.sidebarBg,
        border: Border(
          right: BorderSide(color: colors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.borderSubtle, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.page,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.foregroundPrimary,
                  ),
                ),
                Text(
                  '$pageCount',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.foregroundMuted,
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
    BuildContext context,
    PdfDocument document,
    PdfProvider pdf,
  ) {
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
        return Material(elevation: 4, color: context.colors.sidebarBg, child: child);
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
