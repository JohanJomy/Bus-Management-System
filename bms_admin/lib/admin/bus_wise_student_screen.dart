import 'package:flutter/material.dart';
import '../services/bus_service.dart';
import '../models/bus_model.dart';

class BusWiseStudentListScreen extends StatefulWidget {
  const BusWiseStudentListScreen({super.key});

  @override
  State<BusWiseStudentListScreen> createState() =>
      _BusWiseStudentListScreenState();
}

class _BusWiseStudentListScreenState extends State<BusWiseStudentListScreen> {
  final BusService _busService = BusService();

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
      setState(() => _buses = buses);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load buses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBusStudents(int busId) async {
    if (_busStudents.containsKey(busId)) return;

    try {
      final students = await _busService.getStudentsWithPaymentByBus(busId);
      setState(() => _busStudents[busId] = students);
    } catch (e) {
      _showError('Error loading students: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showEditDialog(Map<String, dynamic> student) {
    final fullNameController = TextEditingController(text: student['full_name'] ?? '');
    final emailController = TextEditingController(text: student['email'] ?? '');
    final courseController = TextEditingController(text: student['course'] ?? '');

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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bus-wise Student Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Text(_errorMessage!)
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;
                  final panelWidth = isSmallScreen
                      ? constraints.maxWidth * 0.4
                      : 250.0;

                  if (isSmallScreen) {
                    // Mobile: Stacked vertically
                    return Column(
                      children: [
                        Expanded(
                          flex: 40,
                          child: _buildBusPanel(panelWidth),
                        ),
                        const Divider(height: 24),
                        Expanded(
                          flex: 60,
                          child: _buildStudentPanel(),
                        ),
                      ],
                    );
                  } else {
                    // Desktop: Side by side
                    return Row(
                      children: [
                        SizedBox(
                          width: panelWidth,
                          child: _buildBusPanel(panelWidth),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStudentPanel(),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBusPanel(double width) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Bus',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _buses.length,
              itemBuilder: (context, index) {
                final bus = _buses[index];
                final studentCount = _busStudents[bus.id]?.length ?? 0;
                final isSelected = _selectedBusId == bus.id;

                return Material(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedBusId = bus.id);
                      _loadBusStudents(bus.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bus #${bus.busNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Capacity: ${bus.totalCapacity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Students: $studentCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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

  Widget _buildStudentPanel() {
    return _selectedBusId == null
        ? const Center(child: Text('Select a bus to view students'))
        : _buildStudentList();
  }

  Widget _buildStudentList() {
    final students = _busStudents[_selectedBusId] ?? [];

    if (students.isEmpty) {
      return Center(
        child: Text(
          'No students assigned to this bus',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final paidCount =
        students.where((s) => s['payment_status'] == true).length;
    final unpaidCount = students.length - paidCount;

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text('Paid: $paidCount'),
                      backgroundColor: Colors.green[100],
                    ),
                    Chip(
                      label: Text('Unpaid: $unpaidCount'),
                      backgroundColor: Colors.red[100],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: students
                    .map((student) => DataRow(
                  cells: [
                    DataCell(Text(student['full_name'] ?? 'N/A')),
                    DataCell(Text(student['email'] ?? 'N/A')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: student['payment_status'] == true
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          student['payment_status'] == true
                              ? 'PAID'
                              : 'UNPAID',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: student['payment_status'] == true
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showEditDialog(student),
                      ),
                    ),
                  ],
                ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
