import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'driver_dashboard_screen.dart';
import 'driver_map_screen.dart';
import 'driver_attendance_screen.dart';
import 'driver_profile_screen.dart';
import '../../../core/providers/navigation_provider.dart';

class DriverMainShell extends ConsumerStatefulWidget {
  const DriverMainShell({super.key});

  @override
  ConsumerState<DriverMainShell> createState() => _DriverMainShellState();
}

class _DriverMainShellState extends ConsumerState<DriverMainShell> {

  final List<Widget> _screens = [
    const DriverDashboardScreen(),
    const DriverMapScreen(),
    const DriverAttendanceScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationService();
  }

  Future<void> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Ubicación Desactivada'),
            content: const Text('Para que RutaSegura funcione correctamente, debes activar el GPS de tu dispositivo.'),
            actions: [
              TextButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('ACTIVAR GPS'),
              ),
            ],
          ),
        );
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(driverNavigationProvider);
    // Prevent out of bounds if selectedIndex was previously 3
    final safeIndex = selectedIndex > 2 ? 0 : selectedIndex;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              currentIndex: safeIndex,
              onTap: (index) {
                ref.read(driverNavigationProvider.notifier).setIndex(index);
              },
              selectedItemColor: const Color(0xFF0D4D3A),
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              unselectedLabelStyle: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'DASHBOARD'),
                BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'MAPA'),
                BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'ALUMNOS'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
