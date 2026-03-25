import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverStudentsScreen extends StatefulWidget {
  const DriverStudentsScreen({super.key});

  @override
  State<DriverStudentsScreen> createState() => _DriverStudentsScreenState();
}

class _DriverStudentsScreenState extends State<DriverStudentsScreen> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _pageSize = 10;
  List<Map<String, dynamic>> _students = [];
  List<int> _stopIds = [];
  final Map<int, String> _stopMap = {};
  String _busNumber = 'Unknown';
  int _totalSeats = 0;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
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
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final supabase = Supabase.instance.client;

      // 00. Fetch bus details
      final busData = await supabase
          .from('buses')
          .select('total_capacity, bus_number')
          .eq('id', busId)
          .maybeSingle();

      if (mounted) {
         setState(() {
            _totalSeats = busData?['total_capacity'] as int? ?? 0;
            if (busData?['bus_number'] != null) {
              _busNumber = busData!['bus_number'].toString();
            }
         });
      }

      // 1. Get all stops assigned to this bus
      final stopsResponse = await supabase
          .from('stops')
          .select('id, stop_name')
          .eq('actual_bus', busId);
      
      final stopsList = stopsResponse as List?;
      if (stopsList == null || stopsList.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      _stopIds = stopsList.map<int>((s) => s['id'] as int).toList();
      _stopMap.clear();
      for (var s in stopsList) {
        _stopMap[s['id'] as int] = s['stop_name'] as String;
      }

      await _loadMoreStudents(isInitialLoad: true);

    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreStudents({bool isInitialLoad = false}) async {
    if (_isLoadingMore) return;
    
    if (mounted) {
      setState(() {
        if (isInitialLoad) {
          _isLoading = true;
        } else {
          _isLoadingMore = true;
        }
      });
    }

    try {
      final supabase = Supabase.instance.client;
      final int from = _students.length;
      final int to = from + _pageSize - 1;

      // 2. Get students assigned to these stops with pagination
      final studentsResponse = await supabase
          .from('students')
          .select()
          .filter('boarding_stop_id', 'in', _stopIds)
          .order('full_name')
          .range(from, to);

      final studentsList = studentsResponse as List?;

      if (studentsList != null && studentsList.isNotEmpty) {
        // 3. Fetch payment status for these students
        final studentIds = studentsList.map((s) => s['id']).toList();
        
        final paymentsResponse = await supabase
            .from('payments')
            .select('student_id')
            .filter('student_id', 'in', studentIds);
            
        final paidStudentIds = (paymentsResponse as List)
            .map((p) => p['student_id'].toString())
            .toSet();

        final List<Map<String, dynamic>> newStudents = [];
        for (var student in studentsList) {
          final stopId = student['boarding_stop_id'] as int?;
          final stopName = stopId != null ? _stopMap[stopId] ?? 'Unknown Stop' : 'No Stop';
          final studentId = student['id'].toString();
          final isPaid = paidStudentIds.contains(studentId);
          
          newStudents.add({
            'name': student['full_name']?.toString() ?? 'Unknown',
            'email': student['email']?.toString() ?? '',
            'stop': stopName,
            'semester': student['semester']?.toString() ?? '-',
            'course': student['course']?.toString() ?? '-',
            'isPaid': isPaid,
          });
        }

        if (mounted) {
          setState(() {
            if (isInitialLoad) {
              _students = newStudents;
            } else {
              _students.addAll(newStudents);
            }
            // If we got fewer items than requested, we've reached the end
            _hasMore = studentsList.length == _pageSize;
          });
        }
      } else {
         if (mounted) {
          setState(() {
            _hasMore = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading more students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
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
                  const Text('Students List', style: TextStyle(fontSize: 18)),
                  Text(
                    'Bus: $_busNumber',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Seats: $_totalSeats',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No students found for Bus $_busNumber',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == _students.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: _isLoadingMore
                              ? const SizedBox(
                                  width: 24, 
                                  height: 24, 
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : ElevatedButton(
                                  onPressed: () => _loadMoreStudents(),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text('Load More Students'),
                                ),
                        ),
                      );
                    }
                    final student = _students[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        foregroundColor: Theme.of(context).primaryColor,
                        child: Text(student['name'].isNotEmpty ? student['name'][0].toUpperCase() : '?'),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              student['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (student['isPaid'] as bool? ?? false) 
                                  ? Colors.green.withValues(alpha: 0.1) 
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (student['isPaid'] as bool? ?? false) 
                                    ? Colors.green 
                                    : Colors.red,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              (student['isPaid'] as bool? ?? false) ? 'PAID' : 'UNPAID',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: (student['isPaid'] as bool? ?? false) 
                                    ? Colors.green 
                                    : Colors.red,
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
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  student['stop'],
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.school_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${student['course']} • Sem ${student['semester']}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
