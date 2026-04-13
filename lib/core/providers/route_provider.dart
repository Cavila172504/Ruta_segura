import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_providers.dart';

// Proveedor para obtener el unitCode activo del padre
final activeUnitCodeProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  // Buscamos en qué compañía está registrado este padre
  // Nota: Esto es una simplificación, asumiendo que el padre está en la colección global 'parents' 
  // o buscando en las compañías. Por ahora, buscaremos en el perfil del usuario.
  final profile = await ref.watch(userProfileProvider.future);
  return profile?['activeUnitCode'] as String?;
});

// Stream de la ubicación real del bus desde Firestore
final liveBusLocationProvider = StreamProvider<LatLng?>((ref) {
  final unitCode = ref.watch(activeUnitCodeProvider).value;
  if (unitCode == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode)
      .collection('live_tracking')
      .doc('current')
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        final data = doc.data()!;
        return LatLng(data['lat'] as double, data['lng'] as double);
      });
});

// Stream de la parada del estudiante (Hogar)
final studentStopProvider = StreamProvider<LatLng?>((ref) {
  final user = ref.watch(authStateProvider).value;
  final unitCode = ref.watch(activeUnitCodeProvider).value;
  if (user == null || unitCode == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode)
      .collection('students')
      .where('parentId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) {
        if (snap.docs.isEmpty) {
          // Fallback para pruebas: Centro de un sector residencial en Quito
          return const LatLng(-0.180653, -78.467834); 
        }
        final data = snap.docs.first.data();
        return LatLng(data['stopLat'] as double, data['stopLng'] as double);
      });
});

final busRouteProvider = Provider<List<LatLng>>((ref) {
  // Por ahora mantenemos una ruta base, pero se podría cargar de Firestore
  return const [
    LatLng(-0.180653, -78.467834),
    LatLng(-0.182653, -78.470834),
    LatLng(-0.185653, -78.472834),
    LatLng(-0.188653, -78.475834),
    LatLng(-0.191653, -78.478834),
  ];
});

final activePolylinesProvider = Provider<Set<Polyline>>((ref) {
  final points = ref.watch(busRouteProvider);
  
  return {
    Polyline(
      polylineId: const PolylineId('bus_route'),
      points: points,
      color: const Color(0xFF004782),
      width: 5,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    ),
  };
});

// Lista de estudiantes de la unidad del conductor (en tiempo real)
final driverStudentsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, unitCode) {
  return FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode)
      .collection('students')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
});

final activeRouteProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, unitCode) async {
  final doc = await FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode)
      .collection('routes')
      .where('isActive', isEqualTo: true)
      .limit(1)
      .get();

  if (doc.docs.isEmpty) return null;
  return doc.docs.first.data();
});
