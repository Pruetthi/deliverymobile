import 'package:delivery/pages/job_tracking_page.dart';
import 'package:delivery/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobDetailPage extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final Map<String, dynamic> userData;
  const JobDetailPage({
    super.key,
    required this.jobData,
    required this.userData,
  });

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  int _selectedIndex = 0;
  String _receiverAddress = "-";
  String _senderAddress = "-";

  @override
  void initState() {
    super.initState();
    _loadAddress();
    _loadSenderAddress();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return "รอไรเดอร์มารับสินค้า";
      case 2:
        return "ไรเดอร์รับงาน (กำลังเดินทางมารับสินค้า)";
      case 3:
        return "ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง";
      case 4:
        return "ไรเดอร์นำส่งสินค้าแล้ว";
      default:
        return "ไม่ทราบสถานะ";
    }
  }

  Future<void> _loadSenderAddress() async {
    try {
      final lat = widget.jobData['pickup_latitude'] as double?;
      final lng = widget.jobData['pickup_longitude'] as double?;
      if (lat != null && lng != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _senderAddress =
                "${p.street ?? ''} ${p.thoroughfare ?? ''} ${p.subLocality ?? ''} ${p.locality ?? ''} ${p.administrativeArea ?? ''}"
                    .trim();
          });
        }
      }
    } catch (e) {
      setState(() => _senderAddress = "-");
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
                "${p.street ?? ''} ${p.thoroughfare ?? ''} ${p.subLocality ?? ''} ${p.locality ?? ''} ${p.administrativeArea ?? ''}"
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
                  // Marker ผู้ส่ง (สีเขียว)
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
                  // Marker ผู้รับ (สีแดง)
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

  Widget _buildItemImage() {
    final int status = widget.jobData['status'] ?? 0;

    // ถ้า status < 3 ใช้ item_image เดิม
    if (status < 3) {
      return Image.network(
        widget.jobData['item_image'] ?? '',
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.image)),
        ),
      );
    }

    // status >= 3 ใช้รูป pickup ล่าสุดจาก images
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('images')
          .where('job_id', isEqualTo: widget.jobData['id'])
          .where('image_type', isEqualTo: 'pickup')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // ถ้าไม่มีรูปใหม่ ให้ใช้ item_image เดิม
          return Image.network(
            widget.jobData['item_image'] ?? '',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.image)),
            ),
          );
        }

        // ถ้าเจอรูปใหม่
        final doc = snapshot.data!.docs.first;
        final imageUrl = doc.get('image_url') as String?;
        final timestamp = doc.get('timestamp') as Timestamp?;

        // ใช้ ValueKey + timestamp เพื่อบังคับ Flutter rebuild รูปเมื่อเปลี่ยน
        return Image.network(
          imageUrl ?? widget.jobData['item_image'] ?? '',
          key: ValueKey("${imageUrl}_${timestamp?.millisecondsSinceEpoch}"),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final int status = widget.jobData['status'] ?? 0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: const Color(0xFFFFC857),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รหัสสินค้า: ${widget.jobData['id']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.inventory_2,
                        'ชื่อสินค้า: ${widget.jobData['item_name']}',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.description,
                        'รายละเอียดสินค้า: ${widget.jobData['item_detail']}',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.person,
                        'ชื่อผู้ส่ง: ${widget.jobData['sender_name']}',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.phone,
                        'เบอร์ผู้ส่ง: ${widget.jobData['sender_phone']}',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.home,
                        'ที่อยู่ผู้ส่ง: $_senderAddress',
                      ),

                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.person_outline,
                        'ชื่อผู้รับ: ${widget.jobData['receiver_name']}',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.phone,
                        'เบอร์ผู้รับ: ${widget.jobData['receiver_phone']}',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.home,
                        'ที่อยู่ผู้รับ: $_receiverAddress',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.photo_camera_front_outlined,
                        'ชื่อไรเดอร์: ${widget.jobData['rider_name']}',
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.phone_outlined,
                        'เบอร์ไรเดอร์: ${widget.jobData['rider_phone']}',
                      ),
                      const SizedBox(height: 10),
                      Divider(color: Colors.white, thickness: 1, height: 20),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
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
                      ),

                      // รูปสินค้า / รูปล่าสุด Rider ถ่าย
                      _buildItemImage(),

                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobTrackingPage(
                                jobId: widget
                                    .jobData['id'], // <-- ส่ง jobId ที่นี่
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map),
                        label: const Text("ดูตำแหน่งสินค้า"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          minimumSize: const Size(double.infinity, 50),
                          foregroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
