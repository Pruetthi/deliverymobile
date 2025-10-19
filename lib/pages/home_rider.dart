import 'package:flutter/material.dart';

class HomeRiderPage extends StatefulWidget {
  final Map<String, dynamic> riderData;
  const HomeRiderPage({super.key, required this.riderData});

  @override
  State<HomeRiderPage> createState() => _HomeRiderPageState();
}

class _HomeRiderPageState extends State<HomeRiderPage> {
  int _selectedIndex = 0;

  // Mock data for jobs
  final List<Map<String, dynamic>> jobs = [
    {'id': 1, 'status': 'รอไปรับ', 'description': 'หมายเลขการจัดส่ง : 1'},
    {'id': 2, 'status': 'รับงาน', 'description': 'หมายเลขการจัดส่ง : 2'},
  ];

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
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.orange.shade800,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.orange.shade800,
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
                                    'คุณ ${widget.riderData['name'] ?? 'บารอน อีไระ'}',
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

                      // Job Cards
                      ...jobs.map((job) => _buildJobCard(job)).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  icon: Icons.home,
                  label: 'หน้าแรก',
                  isSelected: _selectedIndex == 0,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
                _buildBottomNavItem(
                  icon: Icons.person,
                  label: 'โปรไฟล์',
                  isSelected: _selectedIndex == 1,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'สถานะ: ${job['status']}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
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
              job['status'],
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

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
