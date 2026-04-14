import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/tracking_repository.dart';

class FirebaseTrackingRepository implements TrackingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> updateDriverLocation(String unitCode, String driverId, String driverName, double lat, double lng) async {
    try {
      await _firestore
          .collection('companies')
          .doc(unitCode)
          .collection('live_tracking')
          .doc(driverId) // Cada chofer tiene su propio documento
          .set({
            'driverId': driverId,
            'driverName': driverName,
            'unitCode': unitCode,
            'lat': lat,
            'lng': lng,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error al actualizar posición del chofer: $e');
    }
  }

  @override
  Future<void> updateRouteStatus(String unitCode, String driverId, String status) async {
    try {
      await _firestore
          .collection('companies')
          .doc(unitCode)
          .collection('live_tracking')
          .doc(driverId)
          .set({
            'status': status,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error al actualizar estado de ruta: $e');
    }
  }

  @override
  Stream<DocumentSnapshot> listenToDriverLocation(String unitCode, String driverId) {
    return _firestore
        .collection('companies')
        .doc(unitCode)
        .collection('live_tracking')
        .doc(driverId)
        .snapshots();
  }
}
