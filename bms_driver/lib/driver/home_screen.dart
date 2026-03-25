import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';

class BusLocation {
  final double lat;
  final double lng;
  final int timestamp;
  final String status;

  BusLocation({
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'ts': timestamp,
        'status': status,
      };
}

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  static const String _realtimeDbUrl =
      'https://bus-management-a7917-default-rtdb.asia-southeast1.firebasedatabase.app';

  bool isTripActive = false;
  final MapController _mapController = MapController();
  late final FirebaseDatabase _realtimeDb = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: _realtimeDbUrl,
  );
  String _busNumber = 'Unknown';
  int _totalCapacity = 0;
  int? _busId;

  // Saintgits College of Engineering (Approximate)
  final LatLng _stopLocation = const LatLng(9.5042, 76.5521);

  LatLng? _currentPosition;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchBusDetails();
  }

  Future<void> _fetchBusDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final busId = prefs.getInt('bus_id');
      final busNum = prefs.getString('bus_number');
      
      if (mounted) {
        setState(() {
           _busNumber = busNum ?? 'Unknown';
           _busId = busId;
        });
      }

      if (busId == null) return;

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('buses')
          .select('total_capacity')
          .eq('id', busId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _totalCapacity = response['total_capacity'] as int? ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bus details: $e');
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendLocationFromPosition(
    Position position, {
    required String status,
    bool showSnackBar = true,
  }) async {
    debugPrint(
      'Sending location: ${position.latitude}, ${position.longitude} status=$status',
    );
    final busLocation = BusLocation(
      lat: position.latitude,
      lng: position.longitude,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: status,
    );

    if (_busId == null) {
      debugPrint('No bus ID available to send location');
      return;
    }

    final ref = _realtimeDb.ref('buses/$_busId/location');
    await ref.set(busLocation.toJson());
    debugPrint('Firebase write success: buses/$_busId/location');

    if (mounted && showSnackBar && status != 'active') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip $status, location sent')),
      );
    }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: () {
              Geolocator.openAppSettings();
            },
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
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _sendLocationOnce({String status = 'running'}) async {
    // Always get fresh location before sending
    try {
      debugPrint('Fetching current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      debugPrint('Position fetched: ${position.latitude}, ${position.longitude}');

      // Update the current position
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }

      await _sendLocationFromPosition(
        position,
        status: status,
      );
    } catch (e) {
      debugPrint('Error sending location to Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send location')),
        );
      }
    }
  }

  void _startLiveLocation() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!isTripActive) {
        return;
      }
      debugPrint('Timer tick: sending active location');
      _sendLocationOnce(status: 'active');
    });
    debugPrint('Live location started');
    _sendLocationOnce(status: 'active');
  }

  void _stopLiveLocation() {
    _locationTimer?.cancel();
    _locationTimer = null;
    debugPrint('Live location stopped');
    _sendLocationOnce(status: 'inactive');
  }

  void _fitBounds() {
    final List<LatLng> points = <LatLng>[_stopLocation];
    if (_currentPosition != null) {
      points.add(_currentPosition!);
    }

    if (points.length > 1) {
      try {
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(80),
          ),
        );
      } catch (e) {
        // Sometimes map controller isn't ready
        debugPrint('Map controller error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme Colors
    final Color bgColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F6F8);
    final Color textPrim =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final Color textSec =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    Icons.settings,
                    isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DriverSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  Column(
                    children: [
                      Text(
                        'ROUTE $_busNumber',
                        style: TextStyle(
                          color: textSec,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Driver Dashboard',
                        style: TextStyle(
                          color: textPrim,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 40), // Placeholder to balance
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // System Ready Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPulsingDot(),
                          const SizedBox(width: 8),
                          const Text(
                            'System Ready',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Ready to Start?',
                      style: TextStyle(
                        color: textPrim,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    

                    const SizedBox(height: 32),

                    // Map Card
                    _buildMapCard(isDark, primaryColor, textPrim, textSec),

                    const SizedBox(height: 32),

                    // Start Trip Button
                    SizedBox(
                      width: 280,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isTripActive = !isTripActive;
                          });
                          if (isTripActive) {
                            _startLiveLocation();
                          } else {
                            _stopLiveLocation();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTripActive ? Colors.red : primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: (isTripActive ? Colors.red : primaryColor)
                              .withOpacity(0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_bus, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              isTripActive ? 'STOP TRIP' : 'START TRIP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Stats Grid - Total Capacity
                    SizedBox(
                      width: double.infinity,
                      child: _buildStatCard(
                        isDark,
                        cardColor,
                        Icons.airline_seat_recline_extra,
                        'TOTAL CAPACITY',
                        _totalCapacity.toString(),
                        Colors.blue, // Using a distinct color like blue for capacity
                        textPrim,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildPulsingDot() {
    return SizedBox(
      width: 8,
      height: 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(bool isDark, Color primary, Color textPrim, Color textSec) {
    return Container(
      width: double.infinity,
      height: 340,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[300],
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Flutter Map Implementation
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _stopLocation,
              initialZoom: 13.0,
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
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.school, size: 20, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Current Driver/Bus Marker
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: const Column(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFF137FEC),
                            child: Icon(Icons.directions_bus, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Map Control Buttons
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                _buildMapBtn(Icons.my_location, primary, isDark, _fitBounds),
                const SizedBox(height: 8),
                _buildMapBtn(
                  Icons.layers,
                  isDark ? Colors.white : Colors.black87,
                  isDark,
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBtn(IconData icon, Color color, bool isDark, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildStatCard(
    bool isDark,
    Color cardColor,
    IconData icon,
    String label,
    String value,
    Color iconColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : (Colors.grey[200] ?? Colors.grey),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                  fontSize: 12, // Increased slightly
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 32, // Larger for emphasis
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
        ],
      ),
    );
  }
}
