import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

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
                        'assets/delivery_logo.png',
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.orange.shade800,
                                  width: 2,
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
                              // Navigate to send package
                            },
                          ),
                          _buildMenuCard(
                            icon: Icons.inventory_2,
                            label: 'สินค้าที่จะถึง',
                            onTap: () {
                              // Navigate to incoming packages
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
                              // Navigate to delivering packages
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFFF6B35),
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
            BottomNavigationBarItem(icon: Icon(Icons.send), label: 'ส่งสินค้า'),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2),
              label: 'สินค้าที่จะถึง',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on),
              label: 'ดูพัดสินค้า',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
          ],
        ),
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
