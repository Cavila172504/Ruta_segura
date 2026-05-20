import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class MapHUD extends StatelessWidget {
  final double speedKmh;
  final double progressPercent;
  final String eta;
  final String? nextStopName;

  const MapHUD({
    super.key,
    required this.speedKmh,
    required this.progressPercent,
    required this.eta,
    this.nextStopName,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D4D3A).withOpacity(0.85), // Verde corporativo semi-transparente
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila superior: Velocidad, GPS, Batería
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VELOCIDAD', style: GoogleFonts.inter(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(speedKmh.toStringAsFixed(0), style: GoogleFonts.inter(color: const Color(0xFFFFD600), fontSize: 28, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 4),
                          Text('km/h', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: [
                      _statusIcon(Icons.gps_fixed, Colors.greenAccent),
                      const SizedBox(width: 8),
                      _statusIcon(Icons.battery_charging_full, Colors.greenAccent),
                    ],
                  )
                ],
              ),
              if (nextStopName != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_pin_circle_rounded, color: Color(0xFFFFD600), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'PRÓXIMA PARADA: ${nextStopName!.toUpperCase()}',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              
              // Barra de progreso y ETA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PROGRESO', style: GoogleFonts.inter(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                  Text('ETA: $eta', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(3)),
                  ),
                  FractionallySizedBox(
                    widthFactor: progressPercent.clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD600),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [BoxShadow(color: const Color(0xFFFFD600).withOpacity(0.5), blurRadius: 6)]
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.3))),
      child: Icon(icon, color: color, size: 12),
    );
  }
}
