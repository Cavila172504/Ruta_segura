import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_providers.dart';

// Proveedor para obtener el unitCode activo del padre
final activeUnitCodeProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  // 1. Intentar obtenerlo del perfil (preferido)
  final profile = await ref.watch(userProfileProvider.future);
  if (profile?['activeUnitCode'] != null && profile!['activeUnitCode'].toString().isNotEmpty) {
    return profile['activeUnitCode'] as String;
  }

  // 2. Si no hay en perfil, buscar en la lista de sus estudiantes ya cargados
  final studentsAsync = await ref.watch(parentStudentsProvider.future);
  if (studentsAsync.isNotEmpty) {
    return studentsAsync.first['unitCode'] as String?;
  }

  return null;
});

// Proveedor para extraer los driverIds únicos de los estudiantes del padre
final activeDriverIdsProvider = Provider<List<String>>((ref) {
  final students = ref.watch(parentStudentsProvider).value;
  if (students == null || students.isEmpty) return [];
  
  return students
      .map((s) => s['driverId'] as String?)
      .where((id) => id != null && id.isNotEmpty)
      .cast<String>()
      .toSet()
      .toList();
});

// Stream de los datos del bus activo (solo para los conductores asignados a los hijos del padre)
final activeBusDataProvider = StreamProvider<Map<String, dynamic>?>((ref) async* {
  final unitCode = await ref.watch(activeUnitCodeProvider.future);
  final driverIds = ref.watch(activeDriverIdsProvider);

  if (unitCode == null || unitCode.trim().isEmpty || driverIds.isEmpty) {
    yield null;
    return;
  }

  // Firestore limita el 'whereIn' a 10 elementos como máximo.
  final safeDriverIds = driverIds.map((id) => id.trim()).where((id) => id.isNotEmpty).take(10).toList();
  
  if (safeDriverIds.isEmpty) {
    yield null;
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode.trim())
      .collection('live_tracking')
      .where(FieldPath.documentId, whereIn: safeDriverIds)
      .snapshots()
      .map((snap) {
        if (snap.docs.isEmpty) return null;
        
        // Priorizar el bus que esté 'on_route'
        final activeDocs = snap.docs.where((doc) => doc.data()['status'] == 'on_route').toList();
        if (activeDocs.isNotEmpty) {
          return activeDocs.first.data();
        }
        
        return null; // Ocultar el bus si el conductor no ha iniciado la ruta (status != 'on_route')
      });
});

// Proveedor de la ubicación real del bus
final liveBusLocationProvider = Provider<AsyncValue<LatLng?>>((ref) {
  final dataAsync = ref.watch(activeBusDataProvider);
  return dataAsync.whenData((data) {
    if (data == null || data['lat'] == null || data['lng'] == null) return null;
    return LatLng((data['lat'] as num).toDouble(), (data['lng'] as num).toDouble());
  });
});

// Proveedor para obtener la orientación del bus
final busHeadingProvider = Provider<AsyncValue<double>>((ref) {
  final dataAsync = ref.watch(activeBusDataProvider);
  return dataAsync.whenData((data) => (data?['heading'] as num?)?.toDouble() ?? 0.0);
});

// Proveedor para obtener el JSON de la ruta actual del bus
final busRouteJsonProvider = Provider<AsyncValue<String?>>((ref) {
  final dataAsync = ref.watch(activeBusDataProvider);
  return dataAsync.whenData((data) => data?['fullRouteJson'] as String?);
});

// Proveedor del estado actual de la ruta (idle, on_route)
final busStatusProvider = Provider<AsyncValue<String>>((ref) {
  final dataAsync = ref.watch(activeBusDataProvider);
  return dataAsync.whenData((data) => (data?['status'] as String?) ?? 'idle');
});

// Stream de las paradas de los estudiantes del padre (Hogar)
final parentStudentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  // Buscamos el documento del padre para extraer el unitCode
  final parentQuery = await FirebaseFirestore.instance
      .collection('users')
      .doc('parents')
      .collection('members')
      .where('uid', isEqualTo: user.uid)
      .limit(1)
      .get();

  if (parentQuery.docs.isEmpty) {
    yield [];
    return;
  }

  final parentData = parentQuery.docs.first.data();
  String? unitCode = parentData['activeUnitCode'] as String?;

  // Si no está en el perfil, revisamos la subcolección estática una sola vez
  if (unitCode == null || unitCode.isEmpty) {
    final subStudents = await parentQuery.docs.first.reference.collection('students').limit(1).get();
    if (subStudents.docs.isNotEmpty) {
      unitCode = subStudents.docs.first.data()['unitCode'] as String?;
    }
  }

  // Si logramos encontrar el unitCode, escuchamos la fuente de la verdad (donde el Admin actualiza)
  if (unitCode != null && unitCode.isNotEmpty) {
    yield* FirebaseFirestore.instance
        .collection('companies')
        .doc(unitCode)
        .collection('students')
        .where('parentId', isEqualTo: user.uid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  } else {
    // Fallback extremo
    yield* parentQuery.docs.first.reference
        .collection('students')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
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

// Lista de estudiantes de la unidad del conductor (solo aprobados y asignados a este conductor)
final driverStudentsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, unitCode) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode)
      .collection('students')
      .where('status', isEqualTo: 'active')
      .where('driverId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
});

final activeRouteProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, unitCode) async {
  final doc = await FirebaseFirestore.instance
      .collection('companies')
      .doc(unitCode)
      .collection('routes')
      .where('status', isEqualTo: 'active')
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
