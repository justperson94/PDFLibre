import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/pdf_provider.dart';
import 'screens/empty_state_screen.dart';
import 'screens/main_screen.dart';
import 'screens/merge_screen.dart';
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
      onDragEntered: (_) {
        // Skip overlay if a PDF is already open
        if (context.read<PdfProvider>().hasDocument) return;
        setState(() => _isDragging = true);
      },
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        final files = details.files;
        if (files.isEmpty) return;

        final pdfPaths = files
            .where((f) => f.path.toLowerCase().endsWith('.pdf'))
            .map((f) => f.path)
            .toList();

        if (pdfPaths.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF 파일만 열 수 있습니다')),
            );
          }
          return;
        }

        // Multiple PDFs -> navigate to merge screen
        if (pdfPaths.length > 1) {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MergeScreen(initialPaths: pdfPaths),
              ),
            );
          }
          return;
        }

        // Single PDF -> ignore if a PDF is already open
        final provider = context.read<PdfProvider>();
        if (provider.hasDocument) return;

        final messenger = ScaffoldMessenger.of(context);
        final success = await provider.loadPdf(pdfPaths.first);
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
