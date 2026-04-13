import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/route_provider.dart';
import 'driver_map_screen.dart';
import 'driver_attendance_screen.dart';
import 'driver_qr_screen.dart';

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '¡BUEN DÍA';
    if (hour < 18) return '¡BUENAS TARDES';
    return '¡BUENAS NOCHES';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1000&auto=format&fit=crop',
              fit: BoxFit.cover,
              color: Colors.white.withValues(alpha: 0.6),
              colorBlendMode: BlendMode.dstATop,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey.shade300),
            ),
          ),
          // Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.surface,
                    AppColors.surface.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: const Color(0xFF044837),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 24,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      profileAsync.when(
                        data: (profile) {
                          final initial = (profile?['name'] as String? ?? 'C')[0].toUpperCase();
                          return Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryContainer, width: 2),
                              color: AppColors.primaryContainer,
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: GoogleFonts.publicSans(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF044837),
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          );
                        },
                        loading: () => Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        error: (_, __) => const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'RUTASEGURA',
                        style: GoogleFonts.publicSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  profileAsync.maybeWhen(
                    data: (profile) => IconButton(
                      icon: const Icon(Icons.qr_code_2,
                          color: AppColors.primaryContainer, size: 28),
                      onPressed: () {
                        final unitCode = profile?['unitCode'] as String? ?? 'UNIDAD-00';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverQrScreen(unitCode: unitCode),
                          ),
                        );
                      },
                      tooltip: 'Mostrar QR',
                    ),
                    orElse: () => const SizedBox(width: 48),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60,
            bottom: 84,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: profileAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary),
                ),
                error: (e, _) => Center(
                  child: Text('Error al cargar perfil', style: GoogleFonts.publicSans()),
                ),
                data: (profile) {
                  final name = profile?['name'] as String? ?? 'Conductor';
                  final firstName = name.split(' ').first;
                  final unitCode = profile?['unitCode'] as String? ?? 'UNIDAD-00';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Greeting
                      Text(
                        '${_getGreeting()}, ${firstName.toUpperCase()}!',
                        style: GoogleFonts.publicSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inicio de Recorrido',
                        style: GoogleFonts.publicSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Route Card with dynamic data
                      Consumer(
                        builder: (context, ref, _) {
                          final routeAsync = ref.watch(activeRouteProvider(unitCode));
                          return routeAsync.when(
                            loading: () => _routeCardSkeleton(),
                            error: (_, __) => _routeCardStatic(),
                            data: (route) => _routeCard(route),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // First Stop Card
                      Consumer(
                        builder: (context, ref, _) {
                          final routeAsync = ref.watch(activeRouteProvider(unitCode));
                          final firstStop = routeAsync.value?['firstStop'] as String? 
                              ?? 'Sin paradas configuradas';
                          final firstTime = routeAsync.value?['firstStopTime'] as String? ?? '--:--';

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.outline.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.home,
                                      color: Color(0xFF705E00)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PRIMERA PARADA',
                                        style: GoogleFonts.publicSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.onSurfaceVariant,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$firstStop - $firstTime',
                                        style: GoogleFonts.publicSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 120),
                    ],
                  );
                },
              ),
            ),
          ),

          // Start Route Button
          Positioned(
            bottom: 92, left: 24, right: 24,
            child: profileAsync.maybeWhen(
              data: (profile) {
                final unitCode = profile?['unitCode'] as String? ?? 'UNIDAD-00';
                return InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverMapScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonMetallic,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow,
                            color: Color(0xFF221B00), size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'INICIAR RECORRIDO',
                          style: GoogleFonts.publicSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF221B00),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),

          // Bottom Nav Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(icon: Icons.route, label: 'Ruta', isActive: true, onTap: () {}),
                  _navItem(
                    icon: Icons.map,
                    label: 'Mapa',
                    isActive: false,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const DriverMapScreen()),
                    ),
                  ),
                  _navItem(
                    icon: Icons.assignment_turned_in,
                    label: 'Asistencia',
                    isActive: false,
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DriverAttendanceScreen()),
                    ),
                  ),
                  _navItem(icon: Icons.person, label: 'Perfil', isActive: false, onTap: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────

  Widget _routeCard(Map<String, dynamic>? route) {
    final routeName = route?['name'] as String? ?? 'Sin ruta asignada';
    final students = route?['studentCount'] as int? ?? 0;
    final duration = route?['durationMin'] as int? ?? 0;
    final stops = route?['stopCount'] as int? ?? 0;

    return _routeCardContent(routeName, students, duration, stops);
  }

  Widget _routeCardStatic() {
    return _routeCardContent('Ruta sin conexión', 0, 0, 0);
  }

  Widget _routeCardSkeleton() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );
  }

  Widget _routeCardContent(
      String routeName, int students, int duration, int stops) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 12),
            spreadRadius: -12,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'RUTA ACTIVA',
                              style: GoogleFonts.publicSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            routeName,
                            style: GoogleFonts.publicSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA0F3D4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.route, color: Color(0xFF167159)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _statChip(
                        icon: Icons.group,
                        label: 'ESTUDIANTES',
                        value: students.toString(),
                        unit: 'pax',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statChip(
                        icon: Icons.schedule,
                        label: 'DURACIÓN',
                        value: duration.toString(),
                        unit: 'min',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Dark bar
          Container(
            color: const Color(0xFF044837),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppColors.primaryContainer, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '$stops Paradas programadas',
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.publicSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: '$value ',
              style: GoogleFonts.publicSans(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.onSurface,
              ),
              children: [
                TextSpan(
                  text: unit,
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF044837) : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.publicSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isActive ? const Color(0xFF044837) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
