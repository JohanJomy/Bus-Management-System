import 'dart:math';

import 'package:flutter/material.dart';

import '../models/stop_model.dart';
import '../models/student_model.dart';
import '../services/bus_service.dart';
import '../services/student_service.dart';

class BoardingListScreen extends StatefulWidget {
  const BoardingListScreen({super.key});

  @override
  State<BoardingListScreen> createState() => _BoardingListScreenState();
}

class _BoardingListScreenState extends State<BoardingListScreen> {
  final StudentService _studentService = StudentService();
  final BusService _busService = BusService();
  final TextEditingController _searchController = TextEditingController();

  List<Stop> _stops = [];
  final Map<int, List<Student>> _stopStudents = {};
  String _stopSearchQuery = '';

  int? _selectedStopId;
  bool _isLoading = true;

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

  Future<void> _loadStops() async {
    setState(() => _isLoading = true);
    try {
      final stops = await _busService.getAllStops();
      setState(() {
        _stops = stops;
        if (_selectedStopId == null && stops.isNotEmpty) {
          _selectedStopId = stops.first.id;
        }
      });

      if (_selectedStopId != null) {
        await _loadStudentsForStop(_selectedStopId!);
      }
    } catch (e) {
      _showMessage('Error loading stops: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStudentsForStop(int stopId) async {
    try {
      final students = await _studentService.getStudentsByBoardingStop(
        stopId.toString(),
      );
      if (mounted) {
        setState(() {
          _stopStudents[stopId] = students;
        });
      }
    } catch (e) {
      _showMessage('Error loading students: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatCurrency(double value) {
    final number = value.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      if (i != 0 && (number.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(number[i]);
    }
    return '₹ ${buffer.toString()}';
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'NA';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  List<Stop> get _filteredStops {
    final query = _stopSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _stops;
    }
    return _stops
        .where((stop) => stop.stopName.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _onStopSearchChanged(String value) async {
    final query = value.trim().toLowerCase();
    final matches = query.isEmpty
        ? _stops
        : _stops
              .where((stop) => stop.stopName.toLowerCase().contains(query))
              .toList();

    final shouldSelectFirst =
        matches.isNotEmpty && !matches.any((s) => s.id == _selectedStopId);
    final nextSelectedId = shouldSelectFirst
        ? matches.first.id
        : _selectedStopId;

    if (mounted) {
      setState(() {
        _stopSearchQuery = value;
        _selectedStopId = nextSelectedId;
      });
    }

    if (shouldSelectFirst && nextSelectedId != null) {
      await _loadStudentsForStop(nextSelectedId);
    }
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hexByte(int value) => value.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(hexByte).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  Future<void> _showAddStudentDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final courseController = TextEditingController();
    final semesterController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Student'),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Email is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: courseController,
                  decoration: const InputDecoration(labelText: 'Course'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: semesterController,
                  decoration: const InputDecoration(
                    labelText: 'Semester (optional)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
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
              if (!formKey.currentState!.validate() ||
                  _selectedStopId == null) {
                return;
              }

              try {
                final newStudent = Student(
                  id: _generateUuidV4(),
                  fullName: nameController.text.trim(),
                  email: emailController.text.trim(),
                  course: courseController.text.trim().isEmpty
                      ? null
                      : courseController.text.trim(),
                  semester: semesterController.text.trim().isEmpty
                      ? null
                      : int.tryParse(semesterController.text.trim()),
                  boardingStopId: _selectedStopId,
                );

                await _studentService.addStudent(newStudent);

                if (mounted) {
                  Navigator.pop(ctx);
                  await _loadStudentsForStop(_selectedStopId!);
                  _showMessage('Student added successfully');
                }
              } catch (e) {
                _showMessage('Error adding student: $e');
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Student student) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to delete ${student.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _studentService.deleteStudent(student.id);
                if (mounted) {
                  Navigator.pop(ctx);
                  if (_selectedStopId != null) {
                    await _loadStudentsForStop(_selectedStopId!);
                  }
                  _showMessage('Student deleted successfully');
                }
              } catch (e) {
                _showMessage('Error deleting student: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      color: theme.scaffoldBackgroundColor,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 960;
                final leftPane = _buildStopsPanel(isDark);
                final rightPane = _buildStudentsPanel(isDark);

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopBar(isCompact: true, isDark: isDark),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(height: 270, child: leftPane),
                            const SizedBox(height: 12),
                            Expanded(child: rightPane),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(isCompact: false, isDark: isDark),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(width: 340, child: leftPane),
                          const SizedBox(width: 14),
                          Expanded(child: rightPane),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTopBar({required bool isCompact, required bool isDark}) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.45 : 0.8);

    final title = Text(
      'Boarding Stops',
      style: theme.textTheme.headlineMedium?.copyWith(
        fontSize: 52,
        fontWeight: FontWeight.w700,
      ),
    );

    final search = SizedBox(
      height: 46,
      child: TextField(
        controller: _searchController,
        onChanged: _onStopSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search stop by name...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E2735) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
        ),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 10), search],
      );
    }

    return Row(
      children: [
        title,
        const SizedBox(width: 16),
        Expanded(child: search),
      ],
    );
  }

  Widget _buildStopsPanel(bool isDark) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.4 : 0.85);
    final panelColor = isDark ? const Color(0xFF121B28) : Colors.white;
    final cardColor = isDark
        ? const Color(0xFF1A2636)
        : const Color(0xFFF8FAFD);
    final selectedCard = isDark
        ? const Color(0xFF223450)
        : const Color(0xFFF2F7FF);

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'ALL STOPS',
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.1,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: _filteredStops.isEmpty
                ? Center(
                    child: Text(
                      'No stops found for "${_stopSearchQuery.trim()}"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.75,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    itemCount: _filteredStops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final stop = _filteredStops[index];
                      final isSelected = _selectedStopId == stop.id;
                      final studentCount = _stopStudents[stop.id]?.length;

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() => _selectedStopId = stop.id);
                          _loadStudentsForStop(stop.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? selectedCard : cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3E7CF0)
                                  : borderColor.withOpacity(0.8),
                              width: isSelected ? 1.4 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      stop.stopName.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: isSelected
                                            ? const Color(0xFF4F8EFF)
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(stop.feeAmount),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _metaChip(
                                    icon: Icons.access_time_rounded,
                                    text: stop.arrivalTime ?? '--:--',
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8),
                                  _metaChip(
                                    icon: Icons.groups_2_outlined,
                                    text: '${studentCount ?? '--'} Students',
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
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

  Widget _metaChip({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF273345) : const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.85),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsPanel(bool isDark) {
    final hasSelectedStop =
        _selectedStopId != null &&
        _filteredStops.any((s) => s.id == _selectedStopId);
    return !hasSelectedStop
        ? const Center(child: Text('Select a stop to view students'))
        : _buildStudentList(isDark);
  }

  Widget _buildStudentList(bool isDark) {
    final theme = Theme.of(context);
    final students = _stopStudents[_selectedStopId] ?? [];
    final selectedStop = _stops.firstWhere(
      (s) => s.id == _selectedStopId,
      orElse: () => _stops.first,
    );

    final isNarrow = MediaQuery.of(context).size.width < 1240;
    final headingFontSize = isNarrow ? 30.0 : 40.0;
    final subheadingFontSize = isNarrow ? 14.0 : 16.0;

    final panelColor = isDark ? const Color(0xFF121B28) : Colors.white;
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.4 : 0.85);
    final rowHeaderBg = isDark
        ? const Color(0xFF1A2636)
        : const Color(0xFFF7F9FC);

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stackActions = constraints.maxWidth < 980;

                final infoBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BOARDING DIRECTORY',
                      style: TextStyle(
                        letterSpacing: 1.2,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4C87F0),
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: headingFontSize,
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.08,
                        ),
                        children: [
                          const TextSpan(text: 'Students at\n'),
                          TextSpan(
                            text: selectedStop.stopName,
                            style: const TextStyle(color: Color(0xFF3E7CF0)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage and view all students currently assigned to this boarding point.',
                      style: TextStyle(
                        fontSize: subheadingFontSize,
                        height: 1.35,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.75,
                        ),
                      ),
                    ),
                  ],
                );

                final actionsBlock = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _actionButton(
                      icon: Icons.ios_share_outlined,
                      label: 'Export List',
                      outlined: true,
                      onPressed: () {},
                    ),
                    _actionButton(
                      icon: Icons.add,
                      label: 'Add Student',
                      outlined: false,
                      onPressed: _showAddStudentDialog,
                    ),
                  ],
                );

                if (stackActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      infoBlock,
                      const SizedBox(height: 14),
                      actionsBlock,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: infoBlock),
                    const SizedBox(width: 12),
                    actionsBlock,
                  ],
                );
              },
            ),
          ),
          Divider(height: 1, color: borderColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            color: rowHeaderBg,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  SizedBox(
                    width: 300,
                    child: Text(
                      'STUDENT\nIDENTIFICATION',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.75,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: Text(
                      'CONTACT EMAIL',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.75,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 230,
                    child: Text(
                      'ACADEMIC\nCOURSE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.75,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: Text(
                      'ACTIONS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.75,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? Center(
                    child: Text(
                      'No students for this stop',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.75,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: borderColor),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 300,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isDark
                                          ? const Color(0xFF273A55)
                                          : const Color(0xFFE4EEFF),
                                      child: Text(
                                        _initials(student.fullName),
                                        style: const TextStyle(
                                          color: Color(0xFF3E7CF0),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.fullName.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'ID: ${student.id.substring(0, student.id.length > 8 ? 8 : student.id.length)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.8),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 220,
                                child: Text(
                                  student.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.85),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 230,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF233248)
                                        : const Color(0xFFEFF3F8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    student.course?.isNotEmpty == true
                                        ? student.course!
                                        : 'Not Assigned',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.88),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 78,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.call,
                                        size: 18,
                                        color: theme.iconTheme.color
                                            ?.withOpacity(0.85),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 0,
                                        minHeight: 0,
                                      ),
                                      onPressed: () {
                                        _showMessage(
                                          'Contact feature coming soon',
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.redAccent,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 0,
                                        minHeight: 0,
                                      ),
                                      onPressed: () =>
                                          _showDeleteConfirmation(student),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Text(
              'SHOWING ${students.length} STUDENTS AT ${selectedStop.stopName.toUpperCase()}',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool outlined,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = outlined
        ? (isDark ? const Color(0xFF1C2838) : const Color(0xFFF2F5FA))
        : const Color(0xFF2D6EEA);
    final fg = outlined ? theme.colorScheme.onSurface : Colors.white;
    final border = outlined
        ? theme.dividerColor.withOpacity(isDark ? 0.45 : 0.8)
        : bg;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, color: fg, size: 16),
        label: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
