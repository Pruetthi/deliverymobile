import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final profileCtl = TextEditingController();
  final addressCtl = TextEditingController();
  final altAddressCtl = TextEditingController();

  final db = FirebaseFirestore.instance;

  LatLng? addressLocation;
  LatLng? altAddressLocation;

  final String thunderforestKey = '88f9690d7c84430e8ebb75502e511790';

  // ---------------------------
  // ดึงตำแหน่งปัจจุบัน
  // ---------------------------
  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(pos.latitude, pos.longitude);
  }

  // ---------------------------
  // เปิดแผนที่เลือกตำแหน่ง
  // ---------------------------
  Future<LatLng?> _pickLocationDialog(
    BuildContext context,
    LatLng? startPos,
  ) async {
    LatLng? temp = startPos;

    return await showDialog<LatLng>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('เลือกตำแหน่งบนแผนที่'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: FutureBuilder<LatLng?>(
              future: _getCurrentLocation(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final initial = snapshot.data!;
                temp ??= initial;

                return StatefulBuilder(
                  builder: (context, setMapState) {
                    return FlutterMap(
                      options: MapOptions(
                        initialCenter: temp!,
                        initialZoom: 16,
                        onTap: (tapPos, latlng) {
                          setMapState(() {
                            temp = latlng;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=$thunderforestKey",
                          userAgentPackageName: 'com.example.app',
                        ),
                        if (temp != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: temp!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, temp),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------
  // บันทึกข้อมูลผู้ใช้
  // ---------------------------
  void addData() async {
    if (nameCtl.text.isEmpty ||
        phoneCtl.text.isEmpty ||
        passwordCtl.text.isEmpty ||
        addressLocation == null ||
        altAddressLocation == null) {
      Get.snackbar("Error", "กรุณากรอกข้อมูลและเลือกตำแหน่งทั้งสองที่ให้ครบ");
      return;
    }

    var docRef = db.collection('user').doc();
    await docRef.set({
      'uid': docRef.id,
      'name': nameCtl.text,
      'phone': phoneCtl.text,
      'password': passwordCtl.text,
      'profile_picture': profileCtl.text,
      'address': addressCtl.text,
      'alt_address': altAddressCtl.text,
      'status': 'user',
      'createdAt': DateTime.now(),
      'location1': {
        'latitude': addressLocation!.latitude,
        'longitude': addressLocation!.longitude,
      },
      'location2': {
        'latitude': altAddressLocation!.latitude,
        'longitude': altAddressLocation!.longitude,
      },
    });

    Get.snackbar("สำเร็จ", "สมัครสมาชิกเรียบร้อยแล้ว");
    Get.to(() => const LoginPage());
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField("Name", nameCtl),
            _buildTextField(
              "Phone",
              phoneCtl,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField("Password", passwordCtl, obscureText: true),
            _buildTextField("Profile Picture URL", profileCtl),
            _buildTextField("Address", addressCtl),
            _buildSelectButton(
              context,
              "เลือกตำแหน่งที่อยู่หลัก",
              addressLocation,
              (loc) => setState(() => addressLocation = loc),
            ),
            _buildTextField("Alternate Address", altAddressCtl),
            _buildSelectButton(
              context,
              "เลือกตำแหน่งที่อยู่สำรอง",
              altAddressLocation,
              (loc) => setState(() => altAddressLocation = loc),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addData,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: Colors.orange,
              ),
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------
  // Helper Widgets
  // ---------------------------
  Widget _buildTextField(
    String label,
    TextEditingController ctl, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: ctl,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSelectButton(
    BuildContext context,
    String label,
    LatLng? loc,
    Function(LatLng?) onSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.map),
        label: Text(
          loc == null
              ? label
              : "$label (เลือกแล้ว: ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})",
        ),
        onPressed: () async {
          LatLng? selected = await _pickLocationDialog(context, loc);
          if (selected != null) onSelect(selected);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Colors.orange),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}
