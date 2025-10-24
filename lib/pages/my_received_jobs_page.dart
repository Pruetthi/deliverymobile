import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/job_tracking_page.dart';
import 'package:flutter/material.dart';

class MyReceivedJobsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MyReceivedJobsPage({super.key, required this.userData});

  @override
  State<MyReceivedJobsPage> createState() => _MyReceivedJobsPageState();
}

class _MyReceivedJobsPageState extends State<MyReceivedJobsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('สินค้าที่ส่งมาหาฉัน'),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('jobs')
            .where('receiver_uid', isEqualTo: widget.userData['uid'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "ยังไม่มีสินค้าที่ส่งมาหาคุณ",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final jobs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;

              return Card(
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
                      // ชื่อสินค้า
                      Row(
                        children: [
                          const Icon(Icons.inventory_2, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              job['item_name'] ?? 'ไม่ระบุชื่อสินค้า',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // รายละเอียดสินค้า
                      Text(
                        job['item_detail'] ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: Colors.white54),

                      // ผู้ส่ง
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
                              'ผู้ส่ง: ${job['sender_name']} (${job['sender_phone']})',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // ที่อยู่
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
                              'ที่อยู่: ${job['address_text']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // พิกัด
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${(job['latitude'] as num?)?.toStringAsFixed(5)}, ${(job['longitude'] as num?)?.toStringAsFixed(5)})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // สถานะ
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
                      // ปุ่มดูแผนที่
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    JobTrackingPage(jobId: jobs[index].id),
                              ),
                            );
                          },

                          icon: const Icon(Icons.map, color: Colors.white),
                          label: const Text(
                            "ดูแผนที่",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
        return "ไรเดอร์รับงาน";
      case 3:
        return "ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง";
      case 4:
        return "ไรเดอร์นำส่งสินค้าแล้ว";
      default:
        return "ไม่ทราบสถานะ";
    }
  }
}
