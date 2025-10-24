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
            .where('status', whereIn: [2, 3]) // เฉพาะงานที่มีไรเดอร์แล้ว
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("ยังไม่มีไรเดอร์ที่กำลังมาส่งคุณ"));
          }

          final jobs = snapshot.data!.docs;
          final List<Marker> markers = [];
          final List<Polyline> polylines = [];

          double sumLat = 0;
          double sumLng = 0;
          int count = 0;

          for (var jobDoc in jobs) {
            final job = jobDoc.data() as Map<String, dynamic>;

            final riderLat = (job['rider_lat'] ?? 0).toDouble();
            final riderLng = (job['rider_lng'] ?? 0).toDouble();
            final dropLat = (job['latitude'] ?? 0).toDouble();
            final dropLng = (job['longitude'] ?? 0).toDouble();
            final altLat = (job['alt_latitude'] ?? 0).toDouble();
            final altLng = (job['alt_longitude'] ?? 0).toDouble();

            final riderUid = job['rider_uid'] ?? '';
            Color riderColor;

            // กำหนดสีแตกต่างตาม rider
            switch (riderUid) {
              case 'rider1':
                riderColor = Colors.blue;
                break;
              case 'rider2':
                riderColor = Colors.green;
                break;
              default:
                riderColor = Colors.orange;
            }

            if (riderLat != 0 && riderLng != 0) {
              // Marker ไรเดอร์
              markers.add(
                Marker(
                  point: LatLng(riderLat, riderLng),
                  width: 45,
                  height: 45,
                  child: Tooltip(
                    message: job['rider_name'] ?? 'ไรเดอร์',
                    child: Icon(
                      Icons.directions_bike,
                      color: riderColor,
                      size: 45,
                    ),
                  ),
                ),
              );

              // Marker จุดส่งหลัก
              if (dropLat != 0 && dropLng != 0) {
                markers.add(
                  Marker(
                    point: LatLng(dropLat, dropLng),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.home,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                  ),
                );

                // เส้นทาง Rider → จุดส่งหลัก
                polylines.add(
                  Polyline(
                    points: [
                      LatLng(riderLat, riderLng),
                      LatLng(dropLat, dropLng),
                    ],
                    color: const Color.fromARGB(0, 255, 153, 0),
                    strokeWidth: 4,
                  ),
                );
              }

              // Marker จุดส่งสำรอง
              if (altLat != 0 && altLng != 0) {
                markers.add(
                  Marker(
                    point: LatLng(altLat, altLng),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.home_outlined,
                      color: Colors.purple,
                      size: 40,
                    ),
                  ),
                );

                // เส้นทาง Rider → จุดส่งสำรอง
                polylines.add(
                  Polyline(
                    points: [
                      LatLng(riderLat, riderLng),
                      LatLng(altLat, altLng),
                    ],
                    color: Colors.purpleAccent,
                    strokeWidth: 3,
                  ),
                );
              }

              sumLat += riderLat;
              sumLng += riderLng;
              count++;
            }
          }

          if (count == 0) {
            return const Center(child: Text("ไม่พบตำแหน่งของไรเดอร์ในขณะนี้"));
          }

          final center = LatLng(sumLat / count, sumLng / count);

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=88f9690d7c84430e8ebb75502e511790',
                userAgentPackageName: 'com.example.delivery_app',
              ),
              MarkerLayer(markers: markers),
              PolylineLayer(polylines: polylines),
            ],
          );
        },
      ),
    );
  }
}
