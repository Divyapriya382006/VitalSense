import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../theme/app_theme.dart';

class NearbyHospitalsScreen extends ConsumerStatefulWidget {
  const NearbyHospitalsScreen({super.key});
  @override
  ConsumerState<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends ConsumerState<NearbyHospitalsScreen> {
  Position? _position;
  List<Map<String, dynamic>> _hospitals = [];
  bool _loading = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // TODO: Replace with your actual server IP before demo
  static const String _backendBase = 'http://192.168.1.100:8000';

  // Demo hospitals shown when backend not available
  final List<Map<String, dynamic>> _demoHospitals = [
    {'name': 'VIT Health Centre', 'address': 'VIT Campus, Vellore', 'lat': 12.9698, 'lng': 79.1559, 'rating': 4.2, 'open_now': true, 'place_id': 'demo1'},
    {'name': 'Christian Medical College', 'address': 'Ida Scudder Rd, Vellore', 'lat': 12.9249, 'lng': 79.1357, 'rating': 4.8, 'open_now': true, 'place_id': 'demo2'},
    {'name': 'Government Vellore Medical College', 'address': 'Adukamparai, Vellore', 'lat': 12.9282, 'lng': 79.1336, 'rating': 3.9, 'open_now': true, 'place_id': 'demo3'},
    {'name': 'Aravind Eye Hospital', 'address': 'Cuddalore Road, Vellore', 'lat': 12.9165, 'lng': 79.1325, 'rating': 4.6, 'open_now': true, 'place_id': 'demo4'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    setState(() => _loading = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _loadDemoData();
        return;
      }

      _position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      try {
        final dio = Dio();
        final response = await dio.get(
          '$_backendBase/hospitals/nearby',
          queryParameters: {'lat': _position!.latitude, 'lng': _position!.longitude, 'radius': 5000},
        ).timeout(const Duration(seconds: 5));

        final hospitals = List<Map<String, dynamic>>.from(response.data['hospitals']);
        _setHospitals(hospitals);
      } catch (_) {
        // Backend not running — show demo hospitals
        _loadDemoData();
      }
    } catch (e) {
      _loadDemoData();
    }
  }

  void _loadDemoData() {
    _setHospitals(_demoHospitals);
  }

  void _setHospitals(List<Map<String, dynamic>> hospitals) {
    final markers = hospitals.map((h) => Marker(
      markerId: MarkerId(h['place_id'] ?? h['name']),
      position: LatLng((h['lat'] as num).toDouble(), (h['lng'] as num).toDouble()),
      infoWindow: InfoWindow(title: h['name'], snippet: h['address']),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    )).toSet();

    if (_position != null) {
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(_position!.latitude, _position!.longitude),
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    setState(() {
      _hospitals = hospitals;
      _markers = markers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultLocation = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : const LatLng(12.9698, 79.1559); // VIT Vellore default

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Hospitals'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadHospitals),
        ],
      ),
      body: _loading
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Finding nearby hospitals...'),
              ],
            ))
          : Column(
              children: [
                // Map
                SizedBox(
                  height: 280,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: defaultLocation, zoom: 13),
                    markers: _markers,
                    onMapCreated: (c) => _mapController = c,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),

                // Hospital list
                Expanded(
                  child: _hospitals.isEmpty
                      ? const Center(child: Text('No hospitals found nearby'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _hospitals.length,
                          itemBuilder: (_, i) {
                            final h = _hospitals[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: VitalSenseTheme.alertRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.local_hospital_rounded, color: VitalSenseTheme.alertRed, size: 20),
                                ),
                                title: Text(h['name'] ?? 'Hospital',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                subtitle: Text(h['address'] ?? '', style: const TextStyle(fontSize: 12)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (h['rating'] != null)
                                      Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        Text('${h['rating']}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      ]),
                                    if (h['open_now'] != null)
                                      Text(
                                        h['open_now'] ? 'Open' : 'Closed',
                                        style: TextStyle(
                                          color: h['open_now'] ? VitalSenseTheme.primaryGreen : Colors.grey,
                                          fontSize: 11, fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                        LatLng((h['lat'] as num).toDouble(), (h['lng'] as num).toDouble()), 16),
                                  );
                                },
                              ),
                            ).animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.1);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
