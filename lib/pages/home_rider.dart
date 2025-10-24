import 'dart:developer';

import 'package:delivery/pages/job_detail.rider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/rider_bottom_bar.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class HomeRiderPage extends StatefulWidget {
  final Map<String, dynamic> riderData;
  const HomeRiderPage({super.key, required this.riderData});

  @override
  State<HomeRiderPage> createState() => _HomeRiderPageState();
}

class _HomeRiderPageState extends State<HomeRiderPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Stream<List<QueryDocumentSnapshot>> fetchJobs() {
    return FirebaseFirestore.instance
        .collection('jobs')
        .where('rider_uid', isEqualTo: widget.riderData['uid'])
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> acceptJob(String jobId, Map<String, dynamic> job) async {
    try {
      final rider = widget.riderData;
      log(rider.toString());
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 2, // 1=รอรับ, 2=ไรเดอร์รับงานแล้ว
        'rider_uid': rider['rid'], // uid ของไรเดอร์
        'rider_name': rider['name'], // ชื่อไรเดอร์
        'rider_phone': rider['phone'], // เบอร์โทร
        'rider_vehicle_number': rider['vehicle_number'], // ทะเบียนรถ
        'rider_profile': rider['profile_picture'], // รูปโปรไฟล์
        'accepted_at': FieldValue.serverTimestamp(), // เวลารับงาน
      });
      RiderLocationUpdater().startUpdating(widget.riderData['rid']);

      // อัปเดตสถานะใน local state
      setState(() {
        job['status'] = 2;
        job['rider_uid'] = rider['uid'];
        job['rider_name'] = rider['name'];
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('รับงานเรียบร้อย ✅')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Image.asset(
                        'assets/delivery_logo.png',
                        height: 100,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.delivery_dining,
                          size: 70,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC857),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade300.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                widget.riderData['profile_picture'] != null &&
                                    widget
                                        .riderData['profile_picture']
                                        .isNotEmpty
                                ? NetworkImage(
                                    widget.riderData['profile_picture'],
                                  )
                                : null,
                            child: widget.riderData['profile_picture'] == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ยินดีต้อนรับ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5C3D2E),
                                ),
                              ),
                              Text(
                                'คุณ ${widget.riderData['name'] ?? 'ไรเดอร์'}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'งานจัดส่ง',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5C3D2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<QueryDocumentSnapshot>>(
                      stream: fetchJobs(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final jobs = snapshot.data!;
                        if (jobs.isEmpty) {
                          return const Text('ไม่มีงานจัดส่งในขณะนี้');
                        }

                        return Column(
                          children: jobs.map((doc) {
                            final job = doc.data() as Map<String, dynamic>;
                            return _buildJobCard(job, doc.id);
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RiderBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        userData: widget.riderData,
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, String jobId) {
    final isAccepted = job['status'] >= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สินค้า: ${job['item_name']}',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            'ผู้รับ: ${job['receiver_name']}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'สถานะ: ${job['status']}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!isAccepted)
                ElevatedButton.icon(
                  onPressed: () => acceptJob(jobId, job),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('รับงาน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade800,
                  ),
                ),
              if (isAccepted)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailRiderPage(
                          jobData: job,
                          userData: widget.riderData,
                          riderData: widget.riderData,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info, size: 18),
                  label: const Text('ดูรายละเอียด'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------- JobMapPage -------------------
class JobMapPage extends StatelessWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final double? riderLat;
  final double? riderLng;

  const JobMapPage({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    this.riderLat,
    this.riderLng,
  });

  @override
  Widget build(BuildContext context) {
    final centerLat = (pickupLat + dropLat) / 2;
    final centerLng = (pickupLng + dropLng) / 2;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=88f9690d7c84430e8ebb75502e511790',
          userAgentPackageName: 'com.example.delivery_app',
        ),
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
                    'ผู้ส่ง',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
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
                    'ผู้รับ',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (riderLat != null && riderLng != null)
              Marker(
                point: LatLng(riderLat!, riderLng!),
                width: 80,
                height: 80,
                child: Column(
                  children: const [
                    Icon(Icons.directions_bike, color: Colors.blue, size: 40),
                    Text(
                      'ไรเดอร์',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: [
                LatLng(pickupLat, pickupLng),
                if (riderLat != null && riderLng != null)
                  LatLng(riderLat!, riderLng!),
                LatLng(dropLat, dropLng),
              ],
              color: Colors.orangeAccent,
              strokeWidth: 4,
            ),
          ],
        ),
      ],
    );
  }
}

class RiderLocationUpdater {
  StreamSubscription<Position>? _positionStream;

  void startUpdating(String riderId) async {
    await Geolocator.requestPermission();

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
          ),
        ).listen((position) async {
          await FirebaseFirestore.instance
              .collection('riders')
              .doc(riderId)
              .set({
                'lat': position.latitude,
                'lng': position.longitude,
                'updated_at': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        });
  }

  void stopUpdating() => _positionStream?.cancel();
}
