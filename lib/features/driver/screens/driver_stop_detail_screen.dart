import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_incident_report_screen.dart';

class DriverStopDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> student;
  final String unitCode;

  const DriverStopDetailScreen({
    super.key,
    required this.student,
    required this.unitCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentName = student['studentName'] as String? ?? 'Estudiante';
    final studentId = student['id'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background Layer (Simplified for performance)
          Positioned.fill(
            child: Container(color: Colors.grey.shade200),
          ),
          
          // Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: const Color(0xFF044837),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12, left: 16, right: 16),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  Text('DETALLE DE PARADA', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                ],
              ),
            ),
          ),

          // Main Card
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 40, offset: const Offset(0, -10))]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  
                  Row(
                    children: [
                      CircleAvatar(radius: 40, backgroundColor: AppColors.primaryContainer, child: Text(studentName[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(studentName, style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.w900)),
                            Text('Código Unidad: $unitCode', style: GoogleFonts.publicSans(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // MARCAR COMO RECOGIDO
                            await FirebaseFirestore.instance
                                .collection('companies')
                                .doc(unitCode)
                                .collection('students')
                                .doc(studentId)
                                .update({'status': 'picked_up'});
                            
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: const Color(0xFF221B00),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('PRESENTE', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // MARCAR COMO AUSENTE
                            await FirebaseFirestore.instance
                                .collection('companies')
                                .doc(unitCode)
                                .collection('students')
                                .doc(studentId)
                                .update({'status': 'absent'});
                            
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('AUSENTE', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverIncidentReportScreen())),
                    child: const Text('REPORTAR INCIDENTE', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
