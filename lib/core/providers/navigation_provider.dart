import 'package:flutter_riverpod/flutter_riverpod.dart';

// Definición usando el patrón Notifier (estándar en este proyecto)
class DriverNavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final driverNavigationProvider = NotifierProvider<DriverNavigationNotifier, int>(() {
  return DriverNavigationNotifier();
});
