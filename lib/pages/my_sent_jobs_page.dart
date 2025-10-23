import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/%E0%B9%88job_detail.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart'; // เพิ่มนี่

class MySentJobsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MySentJobsPage({super.key, required this.userData});

  @override
  State<MySentJobsPage> createState() => _MySentJobsPageState();
}

class _MySentJobsPageState extends State<MySentJobsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _addressCache = {}; // เก็บ address ของแต่ละ job id

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return "${p.thoroughfare ?? ''} ${p.subLocality ?? ''} ${p.locality ?? ''} ${p.administrativeArea ?? ''}"
            .trim();
      }
      return "-";
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('สินค้าที่กำลังส่งของฉัน'),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('jobs')
            .where('sender_uid', isEqualTo: widget.userData['uid'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "ยังไม่มีสินค้าที่คุณส่ง",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final jobList = snapshot.data!.docs.map((doc) {
            final job = doc.data() as Map<String, dynamic>;
            job['id'] = doc.id;
            return job;
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobList.length,
            itemBuilder: (context, index) {
              final job = jobList[index];

              return FutureBuilder<String>(
                future: _addressCache[job['id']] != null
                    ? Future.value(_addressCache[job['id']])
                    : _getAddressFromLatLng(job['latitude'], job['longitude']),
                builder: (context, addressSnapshot) {
                  if (addressSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final address = addressSnapshot.data ?? "-";
                  _addressCache[job['id']] = address;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailPage(
                            jobData: job,
                            userData: widget.userData,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: const Color(0xFFFFC857),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รหัสสินค้า: ${job['id']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              job['item_name'] ?? 'ไม่ระบุชื่อสินค้า',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              job['item_detail'] ?? '-',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white54),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'ผู้รับ: ${job['receiver_name']} (${job['receiver_phone']})',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.home,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'ที่อยู่: $address',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(job['status']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getStatusText(dynamic status) {
    switch (status) {
      case 1:
        return "รอคนรับงาน";
      case 2:
        return "กำลังดำเนินการส่ง";
      case 3:
        return "จัดส่งสำเร็จ";
      case 4:
        return "งานเสร็จสิ้น";
      default:
        return "ไม่ทราบสถานะ";
    }
  }
}
