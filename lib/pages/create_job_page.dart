import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // ✅ ใช้แปลงพิกัดเป็นชื่อที่อยู่

class CreateJobPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CreateJobPage({super.key, required this.userData});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final phoneController = TextEditingController();
  final itemNameController = TextEditingController();
  final itemDetailController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = false;

  Map<String, dynamic>? receiverData;
  String? selectedType;
  Map<String, dynamic>? selectedAddress;

  File? _pickedImage;
  String? uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic(
    'daqjnjmto',
    'unsigned_delivery',
    cache: false,
  );

  String? address1Text;
  String? address2Text;

  /// ✅ ดึงตำแหน่ง GPS ปัจจุบันของผู้ส่ง
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเปิด GPS ก่อนสร้างงาน')),
      );
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// ✅ แปลงพิกัดเป็นชื่อสถานที่ (เช่น ถนน / เขต / จังหวัด)
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.street ?? ''} ${place.subLocality ?? ''} ${place.locality ?? ''}"
            .trim();
      }
    } catch (e) {
      print("❌ Error reverse geocoding: $e");
    }
    return "ไม่พบที่อยู่";
  }

  /// ✅ โหลดชื่อที่อยู่จากพิกัดของผู้รับ
  Future<void> loadReceiverAddresses() async {
    if (receiverData != null) {
      final loc1 = receiverData!['location1'];
      final loc2 = receiverData!['location2'];

      if (loc1 != null) {
        address1Text = await getAddressFromLatLng(
          loc1['latitude'],
          loc1['longitude'],
        );
      }

      if (loc2 != null) {
        address2Text = await getAddressFromLatLng(
          loc2['latitude'],
          loc2['longitude'],
        );
      }

      setState(() {});
    }
  }

  /// ✅ เลือกรูปจากกล้อง
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  /// ✅ อัปโหลดรูปไป Cloudinary
  Future<void> uploadImage() async {
    if (_pickedImage == null) return;

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_pickedImage!.path, folder: "delivery_jobs"),
      );
      uploadedImageUrl = response.secureUrl;
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ เกิดข้อผิดพลาดในการอัปโหลด: $e')),
      );
    }
  }

  /// ✅ ค้นหาผู้รับ
  Future<void> searchReceiver() async {
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ กรุณากรอกเบอร์โทรผู้รับ')),
      );
      return;
    }

    setState(() {
      _loading = true;
      receiverData = null;
      selectedType = null;
      selectedAddress = null;
    });

    try {
      final query = await _firestore
          .collection('user')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ ไม่พบผู้ใช้หมายเลขนี้ในระบบ')),
        );
      } else {
        setState(() {
          receiverData = query.docs.first.data();
        });

        /// ✅ โหลดชื่อที่อยู่จาก lat/lng
        await loadReceiverAddresses();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }

    setState(() => _loading = false);
  }

  /// ✅ สร้างงานส่งสินค้า
  Future<void> createJob() async {
    if (receiverData == null || selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ กรุณาเลือกผู้รับและที่อยู่')),
      );
      return;
    }

    if (itemNameController.text.isEmpty || itemDetailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ กรุณากรอกข้อมูลสินค้าให้ครบ')),
      );
      return;
    }

    setState(() => _loading = true);

    Position? currentLocation = await getCurrentLocation();
    if (currentLocation == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      /// ✅ อัปโหลดรูปอัตโนมัติ (ถ้ายังไม่ได้อัปโหลด)
      if (_pickedImage != null && uploadedImageUrl == null) {
        await uploadImage();
      }

      await _firestore.collection('jobs').add({
        "receiver_phone": receiverData!['phone'],
        "receiver_name": receiverData!['name'],
        "receiver_uid": receiverData!['uid'],

        "sender_uid": widget.userData['uid'],
        "sender_name": widget.userData['name'],
        "sender_phone": widget.userData['phone'],

        "pickup_latitude": currentLocation.latitude,
        "pickup_longitude": currentLocation.longitude,

        "address_type": selectedType,
        "address_text": selectedAddress!['text'],
        "latitude": selectedAddress!['latitude'],
        "longitude": selectedAddress!['longitude'],

        "item_name": itemNameController.text,
        "item_detail": itemDetailController.text,
        "item_image": uploadedImageUrl ?? "",
        "status": 1,
        "created_at": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ สร้างงานเรียบร้อยแล้ว')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e')));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("สร้างงานส่งสินค้า"),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      backgroundColor: const Color(0xFFFFF8F0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "เบอร์โทรผู้รับ",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchReceiver,
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (receiverData != null) ...[
              Text(
                "ชื่อผู้รับ: ${receiverData!['name']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text("เลือกที่อยู่จัดส่ง:", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 5),

              RadioListTile<String>(
                title: Text("ที่อยู่หลัก (${address1Text ?? 'กำลังโหลด...'})"),
                value: 'main',
                groupValue: selectedType,
                onChanged: (value) {
                  final loc = receiverData!['location1'];
                  setState(() {
                    selectedType = value;
                    selectedAddress = {
                      'text': address1Text ?? '',
                      'latitude': loc['latitude'],
                      'longitude': loc['longitude'],
                    };
                  });
                },
              ),
              RadioListTile<String>(
                title: Text("ที่อยู่สำรอง (${address2Text ?? 'กำลังโหลด...'})"),
                value: 'alt',
                groupValue: selectedType,
                onChanged: (value) {
                  final loc = receiverData!['location2'];
                  setState(() {
                    selectedType = value;
                    selectedAddress = {
                      'text': address2Text ?? '',
                      'latitude': loc['latitude'],
                      'longitude': loc['longitude'],
                    };
                  });
                },
              ),
              const Divider(),
            ],

            TextField(
              controller: itemNameController,
              decoration: const InputDecoration(labelText: "ชื่อสินค้า"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: itemDetailController,
              decoration: const InputDecoration(labelText: "รายละเอียดสินค้า"),
            ),
            const SizedBox(height: 20),

            Column(
              children: [
                if (_pickedImage != null)
                  Image.file(_pickedImage!, height: 150),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("ถ่ายรูปสินค้า"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: createJob,
              icon: const Icon(Icons.check),
              label: const Text("สร้างงานส่งสินค้า"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
