import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/tracking_repository.dart';

class FirebaseTrackingRepository implements TrackingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> updateDriverLocation(String unitCode, double lat, double lng) async {
    try {
      await _firestore
          .collection('companies')
          .doc(unitCode)
          .collection('live_tracking')
          .doc('current')
          .set({
            'lat': lat,
            'lng': lng,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error al actualizar posición del chofer: $e');
    }
  }

  @override
  Stream<DocumentSnapshot> listenToDriverLocation(String unitCode) {
    return _firestore
        .collection('companies')
        .doc(unitCode)
        .collection('live_tracking')
        .doc('current')
        .snapshots();
  }
}
