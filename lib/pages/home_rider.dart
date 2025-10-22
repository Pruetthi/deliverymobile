import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    setState(() {
      _selectedIndex = index;
    });
  }

  // 🔹 Stream ดึงงานทั้งหมดที่ status = 1 (รอจัดส่ง)
  Stream<List<Map<String, dynamic>>> fetchJobs() {
    return FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList(),
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

                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/delivery_logo.png',
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              children: [
                                Icon(
                                  Icons.delivery_dining,
                                  size: 70,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Delivery',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Rider Profile Card
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
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.orange.shade800,
                                  width: 3,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child:
                                    widget.riderData['profile_picture'] !=
                                            null &&
                                        widget
                                            .riderData['profile_picture']
                                            .isNotEmpty
                                    ? Image.network(
                                        widget.riderData['profile_picture'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, _, __) {
                                          return Icon(
                                            Icons.account_circle,
                                            size: 60,
                                            color: Colors.grey.shade700,
                                          );
                                        },
                                      )
                                    : Icon(
                                        Icons.account_circle,
                                        size: 60,
                                        color: Colors.grey.shade700,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
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
                                    'คุณ ${widget.riderData['name'] ?? 'ผู้ขนส่ง'}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.orange.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Jobs Section Header
                      const Text(
                        'งานจัดส่ง',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5C3D2E),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 🔹 StreamBuilder ดึงงานจริงจาก Firestore
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: fetchJobs(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('ไม่มีงานจัดส่งในขณะนี้');
                          }

                          final jobs = snapshot.data!;
                          return Column(
                            children: jobs
                                .map((job) => _buildJobCard(job))
                                .toList(),
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

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade300.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // แสดงรูปสินค้า ถ้ามี
          if (job['item_image'] != null && job['item_image'] != "")
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  job['item_image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      color: Colors.white70,
                    );
                  },
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'หมายเลขการจัดส่ง: ${job['receiver_uid'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ชื่อผู้รับ: ${job['receiver_name'] ?? ''}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                Text(
                  'สถานะ: ${job['status']}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                Text(
                  'สินค้า: ${job['item_name']}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${job['latitude'].toStringAsFixed(5)}, ${job['longitude'].toStringAsFixed(5)})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              job['status'].toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
