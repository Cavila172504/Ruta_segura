import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'legal_content.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String body;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.body,
  });

  factory LegalDocumentScreen.privacy() {
    return const LegalDocumentScreen(
      title: LegalContent.privacyTitle,
      body: LegalContent.privacyBody,
    );
  }

  factory LegalDocumentScreen.terms() {
    return const LegalDocumentScreen(
      title: LegalContent.termsTitle,
      body: LegalContent.termsBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          body.trim(),
          style: GoogleFonts.publicSans(
            fontSize: 14,
            height: 1.6,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}