import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AllMapSenderPage extends StatefulWidget {
  final String senderId; // uid ผู้ส่ง
  const AllMapSenderPage({Key? key, required this.senderId}) : super(key: key);

  @override
  State<AllMapSenderPage> createState() => _AllMapSenderPageState();
}

class _AllMapSenderPageState extends State<AllMapSenderPage> {
  final Map<String, Color> jobColors = {}; // เก็บสีของแต่ละงาน
  final Random random = Random();

  StreamSubscription<Position>? _positionStream;
  Map<String, Map<String, double>> riderPositions = {}; // jobId -> {lat, lng}

  @override
  void initState() {
    super.initState();
    _startUpdatingRiderPositions();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startUpdatingRiderPositions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      print("❌ ไม่มีสิทธิ์เข้าถึงตำแหน่ง");
      return;
    }

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen((position) {
          setState(() {
            riderPositions['my'] = {
              'lat': position.latitude,
              'lng': position.longitude,
            };
          });
        });
  }

  Future<List<LatLng>> getRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    const accessToken =
        'pk.eyJ1IjoiYXBpY2hhdDE4ODciLCJhIjoiY21oNXJzMzJ3MGF3YzJrb2F2ZGhrM3U4OCJ9.44XsFfpMgJkOhaxRiVVOlA'; // 🔹 ใส่ token ของคุณตรงนี้

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/'
      '$startLng,$startLat;$endLng,$endLat'
      '?geometries=geojson&access_token=$accessToken',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      return coords.map((c) => LatLng(c[1], c[0])).toList();
    } else {
      throw Exception('ไม่สามารถดึงเส้นทางจาก Mapbox ได้');
    }
  }

  Color getJobColor(String jobId) {
    if (!jobColors.containsKey(jobId)) {
      jobColors[jobId] = Color.fromARGB(
        255,
        random.nextInt(156) + 100,
        random.nextInt(156) + 100,
        random.nextInt(156) + 100,
      );
    }
    return jobColors[jobId]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตำแหน่งงานทั้งหมดของฉัน'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .where('sender_uid', isEqualTo: widget.senderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final jobs = snapshot.data!.docs;
          if (jobs.isEmpty) return const Center(child: Text('ยังไม่มีงานส่ง'));

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(
              jobs.map((doc) async {
                final data = doc.data() as Map<String, dynamic>;
                final pickupLat = (data['pickup_latitude'] ?? 0).toDouble();
                final pickupLng = (data['pickup_longitude'] ?? 0).toDouble();
                final dropLat = (data['latitude'] ?? 0).toDouble();
                final dropLng = (data['longitude'] ?? 0).toDouble();
                final riderLat = (data['rider_lat'] ?? 0).toDouble();
                final riderLng = (data['rider_lng'] ?? 0).toDouble();

                final routePoints = await getRoute(
                  pickupLat,
                  pickupLng,
                  dropLat,
                  dropLng,
                );

                return {
                  'jobId': doc.id,
                  'item_name': data['item_name'] ?? 'งานไม่ระบุ',
                  'pickupLat': pickupLat,
                  'pickupLng': pickupLng,
                  'dropLat': dropLat,
                  'dropLng': dropLng,
                  'riderLat': riderLat,
                  'riderLng': riderLng,
                  'routePoints': routePoints,
                };
              }).toList(),
            ),
            builder: (context, routeSnapshot) {
              if (!routeSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              final allJobs = routeSnapshot.data!;
              final centerLat =
                  allJobs
                      .map((j) => j['pickupLat'] as double)
                      .reduce((a, b) => a + b) /
                  allJobs.length;
              final centerLng =
                  allJobs
                      .map((j) => j['pickupLng'] as double)
                      .reduce((a, b) => a + b) /
                  allJobs.length;

              return SizedBox.expand(
                // ให้ FlutterMap มีขนาดเต็มหน้าจอ
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(centerLat, centerLng),
                    initialZoom: 12,
                    minZoom: 3,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=88f9690d7c84430e8ebb75502e511790',
                      userAgentPackageName: 'com.example.delivery_app',
                    ),
                    MarkerLayer(
                      markers: [
                        for (var job in allJobs) ...[
                          Marker(
                            point: LatLng(job['pickupLat'], job['pickupLng']),
                            width: 50,
                            height: 50,
                            child: Icon(
                              Icons.store,
                              color: getJobColor(job['jobId']),
                              size: 30,
                            ),
                          ),
                          Marker(
                            point: LatLng(job['dropLat'], job['dropLng']),
                            width: 50,
                            height: 50,
                            child: Icon(
                              Icons.location_on,
                              color: getJobColor(job['jobId']),
                              size: 30,
                            ),
                          ),
                          if ((job['riderLat'] ?? 0) != 0 &&
                              (job['riderLng'] ?? 0) != 0)
                            Marker(
                              point: LatLng(job['riderLat'], job['riderLng']),
                              width: 50,
                              height: 50,
                              child: Icon(
                                Icons.directions_bike,
                                color: getJobColor(job['jobId']),
                                size: 30,
                              ),
                            ),
                        ],
                        if (riderPositions.containsKey('my'))
                          Marker(
                            point: LatLng(
                              riderPositions['my']!['lat']!,
                              riderPositions['my']!['lng']!,
                            ),
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        for (var job in allJobs)
                          Polyline(
                            points: job['routePoints'] as List<LatLng>,
                            color: getJobColor(job['jobId']),
                            strokeWidth: 4,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
