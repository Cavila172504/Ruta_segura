import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_flavor.dart';

class AppFlavorBadge extends StatelessWidget {
  const AppFlavorBadge({super.key, required this.flavor});

  final AppFlavor flavor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: flavor.accentColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: flavor.accentColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(flavor.icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'APP ${flavor.label}',
            style: GoogleFonts.publicSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
