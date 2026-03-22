import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/stop_model.dart';
import '../services/bus_service.dart';
import 'app_theme.dart';

class RouteMappingScreen extends StatefulWidget {
  const RouteMappingScreen({super.key});

  @override
  State<RouteMappingScreen> createState() => _RouteMappingScreenState();
}

class _RouteMappingScreenState extends State<RouteMappingScreen> {
  final BusService _busService = BusService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<Stop> _stops = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isEditMode = false;
  int? _selectedStopId;
  LatLng? _searchMarker;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Stop> get _mappedStops =>
      _stops.where((s) => s.latitude != null && s.longitude != null).toList();

  Stop? get _selectedStop {
    if (_selectedStopId == null) {
      return null;
    }
    for (final stop in _stops) {
      if (stop.id == _selectedStopId) {
        return stop;
      }
    }
    return null;
  }

  Future<void> _loadStops() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final stops = await _busService.getAllStops();
      final firstMappedStop = stops.firstWhere(
        (s) => s.latitude != null && s.longitude != null,
        orElse: () => stops.isNotEmpty ? stops.first : _emptyStop,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stops = stops;
        if (_selectedStopId == null && stops.isNotEmpty) {
          _selectedStopId = stops.first.id;
        }
      });

      if (firstMappedStop.latitude != null &&
          firstMappedStop.longitude != null) {
        _mapController.move(
          LatLng(firstMappedStop.latitude!, firstMappedStop.longitude!),
          14,
        );
      }
    } catch (e) {
      _showMessage('Error loading stops: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onSearchSubmitted(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() => _isSearching = true);
    }

    try {
      final lowerQuery = query.toLowerCase();
      final matchedStop = _stops
          .where((s) => s.stopName.toLowerCase().contains(lowerQuery))
          .cast<Stop?>()
          .firstWhere((s) => s != null, orElse: () => null);

      if (matchedStop != null &&
          matchedStop.latitude != null &&
          matchedStop.longitude != null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedStopId = matchedStop.id;
          _searchMarker = null;
        });
        _mapController.move(
          LatLng(matchedStop.latitude!, matchedStop.longitude!),
          16,
        );
        return;
      }

      final geocoded = await _geocodeAddress(query);
      if (geocoded != null) {
        if (!mounted) {
          return;
        }
        setState(() => _searchMarker = geocoded);
        _mapController.move(geocoded, 15);
      } else {
        _showMessage('No stop or address found for "$query"');
      }
    } catch (e) {
      _showMessage('Search failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<LatLng?> _geocodeAddress(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '1',
      'addressdetails': '0',
    });

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'bms-admin-route-mapper/1.0',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      return null;
    }

    final first = decoded.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }

    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lng = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  Future<void> _onMapTap(LatLng point) async {
    if (!_isEditMode || _selectedStop == null) {
      return;
    }

    final stop = _selectedStop!;
    try {
      await _busService.updateStopLocation(
        stop.id,
        point.latitude,
        point.longitude,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _stops = _stops.map((s) {
          if (s.id != stop.id) {
            return s;
          }
          return Stop(
            id: s.id,
            stopName: s.stopName,
            feeAmount: s.feeAmount,
            arrivalTime: s.arrivalTime,
            actualBusId: s.actualBusId,
            latitude: point.latitude,
            longitude: point.longitude,
          );
        }).toList();
      });

      _showMessage('Updated location for ${stop.stopName}');
    } catch (e) {
      _showMessage('Failed to update stop location: $e');
    }
  }

  void _selectStop(Stop stop) {
    if (stop.latitude == null || stop.longitude == null) {
      _showMessage(
        'This stop has no coordinates yet. Use edit mode and tap map to place it.',
      );
      setState(() => _selectedStopId = stop.id);
      return;
    }

    setState(() {
      _selectedStopId = stop.id;
      _searchMarker = null;
    });
    _mapController.move(LatLng(stop.latitude!, stop.longitude!), 16);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _zoomMap(double delta) {
    try {
      final camera = _mapController.camera;
      final nextZoom = (camera.zoom + delta).clamp(3.0, 19.0);
      _mapController.move(camera.center, nextZoom);
    } catch (_) {
      _showMessage('Map is still initializing. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedStop = _selectedStop;
    final mappedStops = _mappedStops;

    return Container(
      color: bgColor(context),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: mappedStops.isNotEmpty
                          ? LatLng(
                              mappedStops.first.latitude!,
                              mappedStops.first.longitude!,
                            )
                          : const LatLng(9.9312, 76.2673),
                      initialZoom: 13,
                      onTap: (_, point) => _onMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'bms_admin',
                      ),
                      MarkerLayer(
                        markers: [
                          ...mappedStops.map((stop) {
                            final isSelected = stop.id == _selectedStopId;
                            return Marker(
                              point: LatLng(stop.latitude!, stop.longitude!),
                              width: 44,
                              height: 44,
                              child: GestureDetector(
                                onTap: () => _selectStop(stop),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : surfaceColor(context),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : borderColor(context),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    size: 24,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            );
                          }),
                          if (_searchMarker != null)
                            Marker(
                              point: _searchMarker!,
                              width: 38,
                              height: 38,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.place,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final searchWidth = constraints.maxWidth < 380
                          ? constraints.maxWidth
                          : 360.0;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: searchWidth,
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _onSearchSubmitted,
                              decoration: InputDecoration(
                                hintText: 'Search stop name or address...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: surfaceColor(context),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: borderColor(context),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: borderColor(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: _isSearching
                                  ? null
                                  : () => _onSearchSubmitted(
                                      _searchController.text,
                                    ),
                              icon: _isSearching
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.travel_explore),
                              label: const Text('Search'),
                            ),
                          ),
                          SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isEditMode
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() => _isEditMode = !_isEditMode);
                              },
                              icon: Icon(
                                _isEditMode
                                    ? Icons.close
                                    : Icons.edit_location_alt,
                              ),
                              label: Text(
                                _isEditMode
                                    ? 'Exit Edit Mode'
                                    : 'Edit/Move Points',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 14,
                  top: 78,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor(context).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor(context)),
                    ),
                    child: Text(
                      _isEditMode
                          ? 'Edit mode is ON: select a stop marker, then tap anywhere on map to reposition it.'
                          : 'Select a stop marker to view details.',
                      style: TextStyle(
                        color: onSurfaceVariant(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor(context).withOpacity(0.97),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Zoom in',
                          onPressed: () => _zoomMap(1),
                          icon: Icon(Icons.add, color: onSurface(context)),
                        ),
                        Container(
                          width: 32,
                          height: 1,
                          color: borderColor(context),
                        ),
                        IconButton(
                          tooltip: 'Zoom out',
                          onPressed: () => _zoomMap(-1),
                          icon: Icon(Icons.remove, color: onSurface(context)),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surfaceColor(context).withOpacity(0.97),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: selectedStop == null
                        ? Text(
                            'No stop selected',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: onSurface(context),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Stop Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: onSurface(context),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                selectedStop.stopName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: onSurface(context),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Fee: ₹${selectedStop.feeAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: onSurfaceVariant(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lat: ${selectedStop.latitude?.toStringAsFixed(6) ?? 'N/A'}',
                                style: TextStyle(
                                  color: onSurfaceVariant(context),
                                ),
                              ),
                              Text(
                                'Lng: ${selectedStop.longitude?.toStringAsFixed(6) ?? 'N/A'}',
                                style: TextStyle(
                                  color: onSurfaceVariant(context),
                                ),
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

final Stop _emptyStop = Stop(id: -1, stopName: 'Unknown', feeAmount: 0);
