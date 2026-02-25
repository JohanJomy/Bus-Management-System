import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();

  // Saintgits College of Engineering (Approximate)
  final LatLng _stopLocation = const LatLng(9.5042, 76.5521);

  // Live bus location fetched from Realtime Database
  LatLng? _busLocation;

  // Polling timer for fetching bus location
  Timer? _busLocationTimer;

  bool _isBusActive = false;

  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _startBusLocationPolling();
  }

  @override
  void dispose() {
    _busLocationTimer?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled.'),
        ));
      }
      if (mounted) setState(() {});
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions are denied'),
          ));
        }
        if (mounted) setState(() {});
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ));
      }
      if (mounted) setState(() {});
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Once we have the location, fit bounds to show all markers
      _fitBounds();
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) setState(() {});
    }
  }

  void _fitBounds() {
    List<LatLng> points = [_stopLocation];
    if (_busLocation != null) {
      points.add(_busLocation!);
    }
    if (_currentPosition != null) {
      points.add(_currentPosition!);
    }

    // Fit bounds
    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (e) {
      // Sometimes map controller isn't ready
      debugPrint("Map controller error: $e");
    }
  }

  void _startBusLocationPolling() {
    _busLocationTimer?.cancel();

    final DatabaseReference ref =
        FirebaseDatabase.instance.ref('buses/13/location');

    _busLocationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final DataSnapshot snapshot = await ref.get();
        if (!snapshot.exists) return;

        final value = snapshot.value;
        if (value is! Map) return;

        final Map data = value;
        final String status = (data['status'] ?? '').toString();

        // Only update marker when the trip is active
        if (status != 'active') {
          if (!mounted) return;
          setState(() {
            _isBusActive = false;
          });
          return;
        }

        final latRaw = data['lat'];
        final lngRaw = data['lng'];
        if (latRaw is num && lngRaw is num) {
          final LatLng newLocation = LatLng(latRaw.toDouble(), lngRaw.toDouble());

          if (!mounted) return;
          setState(() {
            _busLocation = newLocation;
            _isBusActive = true;
          });
        }
      } catch (e) {
        debugPrint('Error fetching bus location: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Flutter Map Implementation
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _stopLocation,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
                scrollWheelVelocity: 0.01,
              ),
              onMapReady: () {
                if (_currentPosition != null) {
                  _fitBounds();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.jjns',
              ),
              MarkerLayer(
                markers: [
                  // Bus Marker
                  if (_busLocation != null && _isBusActive)
                    Marker(
                      point: _busLocation!,
                      width: 60,
                      height: 60,
                      child: const Column(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFF137FEC),
                            child: Icon(Icons.directions_bus, color: Colors.white, size: 20),
                          ),
                          SizedBox(height: 2),
                          Text("Bus", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                  // Stop Marker (Saintgits)
                  Marker(
                    point: _stopLocation,
                    width: 80,
                    height: 80,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.school, size: 20, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Saintgits",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Current User Marker
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)],
                            ),
                            child: const Icon(Icons.person, size: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          const Text("You", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Dark Overlay removed to ensure gestures work
          const SizedBox.shrink(),

          // Top Info Card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: _isBusActive ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isBusActive
                                    ? 'Live • Bus active'
                                    : 'Offline • Trip not active',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Floating Action Buttons (Zoom & Center)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            final currentZoom = _mapController.camera.zoom;
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom + 1,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                            ),
                            child: const Icon(Icons.add, size: 20, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            final currentZoom = _mapController.camera.zoom;
                            _mapController.move(
                              _mapController.camera.center,
                              currentZoom - 1,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                            ),
                            child: const Icon(Icons.remove, size: 20, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            if (_currentPosition == null) {
                              _determinePosition();
                            } else {
                              _fitBounds();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
                            ),
                            child: Icon(
                              _currentPosition == null
                                  ? Icons.location_disabled
                                  : Icons.my_location,
                              size: 20,
                              color: _currentPosition == null ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Info Card
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF137FEC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_bus_filled,
                          color: Color(0xFF137FEC),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "College Bus #13",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              "Route: Kottayam - Saintgits",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Next Stop",
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                          Text(
                            "Saintgits",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
