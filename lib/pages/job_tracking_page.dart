import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class JobTrackingPage extends StatelessWidget {
  final String jobId;
  const JobTrackingPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ติดตามตำแหน่งไรเดอร์"),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // 📍 ดึงพิกัดทั้งหมด
          final pickupLat = (data['pickup_latitude'] ?? 0).toDouble();
          final pickupLng = (data['pickup_longitude'] ?? 0).toDouble();
          final dropLat = (data['latitude'] ?? 0).toDouble();
          final dropLng = (data['longitude'] ?? 0).toDouble();
          final riderLat = (data['rider_lat'] ?? 0).toDouble();
          final riderLng = (data['rider_lng'] ?? 0).toDouble();

          // คำนวณจุดศูนย์กลางของแผนที่
          final center = LatLng(
            (pickupLat + dropLat) / 2,
            (pickupLng + dropLng) / 2,
          );

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),

            // ✅ ใช้ 'children' (required)
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=88f9690d7c84430e8ebb75502e511790',
                userAgentPackageName: 'com.example.delivery_app',
              ),

              MarkerLayer(
                markers: [
                  // จุดรับสินค้า
                  Marker(
                    point: LatLng(pickupLat, pickupLng),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.store,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  // จุดปลายทาง
                  Marker(
                    point: LatLng(dropLat, dropLng),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.home, color: Colors.red, size: 40),
                  ),
                  // จุดไรเดอร์
                  if (riderLat != 0 && riderLng != 0)
                    Marker(
                      point: LatLng(riderLat, riderLng),
                      width: 45,
                      height: 45,
                      child: const Icon(
                        Icons.directions_bike,
                        color: Colors.blue,
                        size: 45,
                      ),
                    ),
                ],
              ),

              // เส้นทางระหว่าง pickup → rider → drop
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      LatLng(pickupLat, pickupLng),
                      if (riderLat != 0 && riderLng != 0)
                        LatLng(riderLat, riderLng),
                      LatLng(dropLat, dropLng),
                    ],
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
