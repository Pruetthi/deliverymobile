import 'dart:convert';
import 'package:delivery/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

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

  // ใส่ API Key ของ Google Maps
  final String googleApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
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
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 50),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: const Color(0xFFFFC857),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ชื่อ: ${widget.userData['name']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
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
                        ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text("Logout"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _loadAddresses() async {
    try {
      final loc1 = widget.userData['location1'];
      final loc2 = widget.userData['location2'];

      String? addr1;
      String? addr2;

      if (loc1 != null) {
        try {
          final placemarks1 = await placemarkFromCoordinates(
            loc1['latitude'],
            loc1['longitude'],
          );
          final place1 = placemarks1.first;
          addr1 =
              "${place1.street ?? ''}, ${place1.subLocality ?? ''}, ${place1.locality ?? ''}, ${place1.administrativeArea ?? ''}, ${place1.country ?? ''}";
        } catch (_) {}
      }

      if (loc2 != null) {
        try {
          final placemarks2 = await placemarkFromCoordinates(
            loc2['latitude'],
            loc2['longitude'],
          );
          final place2 = placemarks2.first;
          addr2 =
              "${place2.street ?? ''}, ${place2.subLocality ?? ''}, ${place2.locality ?? ''}, ${place2.administrativeArea ?? ''}, ${place2.country ?? ''}";
        } catch (_) {}
      }

      setState(() {
        address1 = addr1;
        address2 = addr2;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error loading address: $e');
    }
  }

  /// fallback ใช้ Google Maps API
  Future<String> getAddress(double lat, double lon) async {
    final apiKey = 'YOUR_API_KEY';
    final url = Uri.parse(
      'https://api.longdo.com/map/services/address?lat=$lat&lon=$lon&key=635aa8d2ec0896c5af0828783729e910',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['province'] != null) {
        return '${data['subdistrict']}, ${data['district']}, ${data['province']}';
      } else {
        return 'ไม่พบข้อมูลที่อยู่';
      }
    } else {
      return 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์';
    }
  }
}
