import 'package:delivery/pages/create_job_page.dart';
import 'package:delivery/pages/my_received_jobs_page.dart';
import 'package:delivery/pages/my_sent_jobs_page.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_bottom_bar.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
                    children: [
                      const SizedBox(height: 20),
                      // Logo
                      Image.asset(
                        'assets/images/delivery_logo.jpg',
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            children: [
                              Icon(
                                Icons.delivery_dining,
                                size: 80,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Delivery',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      // User Profile Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
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
                                  width: 2,
                                ),
                              ),
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child:
                                      widget.userData['profile_picture'] != null
                                      ? Image.network(
                                          widget.userData['profile_picture'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
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
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ยินดีต้อนรับ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5C3D2E),
                                    ),
                                  ),
                                  Text(
                                    'คุณ ${widget.userData['name'] ?? 'บารอน อีไระ'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Menu Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildMenuCard(
                            icon: Icons.send,
                            label: 'ส่งสินค้า',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CreateJobPage(userData: widget.userData),
                                ),
                              );
                            },
                          ),

                          _buildMenuCard(
                            icon: Icons.inventory_2,
                            label: 'สินค้าที่จะถึง',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MyReceivedJobsPage(
                                    userData: widget.userData,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.location_on,
                            label: 'ดูพัดสินค้า\nที่ส่ง',
                            onTap: () {
                              // Navigate to track package
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.inventory,
                            label: 'สินค้าที่กำลังส่ง',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MySentJobsPage(userData: widget.userData),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        userData: widget.userData,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade300.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
