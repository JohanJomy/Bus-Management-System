import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bus_model.dart';
import '../models/stop_model.dart';
import '../services/bus_service.dart';
import 'allocation_algorithm.dart';
import 'app_theme.dart';

class BusAllocationScreen extends StatefulWidget {
  const BusAllocationScreen({super.key});

  @override
  State<BusAllocationScreen> createState() => _BusAllocationScreenState();
}

class _BusAllocationScreenState extends State<BusAllocationScreen> {
  static const int _rootStopId = 235;
  static const List<int> _availableSemesters = [2, 4, 6, 8];

  final BusService _busService = BusService();
  final MapController _mapController = MapController();

  bool _isLoading = true;
  bool _isAllocating = false;
  bool _useBusColorMode = false;

  DateTime _selectedDate = DateTime.now();
  final Set<int> _selectedSemesters = {2, 4, 6, 8};
  final Set<String> _selectedCourses = <String>{};

  List<Bus> _buses = <Bus>[];
  List<String> _courses = <String>[];
  List<Stop> _stops = <Stop>[];
  List<Map<String, dynamic>> _stopLinks = <Map<String, dynamic>>[];
  Map<int, int> _manifestDominantBusByStop = <int, int>{};

  Set<int> _leafStopIds = <int>{};
  AllocationRunResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final buses = await _busService.getAllBuses();
      final stops = await _busService.getAllStops();
      final links = await _busService.getStopLinks();

      final coursesRaw = await Supabase.instance.client
          .from('students')
          .select('course') as List<dynamic>;

      final uniqueCourses = coursesRaw
          .map((e) => (e as Map<String, dynamic>)['course']?.toString() ?? '')
          .where((c) => c.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (!mounted) return;

      setState(() {
        _buses = buses;
        _stops = stops;
        _stopLinks = links;
        _courses = uniqueCourses;
        _selectedCourses
          ..clear()
          ..addAll(uniqueCourses);
        _leafStopIds = _computeLeafStops(stops, links, _rootStopId);
      });

      await _loadManifestBusColors();

      final mappedStops =
          stops.where((s) => s.latitude != null && s.longitude != null).toList();
      if (mappedStops.isNotEmpty) {
        _mapController.move(
          LatLng(mappedStops.first.latitude!, mappedStops.first.longitude!),
          13,
        );
      }
    } catch (e) {
      _showMessage('Failed to load allocation inputs: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Set<int> _computeLeafStops(
    List<Stop> stops,
    List<Map<String, dynamic>> links,
    int rootStopId,
  ) {
    final adj = <int, Set<int>>{for (final s in stops) s.id: <int>{}};

    for (final link in links) {
      final from = _toInt(link['from_stop_id']);
      final to = _toInt(link['to_stop_id']);
      if (from == null || to == null) continue;
      adj.putIfAbsent(from, () => <int>{}).add(to);
      adj.putIfAbsent(to, () => <int>{}).add(from);
    }

    // Keep only nodes connected to the root component.
    final connectedToRoot = <int>{};
    final q = Queue<int>();
    q.add(rootStopId);
    connectedToRoot.add(rootStopId);

    while (q.isNotEmpty) {
      final node = q.removeFirst();
      for (final nxt in adj[node] ?? const <int>{}) {
        if (connectedToRoot.contains(nxt)) continue;
        connectedToRoot.add(nxt);
        q.add(nxt);
      }
    }

    // Leaf (pendant) nodes in rooted undirected graph:
    // connected to root, not root itself, and degree == 1 in root component.
    return adj.keys
        .where((id) {
          if (id == rootStopId || !connectedToRoot.contains(id)) return false;
          final degreeInComponent = (adj[id] ?? const <int>{})
              .where(connectedToRoot.contains)
              .length;
          return degreeInComponent <= 1;
        })
        .toSet();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      await _loadManifestBusColors();
    }
  }

