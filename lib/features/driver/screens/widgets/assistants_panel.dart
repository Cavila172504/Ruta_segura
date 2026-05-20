import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class AssistantsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final Set<String> presentIds;
  final Function(String) onTogglePresent;

  const AssistantsPanel({
    super.key,
    required this.students,
    required this.presentIds,
    required this.onTogglePresent,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar por no recogidos
    final pendingStudents = students.where((s) => !presentIds.contains(s['id']) && s['status'] != 'absent').toList();

    return Container(
      width: 280,
      height: MediaQuery.of(context).size.height * 0.7,
      margin: const EdgeInsets.only(right: 16, top: 120),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PENDIENTES', style: GoogleFonts.inter(color: const Color(0xFF0D4D3A), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 12),
                Expanded(
                  child: pendingStudents.isEmpty
                    ? Center(child: Text('Todos recogidos 🎉', style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.bold)))
                    : ListView.builder(
                        itemCount: pendingStudents.length,
                        itemBuilder: (context, index) {
                          final student = pendingStudents[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFFFD600).withOpacity(0.3),
                                  child: const Icon(Icons.person, size: 18, color: Color(0xFF0D4D3A)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(student['studentName'] ?? 'Estudiante', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF0D4D3A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                GestureDetector(
                                  onTap: () => onTogglePresent(student['id']),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                    child: const Icon(Icons.check_rounded, color: Colors.grey, size: 20),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
