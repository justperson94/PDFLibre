import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'l10n/strings.dart';
import 'providers/pdf_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/empty_state_screen.dart';
import 'screens/main_screen.dart';
import 'screens/merge_screen.dart';
import 'services/window_chrome_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'widgets/common/drop_overlay.dart';

class PDFLibreApp extends StatelessWidget {
  const PDFLibreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    final ThemeMode themeMode;
    switch (settings.themeMode) {
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        break;
    }

    final lightBase = ThemeData.light(useMaterial3: false);
    final darkBase = ThemeData.dark(useMaterial3: false);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: lightBase.copyWith(
        scaffoldBackgroundColor: AppColors.light.surfacePrimary,
        textTheme: GoogleFonts.interTextTheme(lightBase.textTheme),
        colorScheme: lightBase.colorScheme.copyWith(
          primary: AppColors.light.accentPrimary,
          surface: AppColors.light.surfacePrimary,
          onSurface: AppColors.light.foregroundPrimary,
        ),
        extensions: const [AppColors.light],
      ),
      darkTheme: darkBase.copyWith(
        scaffoldBackgroundColor: AppColors.dark.surfacePrimary,
        textTheme: GoogleFonts.interTextTheme(darkBase.textTheme),
        colorScheme: darkBase.colorScheme.copyWith(
          primary: AppColors.dark.accentPrimary,
          surface: AppColors.dark.surfacePrimary,
          onSurface: AppColors.dark.foregroundPrimary,
        ),
        extensions: const [AppColors.dark],
      ),
      home: const _WindowChromeSync(child: _DropWrapper()),
    );
  }
}

/// MaterialApp의 effective brightness를 네이티브 macOS 창에 전파한다.
/// 시스템 모드에서 OS 밝기가 바뀌면 MediaQuery.platformBrightness → Theme가
/// 재빌드되므로 이 위젯도 자동으로 갱신 신호를 보낸다.
class _WindowChromeSync extends StatefulWidget {
  const _WindowChromeSync({required this.child});

  final Widget child;

  @override
  State<_WindowChromeSync> createState() => _WindowChromeSyncState();
}

class _WindowChromeSyncState extends State<_WindowChromeSync> {
  Brightness? _lastApplied;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness != _lastApplied) {
      _lastApplied = brightness;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WindowChromeService.applyBrightness(brightness);
      });
    }
    return widget.child;
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
              SnackBar(content: Text(S.of(context).onlyPdfAllowed)),
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
            SnackBar(content: Text(S.of(context).cannotOpenFile)),
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
          if (_isDragging) DropOverlay(),
        ],
      ),
    );
  }
}