  Future<void> _allocateNow() async {
    if (_selectedSemesters.isEmpty) {
      _showMessage('Select at least one semester.');
      return;
    }
    if (_selectedCourses.isEmpty) {
      _showMessage('Select at least one course.');
      return;
    }

    if (mounted) {
      setState(() => _isAllocating = true);
    }

    try {
      final allocator = BottomUpGreedyFlowAllocator();
      final result = await allocator.allocateForDate(
        targetDate: _selectedDate,
        activeSemesters: _selectedSemesters.toList()..sort(),
        activeCourses: _selectedCourses.toList()..sort(),
        persistToDatabase: true,
        rootStopId: _rootStopId,
        clearAllExistingManifests: true,
      );

      if (!mounted) return;

      setState(() => _lastResult = result);
      await _loadManifestBusColors();
      _showMessage(
        'Allocation complete. ${result.summary.totalStudents} students assigned.',
      );
    } catch (e) {
      _showMessage('Allocation failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isAllocating = false);
      }
    }
  }

  String _dateIso(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _loadManifestBusColors() async {
    try {
      final manifestsRaw = await Supabase.instance.client
          .from('daily_manifests')
          .select('student_id,allocated_bus_id')
          .eq('manifest_date', _dateIso(_selectedDate)) as List<dynamic>;

      final manifests = manifestsRaw.cast<Map<String, dynamic>>();
      if (manifests.isEmpty) {
        if (!mounted) return;
        setState(() => _manifestDominantBusByStop = <int, int>{});
        return;
      }

      final studentIds = manifests
          .map((e) => e['student_id']?.toString())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      final stopByStudentId = <String, int>{};
      const chunkSize = 500;
      for (var i = 0; i < studentIds.length; i += chunkSize) {
        final end = (i + chunkSize < studentIds.length)
            ? i + chunkSize
            : studentIds.length;
        final chunk = studentIds.sublist(i, end);

        final studentsRaw = await Supabase.instance.client
            .from('students')
            .select('id,boarding_stop_id')
            .inFilter('id', chunk) as List<dynamic>;

        for (final row in studentsRaw.cast<Map<String, dynamic>>()) {
          final sid = row['id']?.toString();
          final stopId = _toInt(row['boarding_stop_id']);
          if (sid == null || stopId == null) continue;
          stopByStudentId[sid] = stopId;
        }
      }

      final grouped = <int, Map<int, int>>{};
      for (final row in manifests) {
        final sid = row['student_id']?.toString();
        final busId = _toInt(row['allocated_bus_id']);
        if (sid == null || busId == null) continue;
        final stopId = stopByStudentId[sid];
        if (stopId == null) continue;

        final byBus = grouped.putIfAbsent(stopId, () => <int, int>{});
        byBus[busId] = (byBus[busId] ?? 0) + 1;
      }

      final dominant = <int, int>{};
      for (final entry in grouped.entries) {
        int? selectedBusId;
        var bestCount = -1;
        for (final busEntry in entry.value.entries) {
          final busId = busEntry.key;
          final count = busEntry.value;
          if (count > bestCount ||
              (count == bestCount &&
                  (selectedBusId == null || busId < selectedBusId))) {
            bestCount = count;
            selectedBusId = busId;
          }
        }
        if (selectedBusId != null) {
          dominant[entry.key] = selectedBusId;
        }
      }

      if (!mounted) return;
      setState(() => _manifestDominantBusByStop = dominant);
    } catch (_) {
      if (!mounted) return;
      setState(() => _manifestDominantBusByStop = <int, int>{});
    }
  }

  int? _busNumberById(int busId) {
    final Object? busesObject = _buses;
    if (busesObject is! List) {
      return null;
    }

    for (final bus in busesObject) {
      if (bus is Bus && bus.id == busId) return bus.busNumber;
    }
    return null;
  }

  Color _busColor(int busId) {
    const palette = <Color>[
      Colors.red,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.brown,
      Colors.cyan,
      Colors.lime,
      Colors.deepOrange,
      Colors.amber,
      Colors.deepPurple,
    ];
    final idx = busId % palette.length;
    return palette[idx];
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final mappedStops =
        _stops.where((s) => s.latitude != null && s.longitude != null).toList();

    return Container(
      color: bgColor(context),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final mapHeight = (constraints.maxHeight * 0.75).clamp(
                  520.0,
                  900.0,
                );

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus Allocation',
                        style: TextStyle(
                          color: onSurface(context),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bottom-Up Greedy Flow (Root: #$_rootStopId)',
                        style: TextStyle(color: onSurfaceVariant(context)),
                      ),
                      const SizedBox(height: 16),
                      _buildControlsCard(),
                      const SizedBox(height: 14),
                      if (_lastResult != null) _buildSummaryCard(_lastResult!),
                      const SizedBox(height: 14),
                      _buildLegend(),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: mapHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
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
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'bms_admin',
                              ),
                              PolylineLayer(polylines: _buildPolylines()),
                              MarkerLayer(markers: _buildMarkers(mappedStops)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildControlsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
            ),
          ),
          _buildMultiSelectChipGroup<int>(
            title: 'Semesters',
            options: _availableSemesters,
            selected: _selectedSemesters,
            labelBuilder: (v) => 'Sem $v',
          ),
          _buildMultiSelectChipGroup<String>(
            title: 'Courses',
            options: _courses,
            selected: _selectedCourses,
            labelBuilder: (v) => v,
          ),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _isAllocating ? null : _allocateNow,
              icon: _isAllocating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(_isAllocating ? 'Allocating...' : 'Allocate'),
            ),
          ),
          SizedBox(
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _manifestDominantBusByStop.isEmpty
                  ? null
                  : () {
                      setState(() => _useBusColorMode = !_useBusColorMode);
                    },
              icon: Icon(
                _useBusColorMode ? Icons.visibility : Icons.palette_outlined,
              ),
              label: Text(
                _useBusColorMode ? 'Normal Nodes' : 'Bus Color Mode',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectChipGroup<T>({
    required String title,
    required List<T> options,
    required Set<T> selected,
    required String Function(T value) labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: onSurfaceVariant(context),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options.map((value) {
              final isSelected = selected.contains(value);
              return FilterChip(
                selected: isSelected,
                label: Text(labelBuilder(value)),
                onSelected: (_) {
                  setState(() {
                    if (isSelected) {
                      selected.remove(value);
                    } else {
                      selected.add(value);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AllocationRunResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allocation Summary',
            style: TextStyle(
              color: onSurface(context),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total Students: ${result.summary.totalStudents} | '
            'Total Buses Used: ${result.summary.totalBusesUsed} | '
            'Leaf Stops: ${result.summary.totalLeafStops}',
            style: TextStyle(color: onSurfaceVariant(context)),
          ),
          const SizedBox(height: 6),
          Text(
            'Inserted rows: ${result.insertStatements.length}',
            style: TextStyle(color: onSurfaceVariant(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final dominantBusByStop = _manifestDominantBusByStop;

    if (_useBusColorMode && dominantBusByStop.isNotEmpty) {
      final busIds = dominantBusByStop.values.toSet().toList()..sort();
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _legendItem(Colors.grey.shade700, 'Unallocated stop'),
          ...busIds.map((busId) {
            final busNo = _busNumberById(busId);
            final label = busNo == null ? 'Bus ID $busId' : 'Bus #$busNo';
            return _legendItem(_busColor(busId), label);
          }),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _legendItem(Colors.deepPurple, 'Root (#$_rootStopId)'),
        _legendItem(Colors.green, 'Leaf stop'),
        _legendItem(Colors.black, 'Intermediate stop'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: onSurfaceVariant(context))),
      ],
    );
  }

  List<Polyline> _buildPolylines() {
    return _stopLinks
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
            color: Colors.red.shade700,
            strokeWidth: 3,
          );
        })
        .whereType<Polyline>()
        .toList();
  }

  List<Marker> _buildMarkers(List<Stop> mappedStops) {
    final dominantBusByStop = _manifestDominantBusByStop;

    return mappedStops.map((stop) {
      final isRoot = stop.id == _rootStopId;
      final isLeaf = _leafStopIds.contains(stop.id);

      final color = _useBusColorMode
          ? (dominantBusByStop.containsKey(stop.id)
                ? _busColor(dominantBusByStop[stop.id]!)
                : Colors.grey.shade700)
          : (isRoot
                ? Colors.deepPurple
                : (isLeaf ? Colors.green : Colors.black));

      return Marker(
        point: LatLng(stop.latitude!, stop.longitude!),
        width: 28,
        height: 28,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${stop.id}',
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
