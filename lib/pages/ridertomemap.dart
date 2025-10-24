import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RidersMapPage extends StatelessWidget {
  final String receiverUid;
  const RidersMapPage({super.key, required this.receiverUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ตำแหน่งไรเดอร์ที่จะมาส่ง"),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('receiver_uid', isEqualTo: receiverUid)
            .where('status', isGreaterThanOrEqualTo: 1)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔹 ถ้ายังโหลดอยู่
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔹 ถ้าไม่มีข้อมูลเลย
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("ยังไม่มีไรเดอร์กำลังมาส่งคุณ"));
          }

          final jobs = snapshot.data!.docs;

          List<Marker> markers = [];
          List<Polyline> polylines = [];
          double sumLat = 0, sumLng = 0;
          int count = 0;

          for (var jobDoc in jobs) {
            final job = jobDoc.data() as Map<String, dynamic>;

            final riderLat = (job['rider_lat'] ?? 0).toDouble();
            final riderLng = (job['rider_lng'] ?? 0).toDouble();
            final dropLat = (job['latitude'] ?? 0).toDouble();
            final dropLng = (job['longitude'] ?? 0).toDouble();

            // 🔸 ตรวจว่าค่าถูกต้องไหม (ไม่ใช่ 0,0)
            if (riderLat != 0 && riderLng != 0) {
              markers.add(
                Marker(
                  point: LatLng(riderLat, riderLng),
                  width: 45,
                  height: 45,
                  child: Tooltip(
                    message: job['rider_name'] ?? 'ไรเดอร์',
                    child: const Icon(
                      Icons.directions_bike,
                      color: Colors.blue,
                      size: 45,
                    ),
                  ),
                ),
              );

              // เส้นจากไรเดอร์ไปจุดส่ง
              if (dropLat != 0 && dropLng != 0) {
                polylines.add(
                  Polyline(
                    points: [
                      LatLng(riderLat, riderLng),
                      LatLng(dropLat, dropLng),
                    ],
                    color: Colors.orange,
                    strokeWidth: 3,
                  ),
                );
              }

              sumLat += riderLat;
              sumLng += riderLng;
              count++;
            }
          }

          // 🔹 ถ้าไม่มี marker เลย ให้ขึ้นข้อความแทน
          if (count == 0) {
            return const Center(child: Text("ไม่พบตำแหน่งของไรเดอร์"));
          }

          final center = LatLng(sumLat / count, sumLng / count);

          // 🔹 ใช้ FutureBuilder ป้องกัน Map โหลดก่อน center พร้อม
          return FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=88f9690d7c84430e8ebb75502e511790',
                userAgentPackageName: 'com.example.delivery_app',
              ),
              MarkerLayer(markers: markers),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            ],
          );
        },
      ),
    );
  }
}
