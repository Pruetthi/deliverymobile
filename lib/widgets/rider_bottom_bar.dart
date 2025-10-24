import 'package:delivery/pages/home_rider.dart';
import 'package:delivery/pages/profile.dart';
import 'package:flutter/material.dart';

class RiderBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Map<String, dynamic> userData; // ✅ เพิ่ม userData

  const RiderBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userData, // ✅ รับ userData
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 167, 35),
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
                isSelected: currentIndex == 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeRiderPage(riderData: userData),
                    ),
                  );
                  onTap(0);
                },
              ),
              _buildBottomNavItem(
                icon: Icons.person,
                label: 'โปรไฟล์',
                isSelected: currentIndex == 1,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(userData: userData),
                    ),
                  );
                  onTap(1);
                },
              ),
            ],
          ),
        ),
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
