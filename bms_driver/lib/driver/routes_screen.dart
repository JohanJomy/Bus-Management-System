import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class DriverRoutesScreen extends StatefulWidget {
  const DriverRoutesScreen({super.key});

  @override
  State<DriverRoutesScreen> createState() => _DriverRoutesScreenState();
}

class _DriverRoutesScreenState extends State<DriverRoutesScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _stops = [];
  bool _isLoading = true;
  int? _activeStopId; // ID of the currently active stop
  Timer? _statusTimer;
  String _busNumber = 'Unknown';

  // We keep track of location separately just for distance checking
  @override
  void initState() {
    super.initState();
    _fetchStops();
    // Check location periodically every 5 seconds
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _checkLocation();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStops() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final busId = prefs.getInt('bus_id');
      final busNum = prefs.getString('bus_number');
      
      if (mounted && busNum != null) {
        setState(() {
          _busNumber = busNum;
        });
      }

      if (busId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch stops for this bus
      // Note: We sort manually in Dart to handle missing times with spatial logic
      final response = await supabase
          .from('stops')
          .select()
          .eq('actual_bus', busId);

      _sortStopsBySequence(response as List<dynamic>);

      if (mounted) {
        setState(() {
          _stops = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
        // Initial check
        _checkLocation();
      }
    } catch (e) {
      debugPrint('Error fetching stops: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Sort logic: Prioritize time, fallback to distance from College destination
  void _sortStopsBySequence(List<dynamic> stops) {
    // Saintgits College Destination
    const double destLat = 9.5042;
    const double destLng = 76.5521;

    stops.sort((a, b) {
      final String? t1 = a['arrival_time'];
      final String? t2 = b['arrival_time'];

      // 1. If both have valid time, use time order
      if (t1 != null && t1.isNotEmpty && t2 != null && t2.isNotEmpty) {
        return t1.compareTo(t2);
      }

      // 2. If time is missing, use spatial proximity to destination
      // Assuming stops are generally "further away" -> "closer" 
      // i.e. Descending distance order
      final double? lat1 = (a['lat'] as num?)?.toDouble();
      final double? lng1 = (a['long'] as num?)?.toDouble();
      final double? lat2 = (b['lat'] as num?)?.toDouble();
      final double? lng2 = (b['long'] as num?)?.toDouble();

      if (lat1 == null || lng1 == null) return 1; // Push invalid to end
      if (lat2 == null || lng2 == null) return -1;

      final double d1 = Geolocator.distanceBetween(lat1, lng1, destLat, destLng);
      final double d2 = Geolocator.distanceBetween(lat2, lng2, destLat, destLng);

      // Sort Descending (Start far away -> End at college)
      return d2.compareTo(d1);
    });
  }

  Future<void> _checkLocation() async {
    if (_stops.isEmpty || !mounted) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Check proximity to each stop
      int? newActiveId;
      // You can adjust this radius (in meters)
      const double thresholdMeters = 150.0; 

      for (final stop in _stops) {
        final double? lat = (stop['lat'] as num?)?.toDouble();
        final double? lng = (stop['long'] as num?)?.toDouble();

        if (lat == null || lng == null) continue;

        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lat,
          lng,
        );

        if (distance <= thresholdMeters) {
          newActiveId = stop['id'];
          break; // Found the active stop, stop searching
        }
      }

      if (mounted && newActiveId != _activeStopId) {
        setState(() {
          _activeStopId = newActiveId;
        });
      }

    } catch (e) {
      debugPrint('Error in location check: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Routes List', style: TextStyle(fontSize: 18)),
                  Text(
                    'Bus: $_busNumber',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_bus, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No stops assigned to Bus $_busNumber',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stops.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final stop = _stops[index];
                    final bool isActive = stop['id'] == _activeStopId;
                    
                    final String stopName = stop['stop_name'] ?? 'Unknown';
                    final String time = stop['arrival_time'] ?? '--:--';
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      shape: isActive 
                        ? RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.green, width: 1),
                          )
                        : null,
                      tileColor: isActive ? Colors.green.withValues(alpha: 0.05) : null,
                      leading: CircleAvatar(
                        backgroundColor: isActive 
                            ? Colors.green.withValues(alpha: 0.1) 
                            : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        foregroundColor: isActive 
                            ? Colors.green 
                            : Theme.of(context).primaryColor,
                        child: Icon(isActive ? Icons.my_location : Icons.location_on, size: 20),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              stopName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isActive)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green, width: 0.5),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(time, style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
