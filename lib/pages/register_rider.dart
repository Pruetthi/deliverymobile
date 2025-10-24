import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'login.dart';

class RegisterRiderPage extends StatefulWidget {
  const RegisterRiderPage({super.key});

  @override
  State<RegisterRiderPage> createState() => _RegisterRiderPageState();
}

class _RegisterRiderPageState extends State<RegisterRiderPage> {
  final phoneCtl = TextEditingController();
  final nameCtl = TextEditingController();
  final passwordCtl = TextEditingController();
  final vehicleNumberCtl = TextEditingController();

  File? profileImage;
  File? vehicleImage;

  String? profileImageUrl;
  String? vehicleImageUrl;

  final db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // ✅ ใช้ CloudinaryPublic ตามที่คุณให้
  final cloudinary = CloudinaryPublic(
    'daqjnjmto', // Cloud name
    'unsigned_delivery', // Upload preset
    cache: false,
  );

  bool _loading = false;

  // ------------------------
  // เลือกรูป
  // ------------------------
  Future<void> pickImage(bool isProfile) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          profileImage = File(pickedFile.path);
        } else {
          vehicleImage = File(pickedFile.path);
        }
      });
    }
  }

  // ------------------------
  // อัปโหลดรูปไป Cloudinary
  // ------------------------
  Future<String?> uploadFile(File file) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, folder: "riders"),
      );
      return response.secureUrl;
    } catch (e) {
      Get.snackbar(
        "Error",
        "อัปโหลดรูปไม่สำเร็จ: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // ------------------------
  // สมัครสมาชิก
  // ------------------------
  void addData() async {
    if (nameCtl.text.isEmpty ||
        phoneCtl.text.isEmpty ||
        passwordCtl.text.isEmpty ||
        vehicleNumberCtl.text.isEmpty ||
        profileImage == null ||
        vehicleImage == null) {
      Get.snackbar(
        "Error",
        "กรุณากรอกข้อมูลและเลือกรูปให้ครบ",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _loading = true);

    // ✅ อัปโหลดรูปไป Cloudinary
    profileImageUrl = await uploadFile(profileImage!);
    vehicleImageUrl = await uploadFile(vehicleImage!);

    if (profileImageUrl == null || vehicleImageUrl == null) {
      setState(() => _loading = false);
      return;
    }

    // ✅ ตรวจว่าเคยเป็น Rider แล้วหรือยัง
    var existingRider = await db
        .collection('rider')
        .where('phone', isEqualTo: phoneCtl.text)
        .limit(1)
        .get();

    if (existingRider.docs.isNotEmpty) {
      Get.snackbar(
        "Error",
        "เบอร์นี้เคยสมัครเป็น Rider แล้ว",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() => _loading = false);
      return;
    }

    // ✅ ตรวจว่าเบอร์นี้มีอยู่ใน User ไหม
    var existingUser = await db
        .collection('user')
        .where('phone', isEqualTo: phoneCtl.text)
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      var userPassword = existingUser.docs.first['password'];
      if (userPassword == passwordCtl.text) {
        Get.snackbar(
          "Error",
          "ห้ามใช้รหัสผ่านเดียวกับบัญชีผู้ใช้ (User)",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() => _loading = false);
        return;
      }
    }

    // ✅ บันทึกข้อมูล Rider
    var docRef = db.collection('rider').doc();
    await docRef.set({
      'rid': docRef.id,
      'name': nameCtl.text,
      'phone': phoneCtl.text,
      'password': passwordCtl.text,
      'vehicle_number': vehicleNumberCtl.text,
      'profile_picture': profileImageUrl,
      'vehicle_picture': vehicleImageUrl,
      'status': 'rider',
      'createdAt': DateTime.now(),
    });

    setState(() => _loading = false);

    Get.snackbar(
      "สำเร็จ",
      "สมัครเป็น Rider เรียบร้อยแล้ว",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    Get.off(() => const LoginPage());
  }

  // ------------------------
  // UI
  // ------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              "Register as Rider",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),
            // รูปโปรไฟล์
            GestureDetector(
              onTap: () => pickImage(true),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImage != null
                    ? FileImage(profileImage!)
                    : null,
                child: profileImage == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text("แตะเพื่อเลือกรูปโปรไฟล์"),

            const SizedBox(height: 20),
            // รูปรถ
            GestureDetector(
              onTap: () => pickImage(false),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                  image: vehicleImage != null
                      ? DecorationImage(
                          image: FileImage(vehicleImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: vehicleImage == null
                    ? const Icon(Icons.directions_bike, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text("แตะเพื่อเลือกรูปรถ"),

            const SizedBox(height: 20),
            _buildTextField("Name", nameCtl),
            _buildTextField("Phone", phoneCtl, type: TextInputType.phone),
            _buildTextField("Password", passwordCtl, obscure: true),
            _buildTextField("Vehicle Registration", vehicleNumberCtl),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : addData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctl, {
    bool obscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: ctl,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneCtl.dispose();
    nameCtl.dispose();
    passwordCtl.dispose();
    vehicleNumberCtl.dispose();
    super.dispose();
  }
}
