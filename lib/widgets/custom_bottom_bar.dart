import 'package:delivery/pages/create_job_page.dart';
import 'package:delivery/pages/home.dart';
import 'package:delivery/pages/my_received_jobs_page.dart';
import 'package:delivery/pages/profile.dart';
import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Map<String, dynamic> userData; // เพิ่มเพื่อส่ง HomePage

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            // กด Home → ไป HomePage จริง
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HomePage(userData: userData)),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateJobPage(userData: userData),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyReceivedJobsPage(userData: userData),
              ),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(userData: userData),
              ),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(userData: userData),
              ),
            );
          } else if (index == 5) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(userData: userData),
              ),
            );
          }
          onTap(index);
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
    );
  }
}
