import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/screens/login_screen.dart';
import 'driver_dashboard_screen.dart';
import 'driver_map_screen.dart';
import 'driver_attendance_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Background Header Gradient
          Positioned(
            top: 0, left: 0, right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF044837), Color(0xFF086B53)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
            ),
          ),

      // Scrollable Content
      Positioned.fill(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 100),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'PERFIL',
                    style: GoogleFonts.publicSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    tooltip: 'Cerrar sesión',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Profile Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                      color: AppColors.primaryContainer,
                    ),
                    child: Center(
                      child: Text(
                        profileAsync.value?['name'] != null 
                          ? profileAsync.value!['name'].toString()[0].toUpperCase() 
                          : 'C',
                        style: GoogleFonts.publicSans(fontSize: 48, fontWeight: FontWeight.w900, color: const Color(0xFF044837)),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, size: 20, color: Color(0xFF044837)),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              profileAsync.when(
                data: (profile) {
                  final name = profile?['name'] as String? ?? 'Conductor';
                  final email = profile?['email'] as String? ?? 'No disponible';
                  final unitCode = profile?['unitCode'] as String? ?? 'SIN ASIGNAR';
                  
                  return Column(
                    children: [
                      Text(name.toUpperCase(), style: GoogleFonts.publicSans(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                      Text(email, style: GoogleFonts.publicSans(fontSize: 14, color: AppColors.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 40),

                      // Profile Info Cards
                      GestureDetector(
                        onTap: () => _showEditUnitCodeDialog(context, ref, unitCode),
                        child: _buildInfoCard(
                          icon: Icons.directions_bus,
                          title: 'UNIDAD ASIGNADA (Toca para cambiar)',
                          value: unitCode,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(icon: Icons.business, title: 'COOPERATIVA / COMPAÑÍA', value: 'TransEscolar S.A.'),
                      const SizedBox(height: 16),
                      _buildInfoCard(icon: Icons.phone, title: 'TELÉFONO DE CONTACTO', value: '+593 98 765 4321'),

                      const SizedBox(height: 40),

                      // Actions
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref.read(authRepositoryProvider).signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFDAD6),
                          foregroundColor: AppColors.error,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.logout),
                        label: Text('CERRAR SESIÓN', style: GoogleFonts.publicSans(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Colors.white)),
                error: (e, _) => Text('Error: $e', style: GoogleFonts.publicSans(color: Colors.white)),
              ),
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
            boxShadow: [BoxShadow(color: AppColors.secondary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4))]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, icon: Icons.route, label: 'Ruta', isActive: false, target: const DriverDashboardScreen()),
              _navItem(context, icon: Icons.map, label: 'Mapa', isActive: false, target: const DriverMapScreen()),
              _navItem(context, icon: Icons.assignment_turned_in, label: 'Asistencia', isActive: false, target: const DriverAttendanceScreen()),
              _navItem(context, icon: Icons.person, label: 'Perfil', isActive: true, target: null),
            ],
          ),
        ),
      )
    ],
  ),
);
}

void _showEditUnitCodeDialog(BuildContext context, WidgetRef ref, String currentCode) {
final controller = TextEditingController(text: currentCode);
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Editar Código de Unidad', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
    content: TextField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Nuevo Código', hintText: 'Ej: RUTA-402'),
      textCapitalization: TextCapitalization.characters,
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
      ElevatedButton(
        onPressed: () async {
          final newCode = controller.text.trim().toUpperCase();
          if (newCode.isNotEmpty) {
            final uid = ref.read(authStateProvider).value?.uid;
            if (uid != null) {
              final query = await FirebaseFirestore.instance
                  .collection('users')
                  .doc('drivers')
                  .collection('members')
                  .where('uid', isEqualTo: uid)
                  .limit(1)
                  .get();
                  
              if (query.docs.isNotEmpty) {
                await query.docs.first.reference.update({'unitCode': newCode});
                // Invalida el perfl para que se refresque
                ref.invalidate(userProfileProvider);
                if (context.mounted) Navigator.pop(context);
              }
            }
          }
        },
        child: const Text('GUARDAR'),
      ),
    ],
  ),
);
}

  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFA0F3D4).withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF044837)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.publicSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.publicSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required Widget? target}) {
    return GestureDetector(
      onTap: () {
        if (!isActive && target != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
        }
      },
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
