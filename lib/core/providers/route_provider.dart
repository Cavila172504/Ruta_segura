import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_providers.dart';
import 'parent_member_utils.dart';
import '../utils/polyline_utils.dart';

// Proveedor para obtener el unitCode activo del padre
final activeUnitCodeProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final parentData = await readParentMemberData(user.uid);
  final fromProfile = resolveActiveUnitCode(parentData);
  if (fromProfile != null && fromProfile.isNotEmpty) {
    return fromProfile;
  }

  // Si no hay en perfil, buscar en la lista de sus estudiantes ya cargados
  final studentsAsync = await ref.watch(parentStudentsProvider.future);
  if (studentsAsync.isNotEmpty) {
    return normalizeUnitCode(studentsAsync.first['unitCode'] as String?);
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
      .doc(unitCode.trim().toUpperCase())
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

// Proveedor del tipo de ruta (to_school / from_school)
final busRouteTypeProvider = Provider<AsyncValue<String?>>((ref) {
  final dataAsync = ref.watch(activeBusDataProvider);
  return dataAsync.whenData((data) => data?['routeType'] as String?);
});

// Proveedor del estado actual de la ruta (idle, on_route)
final busStatusProvider = Provider<AsyncValue<String>>((ref) {
  final dataAsync = ref.watch(activeBusDataProvider);
  return dataAsync.whenData((data) => (data?['status'] as String?) ?? 'idle');
});

// Stream de las paradas de los estudiantes del padre (Hogar)
List<Map<String, dynamic>> _mapParentStudents(
  QuerySnapshot<Map<String, dynamic>> snap,
) {
  return snap.docs
      .map((doc) => {'id': doc.id, ...doc.data()})
      .where((student) {
        final status = (student['status'] as String?)?.toLowerCase() ?? 'active';
        return status != 'deleted' && status != 'rejected';
      })
      .toList();
}

final parentStudentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield [];
    return;
  }

  final memberRef = await ensureParentMemberRef(user);
  final parentData = (await memberRef.get()).data();
  String? unitCode = resolveActiveUnitCode(parentData);

  if (unitCode != null && unitCode.isNotEmpty) {
    yield* FirebaseFirestore.instance
        .collection('companies')
        .doc(unitCode)
        .collection('students')
        .where('parentId', isEqualTo: user.uid)
        .snapshots()
        .map(_mapParentStudents);
    return;
  }

  yield* memberRef
      .collection('students')
      .snapshots()
      .map(_mapParentStudents);
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
  final routeJson = ref.watch(busRouteJsonProvider).asData?.value;
  if (routeJson != null && routeJson.isNotEmpty) {
    final points = decodePolyline(routeJson);
    if (points.isNotEmpty) {
      return {
        Polyline(
          polylineId: const PolylineId('live_bus_route'),
          points: points,
          color: const Color(0xFF004782),
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }
  }

  final fallback = ref.watch(busRouteProvider);
  return {
    Polyline(
      polylineId: const PolylineId('bus_route'),
      points: fallback,
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

  final normalizedUnit = normalizeUnitCode(unitCode);
  if (normalizedUnit.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('companies')
      .doc(normalizedUnit)
      .collection('students')
      .where('status', isEqualTo: 'active')
      .where('driverId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => {
                'id': d.id,
                ...d.data(),
              })
          .toList());
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
