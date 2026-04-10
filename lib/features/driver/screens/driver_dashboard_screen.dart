import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'driver_map_screen.dart';
import 'driver_attendance_screen.dart';

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background "Map" Layer
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1000&auto=format&fit=crop', // Replaced with a reliable map placeholder
              fit: BoxFit.cover,
              color: Colors.white.withOpacity(0.6),
              colorBlendMode: BlendMode.dstATop,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade300),
            ),
          ),
          // Gradient Fade
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.surface,
                    AppColors.surface.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0]
                ),
              ),
            ),
          ),

          // Main Header (TopAppBar)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: const Color(0xFF044837), // Dark teal (teal-900)
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
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryContainer, width: 2),
                          image: const DecorationImage(
                            image: NetworkImage('https://i.pravatar.cc/150?u=carlos'),
                            fit: BoxFit.cover,
                          ),
                        ),
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
                  IconButton(
                    icon: const Icon(Icons.notifications, color: AppColors.primaryContainer),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 60,
            bottom: 80, // Space for Bottom Nav
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Greeting
                  Text(
                    '¡BUEN DÍA, CARLOS!',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Inicio de Recorrido',
                    style: GoogleFonts.publicSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Route Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outline.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                          spreadRadius: -12,
                        ),
                      ]
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                          'Ruta 42 - Colegio Central',
                                          style: GoogleFonts.publicSans(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.onSurface,
                                            height: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA0F3D4), // secondary-container
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.route, color: Color(0xFF167159)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  // Stats 1
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.group, color: AppColors.secondary, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                'ESTUDIANTES',
                                                style: GoogleFonts.publicSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          RichText(
                                            text: TextSpan(
                                              text: '12 ',
                                              style: GoogleFonts.publicSans(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.onSurface,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'pax',
                                                  style: GoogleFonts.publicSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.onSurface.withOpacity(0.6),
                                                  )
                                                )
                                              ]
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Stats 2
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.schedule, color: AppColors.secondary, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                'DURACIÓN',
                                                style: GoogleFonts.publicSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          RichText(
                                            text: TextSpan(
                                              text: '45 ',
                                              style: GoogleFonts.publicSans(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.onSurface,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'min',
                                                  style: GoogleFonts.publicSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.onSurface.withOpacity(0.6),
                                                  )
                                                )
                                              ]
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Secondary Info Bar
                        Container(
                          color: const Color(0xFF044837), // teal-900
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: AppColors.primaryContainer, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    '15 Paradas programadas',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  )
                                ],
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white54),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Next Stop Preview
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outline.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.home, color: Color(0xFF705E00)),
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
                                'Residencial Los Olivos - 06:45 AM',
                                style: GoogleFonts.publicSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.onSurface,
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 120), // Bottom padding
                ],
              ),
            ),
          ),

          // Floating Start Button
          Positioned(
            bottom: 96, left: 24, right: 24,
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverMapScreen()));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buttonMetallic,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ]
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, color: Color(0xFF221B00), size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'INICIAR RECORRIDO',
                      style: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF221B00),
                        letterSpacing: 1,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Bottom Nav Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  )
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(
                    icon: Icons.route, 
                    label: 'Ruta', 
                    isActive: true, 
                    onTap: () {}
                  ),
                  _navItem(
                    icon: Icons.map, 
                    label: 'Mapa', 
                    isActive: false, 
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverMapScreen()));
                    }
                  ),
                  _navItem(
                    icon: Icons.assignment_turned_in, 
                    label: 'Asistencia', 
                    isActive: false, 
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverAttendanceScreen()));
                    }
                  ),
                  _navItem(icon: Icons.person, label: 'Perfil', isActive: false, onTap: () {}),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
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
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: isActive ? const Color(0xFF044837) : Colors.grey.shade500,
          ),
        )
      ],
    ),
  );
}
}
