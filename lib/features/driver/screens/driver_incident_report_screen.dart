import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/parent_member_utils.dart';
import '../../../core/services/incident_report_service.dart';
import 'driver_dashboard_screen.dart';
import 'driver_map_screen.dart';
import 'driver_attendance_screen.dart';

class DriverIncidentReportScreen extends ConsumerStatefulWidget {
  const DriverIncidentReportScreen({super.key});

  @override
  ConsumerState<DriverIncidentReportScreen> createState() => _DriverIncidentReportScreenState();
}

class _DriverIncidentReportScreenState extends ConsumerState<DriverIncidentReportScreen> {
  String? _selectedIncidentType;
  bool _shareLocation = true;
  bool _isSubmitting = false;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedIncidentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione el tipo de novedad.')),
      );
      return;
    }

    final profile = ref.read(userProfileProvider).value;
    final unitCode = normalizeUnitCode(profile?['unitCode'] as String?);
    final driverId = profile?['uid'] as String?;
    if (unitCode.isEmpty || driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil de conductor incompleto.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      double? lat;
      double? lng;
      if (_shareLocation) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      }

      final description = _descriptionController.text.trim().isEmpty
          ? _selectedIncidentType!
          : _descriptionController.text.trim();

      String category = 'novedad';
      if (_selectedIncidentType!.toLowerCase().contains('retraso')) {
        category = 'retraso';
      }

      await IncidentReportService.create(
        unitCode: unitCode,
        driverId: driverId,
        driverName: profile?['name'] ?? 'Conductor',
        type: _selectedIncidentType!,
        category: category,
        description: description,
        lat: lat,
        lng: lng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Novedad registrada en la bitácora del colegio.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF044837),
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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 80,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: AppColors.error,
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.white, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'La novedad quedará registrada en la bitácora del panel administrativo.',
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
                          'Complete la información para registrar incidencias en tiempo real.',
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
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
                                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    icon: const Icon(Icons.expand_more, color: AppColors.secondary),
                                    items: const [
                                      'Retraso por Tráfico',
                                      'Falla Mecánica',
                                      'Condiciones Climáticas',
                                      'Cambio de Ruta',
                                      'Emergencia Médica',
                                    ].map((value) {
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
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                controller: _descriptionController,
                                maxLines: 4,
                                style: GoogleFonts.publicSans(fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: 'Detalle lo sucedido aquí...',
                                  hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
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
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA0F3D4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
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
                                              color: Color(0xFF167159),
                                            ),
                                          ),
                                          Text(
                                            'Se incluirán coordenadas GPS exactas',
                                            style: GoogleFonts.publicSans(
                                              fontSize: 12,
                                              color: Color(0xFF00513e),
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
                                onChanged: (val) => setState(() => _shareLocation = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.campaign, size: 28),
                          label: Text(
                            _isSubmitting ? 'ENVIANDO...' : 'REGISTRAR NOVEDAD',
                            style: GoogleFonts.publicSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 64),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(color: AppColors.secondary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    icon: Icons.route,
                    label: 'Ruta',
                    isActive: false,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  _navItem(
                    icon: Icons.map,
                    label: 'Mapa',
                    isActive: false,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverMapScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  _navItem(
                    icon: Icons.assignment_turned_in,
                    label: 'Asistencia',
                    isActive: false,
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverAttendanceScreen()),
                        (route) => false,
                      );
                    },
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
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isActive ? const Color(0xFF044837) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
