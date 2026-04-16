import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_providers.dart';

// Proveedor para obtener el unitCode activo del padre
final activeUnitCodeProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final profile = await ref.watch(userProfileProvider.future);
  final profileCode = profile?['activeUnitCode'] as String?;
  
  if (profileCode != null) return profileCode;

  // Si no está en perfil, buscamos en sus estudiantes vinculados
  final students = await FirebaseFirestore.instance
      .collectionGroup('students')
      .where('parentId', isEqualTo: user.uid)
      .limit(1)
      .get();

  if (students.docs.isNotEmpty) {
    return students.docs.first.data()['unitCode'] as String?;
  }

  return null;
});

// Stream de la ubicación real del bus desde Firestore
final liveBusLocationProvider = StreamProvider<LatLng?>((ref) {
  final unitCode = ref.watch(activeUnitCodeProvider).value;
  if (unitCode == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode)
      .collection('live_tracking')
      .limit(1)
      .snapshots()
      .map((snap) {
        if (snap.docs.isEmpty) return null;
        final data = snap.docs.first.data();
        if (data['lat'] == null || data['lng'] == null) return null;
        return LatLng(data['lat'] as double, data['lng'] as double);
      });
});

// Stream del estado actual de la ruta (idle, on_route)
final busStatusProvider = StreamProvider<String>((ref) {
  final unitCode = ref.watch(activeUnitCodeProvider).value;
  if (unitCode == null) return Stream.value('idle');

  return FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode)
      .collection('live_tracking')
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty ? 'idle' : (snap.docs.first.data()['status'] as String?) ?? 'idle');
});

// Stream de las paradas de los estudiantes del padre (Hogar)
final parentStudentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final unitCode = ref.watch(activeUnitCodeProvider).value;
  if (user == null || unitCode == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode)
      .collection('students')
      .where('parentId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) {
        if (snap.docs.isEmpty) {
          // Fallback para pruebas si no hay datos reales vinculados
          return [
            {
              'studentName': 'ESTUDIANTE DE PRUEBA',
              'stopLat': -0.180653,
              'stopLng': -0.467834,
            }
          ];
        }
        return snap.docs.map((doc) => doc.data()).toList();
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
// Estado de la ruta específica del conductor (en tiempo real)
final driverRouteStatusProvider = StreamProvider.family<Map<String, dynamic>?, ({String unitCode, String driverId})>((ref, arg) {
  return FirebaseFirestore.instance
      .collection('companies')
      .doc(arg.unitCode)
      .collection('live_tracking')
      .doc(arg.driverId)
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null);
});
