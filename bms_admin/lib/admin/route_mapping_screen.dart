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
  static const int _rootStopId = 235;

  final BusService _busService = BusService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<Stop> _stops = [];
  List<Map<String, dynamic>> _stopLinks = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isEditMode = false;
  bool _showEdges = false;
  bool _isAddEdgeMode = false;
  bool _isDeleteEdgeMode = false;
  int? _selectedStopId;
  int? _pendingEdgeFromStopId;
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
      final stopLinks = await _busService.getStopLinks();
      final firstMappedStop = stops.firstWhere(
        (s) => s.latitude != null && s.longitude != null,
        orElse: () => stops.isNotEmpty ? stops.first : _emptyStop,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stops = stops;
        _stopLinks = stopLinks;
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
      Stop? matchedStop;

      // Try to parse query as ID first
      final stopId = int.tryParse(query);
      if (stopId != null) {
        matchedStop = _stops.cast<Stop?>().firstWhere(
          (s) => s?.id == stopId,
          orElse: () => null,
        );
      }

      // If no ID match, search by stop name
      if (matchedStop == null) {
        final lowerQuery = query.toLowerCase();
        matchedStop = _stops
            .where((s) => s.stopName.toLowerCase().contains(lowerQuery))
            .cast<Stop?>()
            .firstWhere((s) => s != null, orElse: () => null);
      }

      if (matchedStop != null &&
          matchedStop.latitude != null &&
          matchedStop.longitude != null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedStopId = matchedStop!.id;
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
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  bool _edgeExists(int fromStopId, int toStopId) {
    for (final link in _stopLinks) {
      final from = _toInt(link['from_stop_id']);
      final to = _toInt(link['to_stop_id']);
      if ((from == fromStopId && to == toStopId) ||
          (from == toStopId && to == fromStopId)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _onStopMarkerTap(Stop stop) async {
    if (!(_showEdges && (_isAddEdgeMode || _isDeleteEdgeMode))) {
      _selectStop(stop);
      return;
    }

    final fromStopId = _pendingEdgeFromStopId;
    if (fromStopId == null) {
      setState(() {
        _pendingEdgeFromStopId = stop.id;
        _selectedStopId = stop.id;
      });
      _showMessage('First stop selected (#${stop.id}). Select second stop.');
      return;
    }

    if (fromStopId == stop.id) {
      _showMessage('Select a different second stop.');
      return;
    }

    if (_edgeExists(fromStopId, stop.id)) {
      if (_isDeleteEdgeMode) {
        try {
          await _busService.deleteStopLink(fromStopId, stop.id);
          if (!mounted) return;

          setState(() {
            _stopLinks = _stopLinks.where((link) {
              final from = _toInt(link['from_stop_id']);
              final to = _toInt(link['to_stop_id']);
              return !((from == fromStopId && to == stop.id) ||
                  (from == stop.id && to == fromStopId));
            }).toList();
            _pendingEdgeFromStopId = null;
            _selectedStopId = stop.id;
          });
          _showMessage('Edge deleted: #$fromStopId ↔ #${stop.id}');
        } catch (e) {
          _showMessage('Failed to delete edge: $e');
        }
        return;
      }

      setState(() => _pendingEdgeFromStopId = null);
      _showMessage('Edge already exists between #$fromStopId and #${stop.id}.');
      return;
    }

    if (_isDeleteEdgeMode) {
      setState(() => _pendingEdgeFromStopId = null);
      _showMessage('No edge found between #$fromStopId and #${stop.id}.');
      return;
    }

    try {
      await _busService.addStopLink(fromStopId, stop.id);
      if (!mounted) return;

      setState(() {
        _stopLinks = [
          ..._stopLinks,
          {'from_stop_id': fromStopId, 'to_stop_id': stop.id},
        ];
        _pendingEdgeFromStopId = null;
        _selectedStopId = stop.id;
      });
      _showMessage('Edge added: #$fromStopId ↔ #${stop.id}');
    } catch (e) {
      _showMessage('Failed to add edge: $e');
    }
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
                      if (_showEdges)
                        PolylineLayer(
                          polylines: _stopLinks
                              .map((link) {
                                final fromId = _toInt(link['from_stop_id']);
                                final toId = _toInt(link['to_stop_id']);
                                if (fromId == null || toId == null) return null;

                                final fromStop = _stops.cast<Stop?>().firstWhere(
                                  (s) => s?.id == fromId,
                                  orElse: () => null,
                                );
                                final toStop = _stops.cast<Stop?>().firstWhere(
                                  (s) => s?.id == toId,
                                  orElse: () => null,
                                );

                                if (fromStop == null ||
                                    toStop == null ||
                                    fromStop.latitude == null ||
                                    fromStop.longitude == null ||
                                    toStop.latitude == null ||
                                    toStop.longitude == null) {
                                  return null;
                                }

                                return Polyline(
                                  points: [
                                    LatLng(fromStop.latitude!, fromStop.longitude!),
                                    LatLng(toStop.latitude!, toStop.longitude!),
                                  ],
                                  color: Colors.red[900]!,
                                  strokeWidth: 4,
                                );
                              })
                              .whereType<Polyline>()
                              .toList(),
                        ),
                      MarkerLayer(
                        markers: [
                          ...mappedStops.map((stop) {
                            final isSelected = stop.id == _selectedStopId;
                            final isPendingEdgeStart =
                                stop.id == _pendingEdgeFromStopId;
                            final isRootStop = stop.id == _rootStopId;
                            double zoomLevel = 13.0;
                            try {
                              zoomLevel = _mapController.camera.zoom;
                            } catch (_) {
                              zoomLevel = 13.0;
                            }
                            final markerSize = (zoomLevel * 1.5).clamp(14.0, 40.0);
                            final textSize = (zoomLevel * 0.4).clamp(6.0, 10.0);
                            return Marker(
                              point: LatLng(stop.latitude!, stop.longitude!),
                              width: markerSize,
                              height: markerSize,
                              child: GestureDetector(
                                onTap: () => _onStopMarkerTap(stop),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isPendingEdgeStart
                                        ? Colors.orange
                                        : (isSelected
                                            ? Colors.blue
                                            : (isRootStop
                                                ? Colors.deepPurple
                                                : Colors.black)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (isSelected || isPendingEdgeStart)
                                          ? Colors.white
                                          : (isRootStop
                                              ? Colors.deepPurpleAccent
                                              : Colors.black),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      stop.id.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: textSize,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                          SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _showEdges
                                    ? Colors.blueAccent
                                    : Colors.grey[600],
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showEdges = !_showEdges;
                                  if (!_showEdges) {
                                    _isAddEdgeMode = false;
                                    _isDeleteEdgeMode = false;
                                    _pendingEdgeFromStopId = null;
                                  }
                                });
                              },
                              icon: Icon(
                                _showEdges
                                    ? Icons.link
                                    : Icons.link_off,
                              ),
                              label: Text(
                                _showEdges ? 'Hide Routes' : 'Show Routes',
                              ),
                            ),
                          ),
                          if (_showEdges)
                            SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isAddEdgeMode
                                      ? Colors.deepOrange
                                      : Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isAddEdgeMode = !_isAddEdgeMode;
                                    if (_isAddEdgeMode) {
                                      _isDeleteEdgeMode = false;
                                    }
                                    if (!_isAddEdgeMode) {
                                      _pendingEdgeFromStopId = null;
                                    }
                                  });
                                },
                                icon: Icon(
                                  _isAddEdgeMode
                                      ? Icons.timeline
                                      : Icons.add_link,
                                ),
                                label: Text(
                                  _isAddEdgeMode ? 'Finish Edge' : 'Add Edge',
                                ),
                              ),
                            ),
                          if (_showEdges)
                            SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isDeleteEdgeMode
                                      ? Colors.red[800]
                                      : Colors.brown,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isDeleteEdgeMode = !_isDeleteEdgeMode;
                                    if (_isDeleteEdgeMode) {
                                      _isAddEdgeMode = false;
                                    }
                                    if (!_isDeleteEdgeMode) {
                                      _pendingEdgeFromStopId = null;
                                    }
                                  });
                                },
                                icon: Icon(
                                  _isDeleteEdgeMode
                                      ? Icons.delete_forever
                                      : Icons.remove_circle_outline,
                                ),
                                label: Text(
                                  _isDeleteEdgeMode
                                      ? 'Finish Delete'
                                      : 'Delete Edge',
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
                      _isDeleteEdgeMode
                        ? (_pendingEdgeFromStopId == null
                          ? 'Delete Edge mode: select first stop marker.'
                          : 'Delete Edge mode: select second stop to delete edge from #$_pendingEdgeFromStopId.')
                        : (_isAddEdgeMode
                        ? (_pendingEdgeFromStopId == null
                          ? 'Add Edge mode: select first stop marker.'
                          : 'Add Edge mode: select second stop to create edge from #$_pendingEdgeFromStopId.')
                        : (_isEditMode
                          ? 'Edit mode is ON: select a stop marker, then tap anywhere on map to reposition it.'
                          : 'Select a stop marker to view details.')),
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
                                '${selectedStop.stopName} (#${selectedStop.id})',
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
                                'Bus: ${selectedStop.actualBusId ?? 'N/A'}',
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