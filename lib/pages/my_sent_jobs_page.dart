import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MySentJobsPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MySentJobsPage({super.key, required this.userData});

  @override
  State<MySentJobsPage> createState() => _MySentJobsPageState();
}

class _MySentJobsPageState extends State<MySentJobsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

                      // ผู้รับ
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

  /// แปลงค่า status เป็นข้อความภาษาไทย
  String _getStatusText(dynamic status) {
    switch (status) {
      case 1:
        return "รอคนรับงาน";
      case 2:
        return "กำลังดำเนินการส่ง";
      case 3:
        return "จัดส่งสำเร็จ";
      default:
        return "ไม่ทราบสถานะ";
    }
  }
}
