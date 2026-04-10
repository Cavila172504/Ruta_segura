import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'driver_dashboard_screen.dart';
import 'driver_map_screen.dart';

class DriverAttendanceScreen extends StatefulWidget {
  const DriverAttendanceScreen({super.key});

  @override
  State<DriverAttendanceScreen> createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends State<DriverAttendanceScreen> {
  // Estado local para simular la asistencia (true = presente, false = ausente)
  final List<bool> _attendance = [true, true, false, true, true];

  int get presents => _attendance.where((a) => a).length;
  int get total => _attendance.length;
  double get percentage => presents / total;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF044837), // teal-900
        elevation: 0,
        titleSpacing: 24,
        title: Row(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.primaryContainer),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
        automaticallyImplyLeading: false, // Quitar flecha por defecto si no es sub-página
      ),
      body: Stack(
        children: [
          // Scrollable Content
          Positioned.fill(
            bottom: 80, // Space for Bottom Nav
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Hero Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(bottom: BorderSide(color: AppColors.primaryContainer, width: 4)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ESTADO ACTUAL',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$presents de $total',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.onSurface,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'estudiantes presentes',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                )
                              ],
                            ),
                            Text(
                              '${(percentage * 100).toInt()}%',
                              style: GoogleFonts.publicSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Progress Bar
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA0F3D4), // secondary-container
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: percentage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryContainer.withOpacity(0.5),
                                    blurRadius: 12,
                                  )
                                ]
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Header List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LISTA DE ESTUDIANTES',
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA0F3D4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Ruta AM-402',
                          style: GoogleFonts.publicSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF167159),
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Student List Items
                  _buildStudentItem(
                    index: 0,
                    name: 'Mateo Rodriguez',
                    desc: '3ER GRADO • SILLA 04',
                    imageUrl: 'https://images.unsplash.com/photo-1549666978-75aa3afc002f?q=80&w=150&auto=format&fit=crop',
                  ),
                  const SizedBox(height: 12),
                  _buildStudentItem(
                    index: 1,
                    name: 'Elena Gómez',
                    desc: '2DO GRADO • SILLA 12',
                    imageUrl: 'https://images.unsplash.com/photo-1510006935-71bbd3c348dc?q=80&w=150&auto=format&fit=crop',
                  ),
                  const SizedBox(height: 12),
                  _buildStudentItem(
                    index: 2,
                    name: 'Julián Soto',
                    desc: 'AUSENTE • REPORTADO',
                    imageUrl: 'https://images.unsplash.com/photo-1519340243431-404859a68fae?q=80&w=150&auto=format&fit=crop',
                    isAbsentAlert: true,
                  ),
                  const SizedBox(height: 12),
                  _buildStudentItem(
                    index: 3,
                    name: 'Sofía Méndez',
                    desc: '4TO GRADO • SILLA 01',
                    imageUrl: 'https://images.unsplash.com/photo-1511284898144-42b45155f464?q=80&w=150&auto=format&fit=crop',
                  ),
                  const SizedBox(height: 12),
                  _buildStudentItem(
                    index: 4,
                    name: 'Lucas Paez',
                    desc: '1ER GRADO • SILLA 08',
                    imageUrl: 'https://images.unsplash.com/photo-1519894452134-2eec30534c06?q=80&w=150&auto=format&fit=crop',
                  ),

                  const SizedBox(height: 48),

                  // Sticky Hero Action (Guardar Asistencia)
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: const Color(0xFF221B00),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                      side: const BorderSide(color: AppColors.primary, width: 2), // bottom border feel
                    ),
                    icon: const Icon(Icons.how_to_reg, size: 24),
                    label: Text(
                      'GUARDAR ASISTENCIA',
                      style: GoogleFonts.publicSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ÚLTIMA SINCRONIZACIÓN: HOY 07:14 AM',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.publicSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 64), 
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
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverDashboardScreen()))
                  ),
                  _navItem(
                    icon: Icons.map, 
                    label: 'Mapa', 
                    isActive: false, 
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DriverMapScreen()))
                  ),
                  _navItem(icon: Icons.assignment_turned_in, label: 'Asistencia', isActive: true, onTap: () {}),
                  _navItem(icon: Icons.person, label: 'Perfil', isActive: false, onTap: () {}),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStudentItem({
    required int index,
    required String name,
    required String desc,
    required String imageUrl,
    bool isAbsentAlert = false,
  }) {
    final isPresent = _attendance[index];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPresent 
            ? AppColors.surfaceContainerLowest 
            : AppColors.surfaceContainerLow.withOpacity(isAbsentAlert ? 0.8 : 1),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: isPresent ? AppColors.primary : Colors.transparent, width: 4)),
        boxShadow: isPresent 
            ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                colorFilter: isPresent ? null : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              )
            ),
          ),
          const SizedBox(width: 16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.publicSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAbsentAlert ? AppColors.onSurfaceVariant : AppColors.onSurface,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.publicSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                    fontStyle: isAbsentAlert ? FontStyle.italic : null,
                  ),
                )
              ],
            ),
          ),
          // Custom Toggle Switch
          GestureDetector(
            onTap: () {
              setState(() {
                _attendance[index] = !_attendance[index];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isPresent ? AppColors.primaryContainer : const Color(0xFFE8E8E8), // surface-container-high
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isPresent ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPresent ? AppColors.primary : const Color(0xFFD0C6AB), // outline-variant
                    ),
                  ),
                ),
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
