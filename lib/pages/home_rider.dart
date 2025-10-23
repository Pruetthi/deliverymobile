import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/rider_bottom_bar.dart';

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

  // 🔹 Stream ดึงงานทั้งหมดที่ status = 1 (รอจัดส่ง)
  Stream<List<QueryDocumentSnapshot>> fetchJobs() {
    return FirebaseFirestore.instance
        .collection('jobs')
        .where(
          'rider_uid',
          isEqualTo: widget.riderData['uid'],
        ) // งานของไรเดอร์คนนี้
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // 🔹 รับงานแล้วเปิดแผนที่ทันที
  Future<void> acceptJob(String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 2,
        'rider_uid': widget.riderData['uid'],
        'rider_name': widget.riderData['name'],
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

  Future<void> acceptJobAndOpenMap(
    String jobId,
    Map<String, dynamic> job,
  ) async {
    try {
      // อัปเดตสถานะงาน
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({
        'status': 2,
        'rider_uid': widget.riderData['uid'],
        'rider_name': widget.riderData['name'],
      });

      // แจ้งเตือน
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('รับงานเรียบร้อย ✅')));

      // เปิดหน้าแผนที่
      openMap(
        job['pickup_latitude'],
        job['pickup_longitude'],
        job['latitude'] ?? 16.2477, // fallback พิกัดจำลอง
        job['longitude'] ?? 103.2532,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  // 🔹 เปิดหน้าแผนที่ Thunderforest
  void openMap(
    double pickupLat,
    double pickupLng,
    double dropLat,
    double dropLng,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobMapPage(
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          dropLat: dropLat,
          dropLng: dropLng,
        ),
      ),
    );
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // โลโก้
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

                      // โปรไฟล์ไรเดอร์
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
                  onPressed: () => acceptJobAndOpenMap(jobId, job),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('รับงาน'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade800,
                  ),
                ),

              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => openMap(
                  job['pickup_latitude'],
                  job['pickup_longitude'],
                  job['latitude'] ?? 16.2477,
                  job['longitude'] ?? 103.2532,
                ),
                icon: const Icon(Icons.map, size: 18),
                label: const Text('ดูแผนที่'),
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

// 🔹 หน้าดูแผนที่ (Thunderforest)
class JobMapPage extends StatelessWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;

  const JobMapPage({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่จัดส่ง'),
        backgroundColor: Colors.orange,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(pickupLat, pickupLng),
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
                child: const Icon(Icons.store, color: Colors.green, size: 40),
              ),
              // Marker(
              //   point: LatLng(dropLat, dropLng),
              //   width: 80,
              //   height: 80,
              //   child: const Icon(
              //     Icons.location_on,
              //     color: Colors.red,
              //     size: 40,
              //   ),
              // ),
              Marker(
                point: LatLng(16.2477, 103.2532), // พิกัดจำลองผู้รับ
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  LatLng(pickupLat, pickupLng),
                  LatLng(dropLat, dropLng),
                ],
                color: Colors.orangeAccent,
                strokeWidth: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
