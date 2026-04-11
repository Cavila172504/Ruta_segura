import 'package:cloud_firestore/cloud_firestore.dart';

abstract class TrackingRepository {
  Future<void> updateDriverLocation(String unitCode, double lat, double lng);
  Stream<DocumentSnapshot> listenToDriverLocation(String unitCode);
}
