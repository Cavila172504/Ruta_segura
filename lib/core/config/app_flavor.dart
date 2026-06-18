import 'package:flutter/material.dart';

enum AppFlavor { parent, driver, admin }

extension AppFlavorStyle on AppFlavor {
  String get label => switch (this) {
        AppFlavor.parent => 'PADRE',
        AppFlavor.driver => 'CONDUCTOR',
        AppFlavor.admin => 'ADMIN',
      };

  String get appTitle => switch (this) {
        AppFlavor.parent => 'RutaSegura Padre',
        AppFlavor.driver => 'RutaSegura Conductor',
        AppFlavor.admin => 'RutaSegura Admin',
      };

  String get loginSubtitle => switch (this) {
        AppFlavor.parent => 'App para familias',
        AppFlavor.driver => 'App para conductores',
        AppFlavor.admin => 'App administración',
      };

  Color get accentColor => switch (this) {
        AppFlavor.parent => const Color(0xFF004782),
        AppFlavor.driver => const Color(0xFF0D4D3A),
        AppFlavor.admin => const Color(0xFF533AB7),
      };

  Color get splashColor => switch (this) {
        AppFlavor.parent => const Color(0xFFE3F2FD),
        AppFlavor.driver => const Color(0xFFFFF9C4),
        AppFlavor.admin => const Color(0xFFEDE7F6),
      };

  IconData get icon => switch (this) {
        AppFlavor.parent => Icons.family_restroom_rounded,
        AppFlavor.driver => Icons.directions_bus_rounded,
        AppFlavor.admin => Icons.admin_panel_settings_rounded,
      };
}
