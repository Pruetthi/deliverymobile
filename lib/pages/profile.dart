import 'package:delivery/pages/login.dart';
import 'package:delivery/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? address1;
  String? address2;
  bool isLoading = true;

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final loc1 = widget.userData['location1'];
      final loc2 = widget.userData['location2'];

      if (loc1 != null) {
        final placemarks1 = await placemarkFromCoordinates(
          loc1['latitude'],
          loc1['longitude'],
        );
        final place1 = placemarks1.first;
        address1 =
            "${place1.street ?? ''}, ${place1.subLocality ?? ''}, ${place1.locality ?? ''}, ${place1.administrativeArea ?? ''}, ${place1.country ?? ''}";
      }

      if (loc2 != null) {
        final placemarks2 = await placemarkFromCoordinates(
          loc2['latitude'],
          loc2['longitude'],
        );
        final place2 = placemarks2.first;
        address2 =
            "${place2.street ?? ''}, ${place2.subLocality ?? ''}, ${place2.locality ?? ''}, ${place2.administrativeArea ?? ''}, ${place2.country ?? ''}";
      }
    } catch (e) {
      debugPrint('Error loading address: $e');
      address1 ??= "ไม่พบข้อมูล";
      address2 ??= "ไม่พบข้อมูล";
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน'),
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: const Color(0xFFFFC857),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: widget.userData['status'] == 'user'
                        ? _buildUserProfile()
                        : _buildRiderProfile(),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomBar(
        userData: widget.userData,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildUserProfile() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProfilePicture(widget.userData['profile_picture']),
        Text(
          'ชื่อ: ${widget.userData['name']}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          'เบอร์โทร: ${widget.userData['phone']}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 20),
        Text(
          'ที่อยู่ 1: ${address1 ?? 'ไม่พบข้อมูล'}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          'ที่อยู่ 2: ${address2 ?? 'ไม่พบข้อมูล'}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 30),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildRiderProfile() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProfilePicture(widget.userData['profile_picture']),
        const SizedBox(height: 8),
        Text(
          'ชื่อ: ${widget.userData['name']}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          'เบอร์โทร: ${widget.userData['phone']}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        Text(
          'ทะเบียนรถ: ${widget.userData['vehicle_number']}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        _buildVehiclePicture(widget.userData['vehicle_picture']),
        const SizedBox(height: 30),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildProfilePicture(String? url) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange.shade800, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: url != null && url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) {
                    return Icon(
                      Icons.account_circle,
                      size: 200,
                      color: Colors.grey.shade700,
                    );
                  },
                )
              : Icon(
                  Icons.account_circle,
                  size: 200,
                  color: Colors.grey.shade700,
                ),
        ),
      ),
    );
  }

  Widget _buildVehiclePicture(String? url) {
    return SizedBox(
      width: 120,
      height: 80,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          image: url != null && url.isNotEmpty
              ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
              : null,
        ),
        child: url == null || url.isEmpty
            ? const Icon(Icons.directions_bike, size: 50)
            : null,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text("Logout"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      },
    );
  }
}
