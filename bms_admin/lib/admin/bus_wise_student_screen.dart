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
  final BusService _busService = BusService();
  final StudentService _studentService = StudentService();

  List<Bus> _buses = [];
  Map<int, List<Map<String, dynamic>>> _busStudents = {};
  int? _selectedBusId;
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
      setState(() {
        _buses = buses;
        if (_selectedBusId == null && buses.isNotEmpty) {
          _selectedBusId = buses.first.id;
        }
      });
      if (_selectedBusId != null) {
        await _loadBusStudents(_selectedBusId!);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load buses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBusStudents(int busId) async {
    try {
      final students = await _busService.getStudentsWithPaymentByBus(busId);
      setState(() => _busStudents[busId] = students);
    } catch (e) {
      _showError('Error loading students: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _routeLabel(int index) {
    const labels = ['PRIMARY ROUTE', 'EXPRESS ROUTE', 'SHUTTLE SERVICE'];
    return labels[index % labels.length];
  }

  String _studentTag(String id) {
    final token = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id;
    return 'STU-$token';
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
    final dark = isDark(context);
    final border = Theme.of(
      context,
    ).dividerColor.withValues(alpha: dark ? 0.45 : 0.85);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
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
                final isSelected = _selectedBusId == bus.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() => _selectedBusId = bus.id);
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
                              : border,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _routeLabel(index),
                            style: TextStyle(
                              color: onSurfaceVariant(context),
                              fontSize: 10,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                                'CAPACITY\n$studentCount/${bus.totalCapacity}',
                                style: TextStyle(
                                  color: onSurfaceVariant(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                'ZONE\nCampus',
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
        border: Border.all(color: border),
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
                        'Showing ${students.length} confirmed passengers.',
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
                  flex: 2,
                  child: Text(
                    'ID\nNUMBER',
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
                    itemCount: students.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: border),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final fullName = (student['full_name'] ?? 'N/A')
                          .toString();
                      final studentId = (student['id'] ?? '').toString();

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
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: inputFillColor(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _studentTag(studentId),
                                  style: TextStyle(
                                    color: onSurfaceVariant(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                                child: Icon(
                                  Icons.more_vert,
                                  color: onSurfaceVariant(context),
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
                  'Showing ${students.length} students',
                  style: TextStyle(
                    color: onSurfaceVariant(context),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                OutlinedButton(onPressed: null, child: const Text('Previous')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: null, child: const Text('1')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: null, child: const Text('2')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: null, child: const Text('Next')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
