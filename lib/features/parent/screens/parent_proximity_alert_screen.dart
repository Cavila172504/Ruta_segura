import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentProximityAlertScreen extends StatelessWidget {
  const ParentProximityAlertScreen({super.key});

  final Color _primary = const Color(0xFF004782);
  final Color _primaryContainer = const Color(0xFF185fa5);
  final Color _surfaceLowest = const Color(0xFFffffff);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _surfaceLowest,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: _primary.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tracking Visualizer
            Container(
              height: 180,
              color: const Color(0xFFedeeef), // surface-container
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Path line
                  Positioned(
                    left: 64, right: 64,
                    child: Container(
                      height: 2,
                      width: double.infinity,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  // Progress line
                  Positioned(
                    left: 64,
                    child: Container(
                      height: 4,
                      width: 100, // Partial progress
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_primary.withOpacity(0.2), _primary]),
                      ),
                    ),
                  ),
                  // Emulated bus and home icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)]),
                            child: Icon(Icons.home, color: _primary, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text('MI CASA', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600))
                        ],
                      ),
                      const SizedBox(width: 40),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [_primary, _primaryContainer]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 24)],
                              border: Border.all(color: const Color(0xFFd4e3ff), width: 4),
                            ),
                            child: const Icon(Icons.directions_bus, color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 8),
                          Text('EN CAMINO', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: _primary))
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            
            // Content Area
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFffdcc4), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, size: 16, color: Color(0xFF703800)),
                        const SizedBox(width: 4),
                        Text('Aviso de Proximidad', style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF703800))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡El bus llega en 2 minutos!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.publicSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _primary,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mateo',
                    style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Calle 127 #45-20',
                    style: GoogleFonts.publicSans(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  // Actions
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close map modal implicitly keeping map active
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: _primary.withOpacity(0.4),
                    ),
                    icon: const Icon(Icons.map, size: 20),
                    label: Text(
                      'VER EN MAPA',
                      style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFd9e4ee), // secondary container
                      foregroundColor: const Color(0xFF3e4850),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Cerrar', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            // Safety Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              color: const Color(0xFFd4e3ff),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: _primary, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('SEGUIMIENTO EN VIVO ACTIVO', style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF004883))),
                    ],
                  ),
                  const Icon(Icons.verified_user, color: Color(0xFF004883), size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
