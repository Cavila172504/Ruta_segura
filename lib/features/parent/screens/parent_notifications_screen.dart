import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/notification_list_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/screens/login_screen.dart';
import 'parent_dashboard_screen.dart';
import 'parent_map_screen.dart';

class ParentNotificationsScreen extends ConsumerWidget {
  const ParentNotificationsScreen({super.key});

  final Color _primary = const Color(0xFF004782);
  final Color _surface = const Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Iniciar el monitoreo de cercanía y eventos del bus
    ref.watch(proximityMonitoringProvider);
    ref.watch(remoteNotificationsListenerProvider);

    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notificaciones',
                    style: GoogleFonts.publicSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF191c1d),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mantente al tanto del recorrido de tus hijos hoy.',
                    style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF424751)),
                  ),
                  const SizedBox(height: 32),

                  notificationsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text('No tienes notificaciones recientes.', style: GoogleFonts.publicSans(color: Colors.grey)),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildNotificationItem(n),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('AYER', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildNotificationItem(AppNotification(
                    id: 'old',
                    title: 'Llegada al colegio',
                    subtitle: 'El bus ha finalizado su recorrido de retorno exitosamente.',
                    timestamp: DateTime.now().subtract(const Duration(days: 1)),
                    type: NotificationType.arrival,
                  ), dimmed: true),

                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),

          // Top App Bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: Colors.white.withValues(alpha: 0.85),
              padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_bus, color: _primary, size: 24),
                      const SizedBox(width: 8),
                      Text('RutaSegura', style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w800, color: _primary, letterSpacing: -0.5))
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.logout, color: Colors.grey.shade500),
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Nav Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -8))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(context, icon: Icons.home, label: 'Inicio', isActive: false, target: const ParentDashboardScreen()),
                    _navItem(context, icon: Icons.map, label: 'Mapa', isActive: false, target: const ParentMapScreen()),
                    _navItem(context, icon: Icons.notifications, label: 'Notificaciones', isActive: true, target: const ParentNotificationsScreen()),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification, {bool dimmed = false}) {
    IconData icon;
    Color iconColor;
    Color iconBg;
    Color bgColor = Colors.white;
    Border? border;
    Color titleColor = const Color(0xFF191c1d);
    Color subtitleColor = const Color(0xFF424751);

    switch (notification.type) {
      case NotificationType.alert:
        icon = Icons.error_outline_rounded;
        iconColor = Colors.white;
        iconBg = const Color(0xFFba1a1a);
        bgColor = const Color(0xFFffdad6);
        titleColor = const Color(0xFF93000a);
        subtitleColor = const Color(0xFF93000a);
        break;
      case NotificationType.trip_started:
      case NotificationType.busStart:
        icon = Icons.directions_bus_filled_rounded;
        iconBg = const Color(0xFFd4e3ff);
        iconColor = _primary;
        break;
      case NotificationType.support:
        icon = Icons.headset_mic_rounded;
        iconBg = Colors.green.shade100;
        iconColor = Colors.green.shade800;
        break;
      case NotificationType.proximity:
        icon = Icons.near_me_rounded;
        iconBg = const Color(0xFFd9e4ee);
        iconColor = _primary;
        border = Border(left: BorderSide(color: _primary, width: 4));
        break;
      case NotificationType.boarded:
        icon = Icons.how_to_reg_rounded;
        iconColor = Colors.white;
        iconBg = _primary;
        break;
      case NotificationType.arrival:
        icon = Icons.school_rounded;
        iconColor = const Color(0xFF424751);
        iconBg = const Color(0xFFbdc8d1);
        if (dimmed) bgColor = const Color(0xFFedeeef);
        break;
    }

    final timeStr = DateFormat('hh:mm a').format(notification.timestamp);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: bgColor == Colors.white ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: Opacity(
        opacity: dimmed ? 0.6 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: titleColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notification.type == NotificationType.alert ? 'AHORA' : timeStr,
                        style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: subtitleColor.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.subtitle,
                    style: GoogleFonts.publicSans(fontSize: 14, color: subtitleColor),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required Widget target}) {
    return GestureDetector(
      onTap: () {
        if (!isActive) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: isActive ? const Color(0xFFdbeaFE) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? _primary : Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? _primary : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
