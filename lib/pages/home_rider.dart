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
  bool showAvailableJobs = true; // ✅ ตัวแปรสลับดู "งานว่าง" / "งานของฉัน"

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  /// ✅ ดึงข้อมูลจาก Firestore ตามโหมดที่เลือก
  Stream<List<QueryDocumentSnapshot>> fetchJobs() {
    final ref = FirebaseFirestore.instance.collection('jobs');
    log('uid: ${widget.riderData['rid']}');
    if (showAvailableJobs) {
      // งานว่าง = status = 1 และยังไม่มี rider
      return ref
          .where('status', isEqualTo: 1)
          .snapshots()
          .map((snapshot) => snapshot.docs);
    } else {
      // งานของไรเดอร์คนนี้ = status >=2 และ rider_uid == uid ของเรา
      return ref
          .where('status', whereIn: [2, 3, 4])
          .where('rider_uid', isEqualTo: widget.riderData['rid'])
          .snapshots()
          .map((snapshot) => snapshot.docs);
    }
  }

  Future<void> acceptJob(String jobId, Map<String, dynamic> job) async {
    try {
      final rider = widget.riderData;

      // 🔹 ดึงตำแหน่งปัจจุบัน
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 2,
        'rider_uid': rider['rid'], // ใช้ rid
        'rider_name': rider['name'],
        'rider_phone': rider['phone'],
        'rider_vehicle_number': rider['vehicle_number'],
        'rider_profile': rider['profile_picture'],
        'accepted_at': FieldValue.serverTimestamp(),
        'rider_lat': position.latitude, // เพิ่มตำแหน่งตอนรับงาน
        'rider_lng': position.longitude, // เพิ่มตำแหน่งตอนรับงาน
        'rider_updated_at': FieldValue.serverTimestamp(),
      });

      // 🔹 เริ่มอัปเดตตำแหน่งแบบเรียลไทม์ต่อ
      RiderLocationUpdater().startUpdating(jobId);

      setState(() {
        job['status'] = 2;
        job['rider_uid'] = rider['rid'];
        job['rider_lat'] = position.latitude; // เก็บใน local job map ด้วย
        job['rider_lng'] = position.longitude;
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
                    _buildRiderInfoCard(),
                    const SizedBox(height: 24),

                    // ✅ ปุ่มสลับโหมด
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'รายการงานจัดส่ง',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C3D2E),
                          ),
                        ),
                        Switch(
                          value: showAvailableJobs,
                          activeColor: Colors.orange,
                          onChanged: (v) =>
                              setState(() => showAvailableJobs = v),
                        ),
                      ],
                    ),
                    Text(
                      showAvailableJobs
                          ? 'แสดงเฉพาะงานที่ยังไม่มีใครรับ (status = 1)'
                          : 'แสดงเฉพาะงานที่คุณรับแล้ว',
                      style: const TextStyle(fontSize: 14, color: Colors.brown),
                    ),
                    const SizedBox(height: 12),

                    // ✅ แสดงข้อมูลงาน
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
                          return Center(
                            child: Text(
                              showAvailableJobs
                                  ? 'ยังไม่มีงานว่างในขณะนี้'
                                  : 'คุณยังไม่ได้รับงานใด ๆ',
                              style: const TextStyle(color: Colors.brown),
                            ),
                          );
                        }

                        return Column(
                          children: jobs.map((doc) {
                            final job = doc.data() as Map<String, dynamic>;
                            job['id'] = doc.id;
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

  Widget _buildRiderInfoCard() {
    return Container(
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
                    widget.riderData['profile_picture'].isNotEmpty
                ? NetworkImage(widget.riderData['profile_picture'])
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
                style: TextStyle(fontSize: 15, color: Colors.orange.shade900),
              ),
            ],
          ),
        ],
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
              if (showAvailableJobs && job['status'] == 1)
                ElevatedButton.icon(
                  onPressed: () => acceptJob(jobId, job),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('รับงาน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade800,
                  ),
                ),
              if (!showAvailableJobs)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailRiderPage(
                          jobData: job,
                          userData: widget.riderData,
                          riderData: widget.riderData,
                          jobId: jobId,
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

  Future<void> startUpdating(String jobId) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      print("❌ ไม่มีสิทธิ์เข้าถึงตำแหน่ง");
      return;
    }

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((position) async {
          try {
            await FirebaseFirestore.instance
                .collection('jobs')
                .doc(jobId)
                .update({
                  'rider_lat': position.latitude,
                  'rider_lng': position.longitude,
                  'rider_updated_at': FieldValue.serverTimestamp(),
                });
            print(
              "📍 อัปเดตตำแหน่ง: ${position.latitude}, ${position.longitude}",
            );
          } catch (e) {
            print("⚠️ อัปเดตตำแหน่งล้มเหลว: $e");
          }
        });
  }

  void stopUpdating() {
    _positionStream?.cancel();
    print("🛑 หยุดอัปเดตตำแหน่งแล้ว");
  }
}
