import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/route_provider.dart';
import 'parent_dashboard_screen.dart';
import 'parent_map_screen.dart';
import 'parent_notifications_screen.dart';
import 'parent_onboarding_screen.dart';

class ParentSetupGate extends ConsumerWidget {
  const ParentSetupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupAsync = ref.watch(parentSetupCompleteProvider);

    return setupAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const ParentOnboardingScreen(),
      data: (complete) {
        if (complete) {
          return const ParentShellScreen();
        }
        return const ParentOnboardingScreen();
      },
    );
  }
}

class ParentShellScreen extends ConsumerStatefulWidget {
  const ParentShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<ParentShellScreen> createState() => _ParentShellScreenState();
}

class _ParentShellScreenState extends ConsumerState<ParentShellScreen> {
  bool _hasAutoSwitchedToMap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(parentShellTabIndexProvider.notifier).selectTab(
          widget.initialIndex);
    });
  }

  void _onTabTap(int index) {
    if (index == ref.read(parentShellTabIndexProvider)) return;
    ref.read(parentShellTabIndexProvider.notifier).selectTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(parentShellTabIndexProvider);

    ref.listen<AsyncValue<String>>(busStatusProvider, (previous, next) {
      final prevStatus = previous?.value ?? 'idle';
      final newStatus = next.value ?? 'idle';
      if (newStatus == 'on_route' &&
          prevStatus != 'on_route' &&
          !_hasAutoSwitchedToMap &&
          mounted) {
        _hasAutoSwitchedToMap = true;
        ref.read(parentShellTabIndexProvider.notifier).selectTab(1);
      }
      if (newStatus != 'on_route') {
        _hasAutoSwitchedToMap = false;
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (currentIndex != 0) {
          ref.read(parentShellTabIndexProvider.notifier).selectTab(0);
          return;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Salir', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
            content: const Text('Deseas cerrar RutaSegura?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NO')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('SI')),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: const [
            ParentDashboardScreen(embeddedInShell: true),
            ParentMapScreen(embeddedInShell: true),
            ParentNotificationsScreen(embeddedInShell: true),
          ],
        ),
        bottomNavigationBar: ParentBottomNav(
          currentIndex: currentIndex,
          onTap: _onTabTap,
        ),
      ),
    );
  }
}

class ParentBottomNav extends StatelessWidget {
  const ParentBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.activeColor = const Color(0xFF004782),
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;

  static const _items = [
    _ParentNavItem(Icons.home_rounded, 'Inicio'),
    _ParentNavItem(Icons.map_rounded, 'Mapa'),
    _ParentNavItem(Icons.notifications_rounded, 'Notificaciones'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isActive = currentIndex == index;
            final color = isActive ? activeColor : Colors.grey.shade400;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, color: color, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        item.label.toUpperCase(),
                        style: GoogleFonts.publicSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ParentNavItem {
  const _ParentNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}
