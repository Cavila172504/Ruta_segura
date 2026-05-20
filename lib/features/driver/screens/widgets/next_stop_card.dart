import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class NextStopCard extends StatelessWidget {
  final Map<String, dynamic>? nextStudent;
  final double distance;
  final String eta;
  final VoidCallback onConfirm;

  const NextStopCard({
    super.key,
    required this.nextStudent,
    required this.distance,
    required this.eta,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (nextStudent == null) return const SizedBox.shrink();

    final isDelayed = distance > 2000 && eta.contains('min'); // Lógica simple simulada
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0D4D3A).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF0D4D3A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRÓXIMA PARADA', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        Text(
                          nextStudent!['studentName'] ?? 'Desconocido',
                          style: GoogleFonts.inter(color: const Color(0xFF0D4D3A), fontSize: 18, fontWeight: FontWeight.w900),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoItem(Icons.route_rounded, '${distance.toInt()}m'),
                  _infoItem(Icons.access_time_rounded, eta, isDelayed: isDelayed),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D4D3A),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: const Color(0xFF0D4D3A).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('CONFIRMAR LLEGADA', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text, {bool isDelayed = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDelayed ? Colors.redAccent : Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(color: isDelayed ? Colors.redAccent : Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
