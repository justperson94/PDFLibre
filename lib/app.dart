import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/pdf_provider.dart';
import 'screens/empty_state_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

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
      home: Consumer<PdfProvider>(
        builder: (context, pdf, _) {
          if (pdf.hasDocument) {
            return const MainScreen();
          }
          return const EmptyStateScreen();
        },
      ),
    );
  }
}
