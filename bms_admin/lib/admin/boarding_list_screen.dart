import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../models/student_model.dart';
import '../models/stop_model.dart';

class BoardingListScreen extends StatefulWidget {
  const BoardingListScreen({super.key});

  @override
  State<BoardingListScreen> createState() => _BoardingListScreenState();
}

class _BoardingListScreenState extends State<BoardingListScreen> {
  final StudentService _studentService = StudentService();
  List<Stop> _stops = [];
  Map<String, List<Student>> _stopStudents = {};
  String? _selectedStopId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    setState(() => _isLoading = true);
    try {
      // Mock stops data - replace with actual API call when available
      setState(() {
        _stops = [
          Stop(
            id: 1,
            stopName: 'Central Station',
            feeAmount: 500,
            arrivalTime: '08:00',
            actualBusId: null,
            latitude: null,
            longitude: null,
          ),
          Stop(
            id: 2,
            stopName: 'West Terminal',
            feeAmount: 600,
            arrivalTime: '08:30',
            actualBusId: null,
            latitude: null,
            longitude: null,
          ),
          Stop(
            id: 3,
            stopName: 'East Plaza',
            feeAmount: 550,
            arrivalTime: '09:00',
            actualBusId: null,
            latitude: null,
            longitude: null,
          ),
        ];
      });
    } catch (e) {
      _showError('Error loading stops: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentsForStop(String stopId) async {
    if (_stopStudents.containsKey(stopId)) return;

    try {
      final students = await _studentService.getStudentsByBoardingStop(stopId);
      setState(() {
        _stopStudents[stopId] = students;
      });
    } catch (e) {
      _showError('Error loading students: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
            'Boarding Stops & Students',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;
                  final panelWidth = isSmallScreen
                      ? constraints.maxWidth * 0.4
                      : 280.0;

                  if (isSmallScreen) {
                    // Mobile: Stacked vertically
                    return Column(
                      children: [
                        Expanded(
                          flex: 35,
                          child: _buildStopsPanel(panelWidth),
                        ),
                        const Divider(height: 24),
                        Expanded(
                          flex: 65,
                          child: _buildStudentsPanel(),
                        ),
                      ],
                    );
                  } else {
                    // Desktop: Side by side
                    return Row(
                      children: [
                        SizedBox(
                          width: panelWidth,
                          child: _buildStopsPanel(panelWidth),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStudentsPanel(),
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

  Widget _buildStopsPanel(double width) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Boarding Stops',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _stops.length,
              itemBuilder: (context, index) {
                final stop = _stops[index];
                final isSelected = _selectedStopId == stop.id.toString();

                return Material(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedStopId = stop.id.toString());
                      _loadStudentsForStop(stop.id.toString());
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
                            stop.stopName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Fee: \$${stop.feeAmount}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Time: ${stop.arrivalTime}',
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

  Widget _buildStudentsPanel() {
    return _selectedStopId == null
        ? const Center(child: Text('Select a stop to view students'))
        : _buildStudentList();
  }

  Widget _buildStudentList() {
    final students = _stopStudents[_selectedStopId] ?? [];

    if (students.isEmpty) {
      return Center(
        child: Text(
          'No students for this stop',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final selectedStop = _stops.firstWhere(
      (s) => s.id.toString() == _selectedStopId,
      orElse: () => _stops.first,
    );

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStop.stopName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    Text('Fee: \$${selectedStop.feeAmount}'),
                    Text('Time: ${selectedStop.arrivalTime}'),
                    Text('Students: ${students.length}'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Course')),
                  DataColumn(label: Text('Contact')),
                ],
                rows: students
                    .map((student) => DataRow(
                  cells: [
                    DataCell(Text(student.fullName)),
                    DataCell(Text(student.email)),
                    DataCell(Text(student.course ?? '')),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.phone, size: 18),
                        onPressed: () {
                          _showError('Contact feature coming soon');
                        },
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
