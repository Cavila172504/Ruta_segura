import 'package:cloud_firestore/cloud_firestore.dart';

abstract class TrackingRepository {
  Future<void> updateDriverLocation(String unitCode, String driverId, String driverName, double lat, double lng);
  Future<void> updateRouteStatus(String unitCode, String driverId, String status);
  Stream<DocumentSnapshot> listenToDriverLocation(String unitCode, String driverId);
}
