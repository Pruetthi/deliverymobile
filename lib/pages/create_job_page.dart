import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

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

  // สำหรับรูป
  File? _pickedImage;
  String? uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic(
    'daqjnjmto', // ชื่อ cloud name
    'unsigned_delivery', // ชื่อ upload preset
    cache: false,
  );

  /// เลือกรูปจากกล้อง
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

  /// อัปโหลดรูปไป Cloudinary
  Future<void> uploadImage() async {
    if (_pickedImage == null) return;

    setState(() => _loading = true);
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_pickedImage!.path, folder: "delivery_jobs"),
      );

      setState(() {
        uploadedImageUrl = response.secureUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ อัปโหลดรูปเรียบร้อยแล้ว')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ เกิดข้อผิดพลาดในการอัปโหลด: $e')),
      );
    }
    setState(() => _loading = false);
  }

  /// ค้นหาผู้รับ
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
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }

    setState(() => _loading = false);
  }

  /// สร้างงานส่งสินค้า
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

    try {
      // อัปโหลดรูปถ้ายังไม่ได้อัปโหลด
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
            // เบอร์ผู้รับ
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

            // Loader หรือข้อมูลผู้รับ
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

              // ที่อยู่หลัก
              RadioListTile<String>(
                title: Text("ที่อยู่หลัก (${receiverData!['location1']})"),
                value: 'main',
                groupValue: selectedType,
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                    selectedAddress = {
                      'text': receiverData!['address'],
                      'latitude': receiverData!['location1']['latitude'],
                      'longitude': receiverData!['location1']['longitude'],
                    };
                  });
                },
              ),

              // ที่อยู่สำรอง
              RadioListTile<String>(
                title: Text("ที่อยู่รอง (${receiverData!['location2']})"),
                value: 'alt',
                groupValue: selectedType,
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                    selectedAddress = {
                      'text': receiverData!['alt_address'],
                      'latitude': receiverData!['location2']['latitude'],
                      'longitude': receiverData!['location2']['longitude'],
                    };
                  });
                },
              ),
              const Divider(),
            ],

            // ชื่อสินค้า
            TextField(
              controller: itemNameController,
              decoration: const InputDecoration(labelText: "ชื่อสินค้า"),
            ),
            const SizedBox(height: 10),

            // รายละเอียดสินค้า
            TextField(
              controller: itemDetailController,
              decoration: const InputDecoration(labelText: "รายละเอียดสินค้า"),
            ),
            const SizedBox(height: 20),

            // เลือกรูปสินค้า
            Column(
              children: [
                if (_pickedImage != null)
                  Image.file(_pickedImage!, height: 150),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("ถ่ายรูปสินค้า"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_pickedImage != null)
                      ElevatedButton.icon(
                        onPressed: uploadImage,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text("อัปโหลดรูป"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // สร้างงานส่งสินค้า
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
