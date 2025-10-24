import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
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

  final db = FirebaseFirestore.instance;
  LatLng? addressLocation;
  LatLng? altAddressLocation;
  String? addressName;
  String? altAddressName;

  final String thunderforestKey = '88f9690d7c84430e8ebb75502e511790';

  // ✅ สำหรับเลือกรูป
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic(
    'daqjnjmto', // 👉 เปลี่ยนเป็น Cloud name ของคุณ
    'unsigned_delivery', // 👉 upload preset ที่ตั้งไว้ใน Cloudinary
    cache: false,
  );

  bool _loading = false;

  // ---------------------------
  // เลือกรูปจากแกลเลอรี
  // ---------------------------
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  // ---------------------------
  // อัปโหลดรูปไป Cloudinary
  // ---------------------------
  Future<String?> uploadImage(File image) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, folder: "user_profiles"),
      );
      return response.secureUrl;
    } catch (e) {
      Get.snackbar("Error", "อัปโหลดรูปไม่สำเร็จ: $e");
      return null;
    }
  }

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
      Get.snackbar("Error", "กรุณากรอกข้อมูลให้ครบ");
      return;
    }

    setState(() => _loading = true);

    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await uploadImage(_pickedImage!);
    }

    // ✅ ตรวจสอบเบอร์ซ้ำใน user ก่อน
    var existingUser = await db
        .collection('user')
        .where('phone', isEqualTo: phoneCtl.text)
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      Get.snackbar("Error", "เบอร์นี้ถูกใช้สมัครผู้ใช้อยู่แล้ว");
      setState(() => _loading = false);
      return;
    }

    // ✅ ตรวจสอบเบอร์กับ rider
    var existingRider = await db
        .collection('rider')
        .where('phone', isEqualTo: phoneCtl.text)
        .limit(1)
        .get();

    if (existingRider.docs.isNotEmpty) {
      var riderPassword = existingRider.docs.first['password'];
      if (riderPassword == passwordCtl.text) {
        Get.snackbar(
          "Error",
          "ห้ามใช้รหัสผ่านเดียวกับบัญชี Rider",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() => _loading = false);
        return;
      }
    }

    // ✅ ถ้าไม่มีปัญหา -> บันทึกข้อมูลลง Firestore
    var docRef = db.collection('user').doc();
    await docRef.set({
      'uid': docRef.id,
      'name': nameCtl.text,
      'phone': phoneCtl.text,
      'password': passwordCtl.text,
      'profile_picture': imageUrl ?? '',
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

    setState(() => _loading = false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            _buildTextField("Name", nameCtl),
            _buildTextField(
              "Phone",
              phoneCtl,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField("Password", passwordCtl, obscureText: true),
            _buildSelectButton(
              context,
              "เลือกตำแหน่งที่อยู่หลัก",
              addressLocation,
              (loc) => setState(() => addressLocation = loc),
              isMain: true,
            ),
            _buildSelectButton(
              context,
              "เลือกตำแหน่งที่อยู่สำรอง",
              altAddressLocation,
              (loc) => setState(() => altAddressLocation = loc),
              isMain: false,
            ),
            const SizedBox(height: 10),
            if (_pickedImage != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    _pickedImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.photo, color: Colors.white),
              label: const Text(
                "เลือกรูปโปรไฟล์",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFAB12F), // สีหลักของปุ่ม
                foregroundColor: Colors.white, // สีของข้อความและไอคอน
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : addData,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFFFA812F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Confirm",
                      style: TextStyle(color: Colors.white),
                    ),
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
    Function(LatLng?) onSelect, {
    bool isMain = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.map),
        label: Text(
          loc == null
              ? label
              : isMain
              ? "$label (เลือกแล้ว: ${addressName ?? "กำลังแปลงที่อยู่..."})"
              : "$label (เลือกแล้ว: ${altAddressName ?? "กำลังแปลงที่อยู่..."})",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: () async {
          LatLng? selected = await _pickLocationDialog(context, loc);
          if (selected != null) {
            // ✅ แปลงพิกัดเป็นชื่อที่อยู่
            List<Placemark> placemarks = await placemarkFromCoordinates(
              selected.latitude,
              selected.longitude,
            );

            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              String formatted = [
                p.name,
                p.subLocality,
                p.locality,
                p.administrativeArea,
                p.country,
              ].where((e) => e != null && e.isNotEmpty).join(", ");

              setState(() {
                onSelect(selected);
                if (isMain) {
                  addressName = formatted;
                } else {
                  altAddressName = formatted;
                }
              });
            }
          }
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
