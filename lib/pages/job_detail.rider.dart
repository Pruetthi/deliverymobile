import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:delivery/widgets/rider_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobDetailRiderPage extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> riderData;
  final String jobId;

  const JobDetailRiderPage({
    super.key,
    required this.jobData,
    required this.userData,
    required this.riderData,
    required this.jobId,
  });

  @override
  State<JobDetailRiderPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailRiderPage> {
  int _selectedIndex = 0;
  String _receiverAddress = "-";

  File? _photo;
  String? _displayImage; // แสดงรูปล่าสุด (url หรือ path)
  final cloudinary = CloudinaryPublic(
    'daqjnjmto', // Cloud name
    'unsigned_delivery', // upload preset
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    _loadAddress();
    _displayImage = widget.jobData['item_image'];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  int getStatus() {
    final s = widget.jobData['status'];
    if (s is int) return s;
    return int.tryParse(s.toString()) ?? 0;
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return "รอไรเดอร์มารับสินค้า";
      case 2:
        return "ไรเดอร์รับงาน (ถ่ายรูปสินค้าก่อนรับงาน)";
      case 3:
        return "ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง";
      case 4:
        return "ไรเดอร์นำส่งสินค้าแล้ว";
      default:
        return "ไม่ทราบสถานะ";
    }
  }

  Future<void> _loadAddress() async {
    try {
      final lat = widget.jobData['latitude'] as double?;
      final lng = widget.jobData['longitude'] as double?;
      if (lat != null && lng != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _receiverAddress =
                "${p.thoroughfare ?? ''} ${p.subLocality ?? ''} ${p.locality ?? ''} ${p.administrativeArea ?? ''}"
                    .trim();
          });
        }
      }
    } catch (e) {
      setState(() => _receiverAddress = "-");
    }
  }

  void _openMapPage() {
    final pickupLat = widget.jobData['pickup_latitude'] ?? 0.0;
    final pickupLng = widget.jobData['pickup_longitude'] ?? 0.0;
    final dropLat = widget.jobData['latitude'] ?? 0.0;
    final dropLng = widget.jobData['longitude'] ?? 0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('ตำแหน่งสินค้า'),
            backgroundColor: Colors.orange,
          ),
          body: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                (pickupLat + dropLat) / 2,
                (pickupLng + dropLng) / 2,
              ),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=88f9690d7c84430e8ebb75502e511790',
                userAgentPackageName: 'com.example.delivery_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(pickupLat, pickupLng),
                    width: 80,
                    height: 80,
                    child: Column(
                      children: const [
                        Icon(Icons.store, color: Colors.green, size: 40),
                        Text(
                          'ผู้ส่ง',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Marker(
                    point: LatLng(dropLat, dropLng),
                    width: 80,
                    height: 80,
                    child: Column(
                      children: const [
                        Icon(Icons.location_on, color: Colors.red, size: 40),
                        Text(
                          'ผู้รับ',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      LatLng(pickupLat, pickupLng),
                      LatLng(dropLat, dropLng),
                    ],
                    color: Colors.orangeAccent,
                    strokeWidth: 4,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _photo = File(pickedFile.path);
        _displayImage = _photo!.path;
      });
    }
  }

  Future<void> _uploadPickupPhoto() async {
    if (_photo == null) return;

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_photo!.path, folder: 'delivery_photos'),
      );

      final imageUrl = response.secureUrl;

      // เก็บรูป
      await FirebaseFirestore.instance.collection('images').add({
        'job_id': widget.jobId,
        'rider_id': widget.riderData['rid'],
        'image_type': 'pickup',
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // อัปเดต status
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update({'status': 3});

      setState(() {
        widget.jobData['status'] = 3;
        _displayImage = imageUrl;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปโหลดรูปสินค้าสำเร็จ ✅')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปโหลดล้มเหลว: $e')));
    }
  }

  Future<void> _confirmDelivery() async {
    if (_photo == null) return;

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_photo!.path, folder: 'delivery_photos'),
      );

      final imageUrl = response.secureUrl;

      await FirebaseFirestore.instance.collection('images').add({
        'job_id': widget.jobId,
        'rider_id': widget.riderData['rid'],
        'image_type': 'delivery',
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update({'status': 4});

      setState(() {
        widget.jobData['status'] = 4;
        _displayImage = imageUrl;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยืนยันการส่งสินค้า ✅')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปโหลดล้มเหลว: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final int status = getStatus();

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดงานส่งของ'),
        backgroundColor: const Color(0xFFFF6B35),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'รหัสสินค้า: ${widget.jobId}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'ชื่อสินค้า: ${widget.jobData['item_name']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'รายละเอียดสินค้า: ${widget.jobData['item_detail']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'ชื่อผู้ส่ง: ${widget.jobData['sender_name']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'ชื่อผู้รับ: ${widget.jobData['receiver_name']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'ที่อยู่ผู้รับ: $_receiverAddress',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: const Color(0xFFFFC857),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            status.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getStatusText(status),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _displayImage != null
                        ? _displayImage!.startsWith('http')
                              ? Image.network(
                                  _displayImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_displayImage!),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                        : const SizedBox.shrink(),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _openMapPage,
                      icon: const Icon(Icons.map),
                      label: const Text("ดูตำแหน่งสินค้า"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        status == 3
                            ? "ถ่ายรูปยืนยันการจัดส่ง"
                            : "ถ่ายรูปยืนยันสินค้า",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _photo == null
                          ? null
                          : () async {
                              if (status == 2) {
                                await _uploadPickupPhoto();
                              } else if (status == 3) {
                                await _confirmDelivery();
                              }
                            },
                      icon: const Icon(Icons.directions_bike),
                      label: Text(
                        status == 2
                            ? "อัปโหลดรูปรับสินค้าแล้ว"
                            : status == 3
                            ? "ยืนยันการส่ง"
                            : "เสร็จสิ้น",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RiderBottomBar(
        userData: widget.riderData,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
