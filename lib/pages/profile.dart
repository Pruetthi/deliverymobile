import 'package:delivery/pages/login.dart';
import 'package:delivery/widgets/custom_bottom_bar.dart';
import 'package:delivery/widgets/rider_bottom_bar.dart';
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
            "${place1.street ?? ''}, ${place1.subLocality ?? ''}, ${place1.locality ?? ''}";
      }

      if (loc2 != null) {
        final placemarks2 = await placemarkFromCoordinates(
          loc2['latitude'],
          loc2['longitude'],
        );
        final place2 = placemarks2.first;
        address2 =
            "${place2.street ?? ''}, ${place2.subLocality ?? ''}, ${place2.locality ?? ''}";
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.orange.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: widget.userData['status'] == 'user'
                          ? _buildUserProfile()
                          : _buildRiderProfile(),
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: widget.userData['status'] == 'user'
          ? CustomBottomBar(
              userData: widget.userData,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            )
          : RiderBottomBar(
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
        const SizedBox(height: 16),
        Text(
          widget.userData['name'] ?? 'ไม่ระบุชื่อ',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.userData['phone'] ?? '-',
          style: const TextStyle(fontSize: 18, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        _buildInfoRow(Icons.home, 'ที่อยู่ 1', address1 ?? 'ไม่พบข้อมูล'),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.home_filled,
          'ที่อยู่ 2',
          address2 ?? 'ไม่พบข้อมูล',
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
        const SizedBox(height: 12),
        Text(
          widget.userData['name'] ?? 'ไม่ระบุชื่อ',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.userData['phone'] ?? '-',
          style: const TextStyle(fontSize: 18, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          Icons.directions_car,
          'ทะเบียนรถ',
          widget.userData['vehicle_number'] ?? '-',
        ),
        const SizedBox(height: 16),
        _buildVehiclePicture(widget.userData['vehicle_picture']),
        const SizedBox(height: 30),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildProfilePicture(String? url) {
    return CircleAvatar(
      radius: 70,
      backgroundColor: Colors.orange.shade100,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(70),
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                width: 140,
                height: 140,
                errorBuilder: (context, _, __) {
                  return Icon(
                    Icons.account_circle,
                    size: 140,
                    color: Colors.grey.shade700,
                  );
                },
              )
            : Icon(
                Icons.account_circle,
                size: 140,
                color: Colors.grey.shade700,
              ),
      ),
    );
  }

  Widget _buildVehiclePicture(String? url) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
        image: url != null && url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: url == null || url.isEmpty
          ? const Center(
              child: Icon(Icons.directions_bike, size: 60, color: Colors.grey),
            )
          : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text("Logout", style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: Colors.red.withOpacity(0.5),
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
        },
      ),
    );
  }
}
