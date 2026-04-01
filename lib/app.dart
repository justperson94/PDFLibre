import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/pdf_provider.dart';
import 'screens/empty_state_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'widgets/common/drop_overlay.dart';

class PDFLibreApp extends StatelessWidget {
  const PDFLibreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light(useMaterial3: false);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: AppTheme.surfacePrimary,
        textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: AppTheme.accentPrimary,
          surface: AppTheme.surfacePrimary,
          onSurface: AppTheme.foregroundPrimary,
        ),
      ),
      home: const _DropWrapper(),
    );
  }
}

class _DropWrapper extends StatefulWidget {
  const _DropWrapper();

  @override
  State<_DropWrapper> createState() => _DropWrapperState();
}

class _DropWrapperState extends State<_DropWrapper> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        final files = details.files;
        if (files.isEmpty) return;

        // 첫 번째 PDF 파일만 열기
        final pdfFiles =
            files.where((f) => f.path.toLowerCase().endsWith('.pdf'));
        if (pdfFiles.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF 파일만 열 수 있습니다')),
            );
          }
          return;
        }

        final provider = context.read<PdfProvider>();
        final messenger = ScaffoldMessenger.of(context);
        final success = await provider.loadPdf(pdfFiles.first.path);
        if (!success && mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('파일을 열 수 없습니다')),
          );
        }
      },
      child: Stack(
        children: [
          Consumer<PdfProvider>(
            builder: (context, pdf, _) {
              if (pdf.hasDocument) {
                return const MainScreen();
              }
              return const EmptyStateScreen();
            },
          ),
          if (_isDragging) const DropOverlay(),
        ],
      ),
    );
  }
}
