import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobTrackingPage extends StatefulWidget {
  final String jobId;
  const JobTrackingPage({Key? key, required this.jobId}) : super(key: key);

  @override
  State<JobTrackingPage> createState() => _JobTrackingPageState();
}

class _JobTrackingPageState extends State<JobTrackingPage> {
  List<LatLng> routePoints = [];
  bool routeLoaded = false;
  bool routeFailed = false;

  @override
  void initState() {
    super.initState();
    loadInitialRoute();
  }

  /// ✅ โหลดเส้นทางจากร้าน → ผู้รับ เพียงครั้งเดียว
  Future<void> loadInitialRoute() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final pickupLat = (data['pickup_latitude'] ?? 0).toDouble();
      final pickupLng = (data['pickup_longitude'] ?? 0).toDouble();
      final dropLat = (data['latitude'] ?? 0).toDouble();
      final dropLng = (data['longitude'] ?? 0).toDouble();

      final points = await getRoute(pickupLat, pickupLng, dropLat, dropLng);

      setState(() {
        routePoints = points;
        routeLoaded = true;
      });
    } catch (e) {
      debugPrint("❌ โหลดเส้นทางล้มเหลว: $e");
      setState(() {
        routeFailed = true; // ✅ บอกว่าโหลดไม่สำเร็จ
      });
    }
  }

  /// ✅ ดึงเส้นทางจาก OSRM API
  Future<List<LatLng>> getRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      return coords.map((c) => LatLng(c[1], c[0])).toList();
    } else {
      throw Exception('ไม่สามารถดึงเส้นทางได้');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ติดตามพัสดุ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.jobId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final pickupLat = (data['pickup_latitude'] ?? 0).toDouble();
          final pickupLng = (data['pickup_longitude'] ?? 0).toDouble();
          final dropLat = (data['latitude'] ?? 0).toDouble();
          final dropLng = (data['longitude'] ?? 0).toDouble();
          final riderLat = (data['rider_lat'] ?? 0).toDouble();
          final riderLng = (data['rider_lng'] ?? 0).toDouble();

          final hasRider = riderLat != 0 && riderLng != 0;

          final center = routePoints.isNotEmpty
              ? routePoints[routePoints.length ~/ 2]
              : LatLng(pickupLat, pickupLng);

          return FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=88f9690d7c84430e8ebb75502e511790',
                userAgentPackageName: 'com.example.delivery_app',
              ),
              // ✅ Marker จุดต่าง ๆ
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(pickupLat, pickupLng),
                    width: 80,
                    height: 80,
                    child: Column(
                      children: const [
                        Icon(Icons.store, color: Colors.green, size: 40),
                        Text(
                          "ร้านผู้ส่ง",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasRider)
                    Marker(
                      point: LatLng(riderLat, riderLng),
                      width: 80,
                      height: 80,
                      child: Column(
                        children: const [
                          Icon(
                            Icons.directions_bike,
                            color: Colors.blue,
                            size: 40,
                          ),
                          Text(
                            "ไรเดอร์",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Marker(
                    point: LatLng(dropLat, dropLng),
                    width: 80,
                    height: 80,
                    child: Column(
                      children: const [
                        Icon(Icons.location_on, color: Colors.red, size: 40),
                        Text(
                          "ผู้รับ",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ✅ แสดงเส้นทางเฉพาะเมื่อโหลดสำเร็จ
              if (routeLoaded && routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: Colors.orangeAccent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
