import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_model.dart';
import '../services/bus_service.dart';
import '../services/student_service.dart';
import '../models/bus_model.dart';
import 'app_theme.dart';

class BusWiseStudentListScreen extends StatefulWidget {
  const BusWiseStudentListScreen({super.key});

  @override
  State<BusWiseStudentListScreen> createState() =>
      _BusWiseStudentListScreenState();
}

class _BusWiseStudentListScreenState extends State<BusWiseStudentListScreen> {
  static const int _studentsPageSize = 10;

  final BusService _busService = BusService();
  final StudentService _studentService = StudentService();

  List<Bus> _buses = [];
  Map<int, List<Map<String, dynamic>>> _busStudents = {};
  int? _selectedBusId;
  int _visibleStudentsCount = _studentsPageSize;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final buses = await _busService.getAllBuses();
      final preloadedBusStudents = <int, List<Map<String, dynamic>>>{};

      for (final bus in buses) {
        try {
          final manifests = await _busService.getStudentsWithPaymentByBus(bus.id);
          preloadedBusStudents[bus.id] = _normalizeBusStudents(manifests);
        } catch (_) {
          preloadedBusStudents[bus.id] = <Map<String, dynamic>>[];
        }
      }

      setState(() {
        _buses = buses;
        _busStudents = preloadedBusStudents;
        if (_selectedBusId == null && buses.isNotEmpty) {
          _selectedBusId = buses.first.id;
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load buses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBusStudents(int busId) async {
    try {
      final manifests = await _busService.getStudentsWithPaymentByBus(busId);
      final students = _normalizeBusStudents(manifests);
      setState(() => _busStudents[busId] = students);
    } catch (e) {
      _showError('Error loading students: $e');
    }
  }

  List<Map<String, dynamic>> _normalizeBusStudents(
    List<Map<String, dynamic>> rows,
  ) {
    final byStudentId = <String, Map<String, dynamic>>{};

    for (final row in rows) {
      final student = _extractStudentRow(row);
      if (student == null) {
        continue;
      }

      final studentId = student['id']?.toString();
      if (studentId == null || studentId.isEmpty) {
        continue;
      }

      final manifestDate = row['manifest_date']?.toString() ?? '';
      final existing = byStudentId[studentId];
      final existingDate = existing?['_manifest_date']?.toString() ?? '';

      if (existing == null || manifestDate.compareTo(existingDate) >= 0) {
        final merged = Map<String, dynamic>.from(student);
        merged['_manifest_date'] = manifestDate;
        merged['allocated_bus_id'] = row['allocated_bus_id'];
        byStudentId[studentId] = merged;
      }
    }

    final normalized = byStudentId.values.toList();
    normalized.sort((a, b) {
      final aName = (a['full_name'] ?? '').toString().toLowerCase();
      final bName = (b['full_name'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });
    return normalized;
  }

  Map<String, dynamic>? _extractStudentRow(Map<String, dynamic> row) {
    if (row.containsKey('full_name')) {
      return Map<String, dynamic>.from(row);
    }

    final nested = row['students'];
    if (nested is Map<String, dynamic>) {
      return Map<String, dynamic>.from(nested);
    }
    if (nested is Map) {
      return nested.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _locationText(Map<String, dynamic> student) {
    final stopId = student['boarding_stop_id'];
    if (stopId == null) {
      return 'Not Assigned';
    }
    return 'Stop $stopId';
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'NA';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  String _generateUuidV4() {
    final random = DateTime.now().microsecondsSinceEpoch;
    final seed = random.toRadixString(16).padLeft(32, '0');
    return '${seed.substring(0, 8)}-'
        '${seed.substring(8, 12)}-'
        '4${seed.substring(13, 16)}-'
        'a${seed.substring(17, 20)}-'
        '${seed.substring(20, 32)}';
  }

  Future<void> _showAddStudentDialog() async {
    if (_selectedBusId == null) {
      _showError('Select a bus first');
      return;
    }

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final courseController = TextEditingController();
    final semesterController = TextEditingController();
    final stopController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: courseController,
                    decoration: const InputDecoration(labelText: 'Course'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: semesterController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Semester (optional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: stopController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Boarding Stop Id (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              final student = Student(
                id: _generateUuidV4(),
                fullName: nameController.text.trim(),
                email: emailController.text.trim(),
                course: courseController.text.trim().isEmpty
                    ? null
                    : courseController.text.trim(),
                semester: semesterController.text.trim().isEmpty
                    ? null
                    : int.tryParse(semesterController.text.trim()),
                boardingStopId: stopController.text.trim().isEmpty
                    ? null
                    : int.tryParse(stopController.text.trim()),
              );

              try {
                await _studentService.addStudent(student);
                await Supabase.instance.client.from('daily_manifests').insert({
                  'student_id': student.id,
                  'allocated_bus_id': _selectedBusId,
                  'manifest_date': DateTime.now()
                      .toIso8601String()
                      .split('T')
                      .first,
                });

                if (!mounted) {
                  return;
                }
                Navigator.pop(ctx);
                await _loadBusStudents(_selectedBusId!);
                _showError('Student added successfully');
              } catch (e) {
                _showError('Failed to add student: $e');
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> student) {
    final fullNameController = TextEditingController(
      text: student['full_name'] ?? '',
    );
    final emailController = TextEditingController(text: student['email'] ?? '');
    final courseController = TextEditingController(
      text: student['course'] ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _showError('Edit functionality to be implemented');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Container(
      color: bgColor(context),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Roster',
                            style: TextStyle(
                              color: onSurface(context),
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage student assignments and bus occupancy for the current semester.',
                            style: TextStyle(
                              color: onSurfaceVariant(context),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _showAddStudentDialog,
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text('Add Student'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 980;
                      if (compact) {
                        return Column(
                          children: [
                            SizedBox(height: 280, child: _buildBusPanel()),
                            const SizedBox(height: 12),
                            Expanded(child: _buildStudentPanel(dark)),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          SizedBox(width: 340, child: _buildBusPanel()),
                          const SizedBox(width: 14),
                          Expanded(child: _buildStudentPanel(dark)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBusPanel() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark(context) ? 0.0 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Fleet',
                  style: TextStyle(
                    color: onSurface(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: inputFillColor(context),
                  ),
                  child: Text(
                    '${_buses.length} TOTAL',
                    style: TextStyle(
                      color: onSurfaceVariant(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              itemCount: _buses.length,
              itemBuilder: (context, index) {
                final bus = _buses[index];
                final studentCount = _busStudents[bus.id]?.length ?? 0;
                final availableSeats = (bus.totalCapacity - studentCount).clamp(
                  0,
                  bus.totalCapacity,
                );
                final isSelected = _selectedBusId == bus.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedBusId = bus.id;
                        _visibleStudentsCount = _studentsPageSize;
                      });
                      _loadBusStudents(bus.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.08)
                            : inputFillColor(context),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : borderColor(context),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bus #${bus.busNumber}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: onSurface(context),
                              fontSize: 34,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'CAPACITY\n${bus.totalCapacity}',
                                style: TextStyle(
                                  color: onSurfaceVariant(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                'FILLED\n$studentCount',
                                style: TextStyle(
                                  color: onSurfaceVariant(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                'AVAILABLE\n$availableSeats',
                                style: TextStyle(
                                  color: onSurfaceVariant(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: bus.totalCapacity == 0
                                ? 0
                                : (studentCount / bus.totalCapacity)
                                      .clamp(0, 1)
                                      .toDouble(),
                            minHeight: 4,
                            color: Theme.of(context).primaryColor,
                            backgroundColor: inputFillColor(context),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$studentCount assigned',
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurfaceVariant(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPanel(bool dark) {
    return _selectedBusId == null
        ? const Center(child: Text('Select a bus to view students'))
        : _buildStudentList(dark);
  }

  Widget _buildStudentList(bool dark) {
    final students = _busStudents[_selectedBusId] ?? [];
    final visibleStudents = students.take(_visibleStudentsCount).toList();
    final hasMoreStudents = visibleStudents.length < students.length;
    final selectedBus = _buses.firstWhere(
      (b) => b.id == _selectedBusId,
      orElse: () => _buses.first,
    );

    final border = Theme.of(
      context,
    ).dividerColor.withValues(alpha: dark ? 0.45 : 0.85);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark(context) ? 0.0 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus #${selectedBus.busNumber}: Assigned Students',
                        style: TextStyle(
                          color: onSurface(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Showing ${visibleStudents.length}/${students.length} confirmed passengers.',
                        style: TextStyle(color: onSurfaceVariant(context)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.tune, color: onSurfaceVariant(context)),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.download, color: onSurfaceVariant(context)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            color: inputFillColor(context),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'STUDENT\nNAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: onSurfaceVariant(context),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'COURSE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: onSurfaceVariant(context),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'STOP /\nLOCATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: onSurfaceVariant(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ACTIONS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: onSurfaceVariant(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Text(
                      'No students assigned to this bus yet.',
                      style: TextStyle(color: onSurfaceVariant(context)),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleStudents.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: border),
                    itemBuilder: (context, index) {
                      final student = visibleStudents[index];
                      final fullName = (student['full_name'] ?? 'N/A')
                          .toString();

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      _initials(fullName),
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fullName,
                                      style: TextStyle(
                                        color: onSurface(context),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                (student['course'] ?? 'N/A').toString(),
                                style: TextStyle(
                                  color: onSurface(context),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _locationText(student),
                                      style: TextStyle(
                                        color: onSurfaceVariant(context),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: IconButton(
                                  onPressed: () => _showEditDialog(student),
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: onSurfaceVariant(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Text(
                  'Showing ${visibleStudents.length}/${students.length} students',
                  style: TextStyle(
                    color: onSurfaceVariant(context),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (hasMoreStudents)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _visibleStudentsCount += _studentsPageSize;
                      });
                    },
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: const Text('Show More'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
