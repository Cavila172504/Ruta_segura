import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'driver_dashboard_screen.dart';
import 'driver_map_screen.dart';
import 'driver_attendance_screen.dart';

class DriverIncidentReportScreen extends StatefulWidget {
  const DriverIncidentReportScreen({super.key});

  @override
  State<DriverIncidentReportScreen> createState() => _DriverIncidentReportScreenState();
}

class _DriverIncidentReportScreenState extends State<DriverIncidentReportScreen> {
  String? _selectedIncidentType;
  bool _shareLocation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF044837), // teal-900
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'RUTASEGURA',
          style: GoogleFonts.publicSans(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryContainer, width: 2),
                image: const DecorationImage(
                  image: NetworkImage('https://i.pravatar.cc/150?u=carlos'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable Content
          Positioned.fill(
            bottom: 80, // Space for Bottom Nav
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Critical Alert Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                      ]
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.white, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Esta alerta se enviará a todos los padres de esta ruta.',
                            style: GoogleFonts.publicSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          'REPORTAR NOVEDAD',
                          style: GoogleFonts.publicSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete la información para notificar incidencias en tiempo real.',
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Form - Tipo de Novedad
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'TIPO DE NOVEDAD',
                                style: GoogleFonts.publicSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedIncidentType,
                                    isExpanded: true,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    hint: Text(
                                      'Seleccione una opción',
                                      style: GoogleFonts.publicSans(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSurfaceVariant.withOpacity(0.5),
                                      ),
                                    ),
                                    icon: const Icon(Icons.expand_more, color: AppColors.secondary),
                                    items: [
                                      'Retraso por Tráfico',
                                      'Falla Mecánica',
                                      'Condiciones Climáticas',
                                      'Cambio de Ruta',
                                      'Emergencia Médica'
                                    ].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: GoogleFonts.publicSans(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() => _selectedIncidentType = newValue);
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Form - Descripción
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'DESCRIPCIÓN',
                                style: GoogleFonts.publicSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                maxLines: 4,
                                style: GoogleFonts.publicSans(fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: 'Detalle lo sucedido aquí...',
                                  hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.5)),
                                  filled: true,
                                  fillColor: AppColors.surfaceContainerLowest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Toggle Location Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA0F3D4), // secondary-container
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.location_on, color: AppColors.secondary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Compartir ubicación',
                                            style: GoogleFonts.publicSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF167159), // on-secondary-container
                                            ),
                                          ),
                                          Text(
                                            'Se incluirán coordenadas GPS exactas',
                                            style: GoogleFonts.publicSans(
                                              fontSize: 12,
                                              color: const Color(0xFF00513e), // on-secondary-fixed-variant
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _shareLocation,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.secondary,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: const Color(0xFF167159).withOpacity(0.2), // on-secondary-container
                                onChanged: (val) {
                                  setState(() => _shareLocation = val);
                                },
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Visual Asset Context
                        Container(
                          height: 192, // 48 * 4
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1557223562-6c77ef1607ef?q=80&w=600&auto=format&fit=crop'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  const Color(0xFF044837).withOpacity(0.8), // teal-900
                                  Colors.transparent,
                                ],
                              )
                            ),
                            alignment: Alignment.bottomLeft,
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'VISTA DE CONTEXTO: SEGURIDAD PRIMERO',
                              style: GoogleFonts.publicSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: AppColors.error.withOpacity(0.4),
                          ),
                          icon: const Icon(Icons.campaign, size: 28),
                          label: Text(
                            'ENVIAR ALERTA A TODOS LOS PADRES',
                            style: GoogleFonts.publicSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ESTA ACCIÓN NO SE PUEDE DESHACER UNA VEZ ENVIADA',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.publicSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppColors.outline,
                          ),
                        ),

                        const SizedBox(height: 64),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // Bottom Nav Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(color: AppColors.secondary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4))
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    icon: Icons.route, 
                    label: 'Ruta', 
                    isActive: false, 
                    onTap: () {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DriverDashboardScreen()), (route) => false);
                    }
                  ),
                  _navItem(
                    icon: Icons.map, 
                    label: 'Mapa', 
                    isActive: false, 
                    onTap: () {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DriverMapScreen()), (route) => false);
                    }
                  ),
                  _navItem(
                    icon: Icons.assignment_turned_in, 
                    label: 'Asistencia', 
                    isActive: true, 
                    onTap: () {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DriverAttendanceScreen()), (route) => false);
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
