import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/app_flavor.dart';

/// Cinta visual en builds debug (QA) para distinguir padre / conductor en el dispositivo.
class AppFlavorBanner extends StatelessWidget {
  const AppFlavorBanner({
    super.key,
    required this.flavor,
    required this.child,
  });

  final AppFlavor flavor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;

    return Banner(
      message: flavor.label,
      location: BannerLocation.topStart,
      color: flavor.accentColor,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
      child: child,
    );
  }
}
