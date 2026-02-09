import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  
  // Saintgits College of Engineering (Approximate)
  final LatLng _stopLocation = const LatLng(9.5042, 76.5521); 
  
  // Simulated Bus location (nearby)
  final LatLng _busLocation = const LatLng(9.5150, 76.5600);

  LatLng? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
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
      setState(() => _isLoadingLocation = false);
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
        setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.'),
        ));
      }
      setState(() => _isLoadingLocation = false);
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      
      // Once we have the location, fit bounds to show all markers
      _fitBounds();
    } catch (e) {
      debugPrint("Error getting location: $e");
      setState(() => _isLoadingLocation = false);
    }
  }

  void _fitBounds() {
    List<LatLng> points = [_busLocation, _stopLocation];
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Flutter Map Implementation
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _stopLocation, // Initial fallback center
              initialZoom: 13.0, // Zoomed out a bit more to see context
              minZoom: 5.0, // Allow zooming out
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
                scrollWheelVelocity: 0.01,
              ),
              onMapReady: () {
                 if (_currentPosition != null) {
                   _fitBounds();
                 }
              }
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bus_app',
              ),
              MarkerLayer(
                markers: [
                  // Bus Marker
                  Marker(
                    point: _busLocation,
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
                          child: const Text("Saintgits", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
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
                    const SizedBox(width: 40), // Spacer for balance
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: Colors.green),
                              SizedBox(width: 6),
                              Text(
                                "Live • Arriving in 15 mins",
                                style: TextStyle(
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
                             _mapController.move(_mapController.camera.center, currentZoom + 1);
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
                             _mapController.move(_mapController.camera.center, currentZoom - 1);
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
                              _currentPosition == null ? Icons.location_disabled : Icons.my_location, 
                              size: 20, 
                              color: _currentPosition == null ? Colors.grey : Colors.black87
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
                        child: const Icon(Icons.directions_bus_filled, color: Color(0xFF137FEC)),
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
