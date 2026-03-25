import 'dart:math';
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';
import 'app_theme.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  static const int _pageSize = 10;

  final StudentService _studentService = StudentService();
  final TextEditingController _searchController = TextEditingController();

  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  Map<String, bool> _studentPaymentStatus = {};
  int _visibleCount = _pageSize;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _studentService.getAllStudents();
      students.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

      // Load payment status from payments table (joined per student)
      final studentsWithPayments =
          await _studentService.getAllStudentsWithPayments();

      final Map<String, bool> studentPaymentStatus = {};
      for (final studentData in studentsWithPayments) {
        final studentId = studentData['id']?.toString();
        final semester = _asInt(studentData['semester']);
        final payments = studentData['payments'];

        if (studentId != null && semester != null) {
          final key = '$studentId|$semester';
          final paymentRows = payments is List ? payments : const <dynamic>[];
          var paidInSemester = false;

          for (final payment in paymentRows) {
            if (payment is! Map) {
              continue;
            }

            final paymentMap = payment.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            final paymentSemester = _asInt(paymentMap['semester']);
            final isPaid = paymentMap['status'] == true;

            if (isPaid && paymentSemester == semester) {
              paidInSemester = true;
              break;
            }
          }

          studentPaymentStatus[key] = paidInSemester;
        }
      }

      setState(() {
        _students = students;
        _filteredStudents = students;
        _studentPaymentStatus = studentPaymentStatus;
        _visibleCount = _pageSize;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load students');
      _showError('Error loading students: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase().trim();
    final filtered = _students
        .where(
          (student) =>
              student.fullName.toLowerCase().contains(query) ||
              student.email.toLowerCase().contains(query),
        )
        .toList();

    setState(() {
      _filteredStudents = filtered;
      _visibleCount = _pageSize;
    });
  }

  List<Student> get _visibleStudents => _filteredStudents.take(_visibleCount).toList();

  bool get _hasMoreStudents => _visibleStudents.length < _filteredStudents.length;

  void _loadMoreStudents() {
    setState(() => _visibleCount += _pageSize);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'NA';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  Color _courseChipColor(BuildContext context, String? course) {
    final c = (course ?? '').toLowerCase();
    if (c.contains('robotics') || c.contains('automation')) {
      return Theme.of(context).primaryColor.withValues(alpha: 0.1);
    }
    if (c.contains('computer') || c.contains('engineering')) {
      return Theme.of(context).primaryColor.withValues(alpha: 0.15);
    }
    if (c.contains('food') || c.contains('technology')) {
      return Theme.of(context).primaryColor.withValues(alpha: 0.2);
    }
    return inputFillColor(context);
  }

  bool _hasPaid(Student student) {
    if (student.semester == null) {
      return false;
    }
    final key = '${student.id}|${student.semester}';
    return _studentPaymentStatus[key] ?? false;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final visibleStudents = _visibleStudents;
    final hasMoreStudents = _hasMoreStudents;

    return Container(
      color: bgColor(context),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Student Management',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: onSurface(context),
                ),
              ),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _showAddStudentDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Expanded(child: Center(child: Text(_errorMessage!)))
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark(context) ? 0.0 : 0.02,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 760;

                    if (isSmallScreen) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Active Student Directory',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: onSurface(context),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${visibleStudents.length}/${_filteredStudents.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: onSurfaceVariant(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: _filteredStudents.isEmpty
                                ? Center(
                                    child: Text(
                                      'No students found',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: visibleStudents.length,
                                          itemBuilder: (context, index) => Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: _buildStudentCard(
                                              visibleStudents[index],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (hasMoreStudents)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            0,
                                            12,
                                            12,
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: _loadMoreStudents,
                                              icon: const Icon(
                                                Icons.expand_more,
                                                size: 18,
                                              ),
                                              label: const Text('Load More'),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Active Student Directory',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: onSurface(context),
                                  ),
                                ),
                              ),
                              Text(
                                '${visibleStudents.length}/${_filteredStudents.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: onSurfaceVariant(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search students by name or email...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: inputFillColor(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: borderColor(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: borderColor(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, tableConstraints) {
                              final tableWidth = tableConstraints.maxWidth < 1180
                                  ? 1180.0
                                  : tableConstraints.maxWidth;

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: tableWidth,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Student',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: onSurfaceVariant(context),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Email',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: onSurfaceVariant(context),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Course',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: onSurfaceVariant(context),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Semester',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: onSurfaceVariant(context),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Status',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: onSurfaceVariant(context),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Divider(height: 1),
                                      Expanded(
                                        child: _filteredStudents.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No students found',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge,
                                                ),
                                              )
                                            : Column(
                                                children: [
                                                  Expanded(
                                                    child: ListView.separated(
                                                      itemCount:
                                                          visibleStudents.length,
                                                      separatorBuilder: (_, __) =>
                                                          const Divider(height: 1),
                                                      itemBuilder: (context, index) =>
                                                          Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 11,
                                                        ),
                                                        child: _buildDesktopStudentRow(
                                                          visibleStudents[index],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (hasMoreStudents)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.fromLTRB(
                                                        20,
                                                        0,
                                                        20,
                                                        14,
                                                      ),
                                                      child: SizedBox(
                                                        width: double.infinity,
                                                        child: OutlinedButton.icon(
                                                          onPressed: _loadMoreStudents,
                                                          icon: const Icon(
                                                            Icons.expand_more,
                                                            size: 18,
                                                          ),
                                                          label: const Text('Load More'),
                                                        ),
                                                      ),
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
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopStudentRow(Student student) {
    final sem = student.semester ?? 0;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                child: Text(
                  _initials(student.fullName),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  student.fullName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onSurface(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            student.email,
            style: TextStyle(fontSize: 13, color: onSurfaceVariant(context)),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 7, 34, 7),
            decoration: BoxDecoration(
              color: _courseChipColor(context, student.course),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              student.course?.isNotEmpty == true ? student.course! : 'N/A',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onSurface(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              sem > 0 ? 'S$sem' : 'N/A',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: onSurface(context),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _hasPaid(student)
                    ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                    : const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _hasPaid(student) ? 'Paid' : 'Pending',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _hasPaid(student)
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEF4444),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: onSurfaceVariant(context),
                ),
                tooltip: 'Edit student',
                onPressed: () => _showEditStudentDialog(student),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
                tooltip: 'Delete student',
                onPressed: () => _showDeleteConfirmation(student),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student student) {
    return Card(
      color: surfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    student.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: onSurface(context),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 18,
                        color: onSurfaceVariant(context),
                      ),
                      onPressed: () => _showEditStudentDialog(student),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _showDeleteConfirmation(student),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${student.email}',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant(context)),
            ),
            Text(
              'Course: ${student.course ?? 'N/A'}',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant(context)),
            ),
            Text(
              'Semester: ${student.semester ?? 'N/A'}',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => _StudentEditDialog(
        studentService: _studentService,
        onSave: _loadStudents,
      ),
    );
  }

  void _showEditStudentDialog(Student student) {
    showDialog(
      context: context,
      builder: (context) => _StudentEditDialog(
        student: student,
        studentService: _studentService,
        onSave: _loadStudents,
      ),
    );
  }

  void _showDeleteConfirmation(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _studentService.deleteStudent(student.id);
                if (mounted) {
                  Navigator.pop(context);
                  _loadStudents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StudentEditDialog extends StatefulWidget {
  final Student? student;
  final StudentService studentService;
  final VoidCallback onSave;

  const _StudentEditDialog({
    this.student,
    required this.studentService,
    required this.onSave,
  });

  @override
  State<_StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends State<_StudentEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _courseController;
  int? _semester;
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.student?.fullName ?? '',
    );
    _emailController = TextEditingController(text: widget.student?.email ?? '');
    _courseController = TextEditingController(
      text: widget.student?.course ?? '',
    );
    _semester = widget.student?.semester;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final student = Student(
        id: widget.student?.id ?? _generateUuidV4(),
        fullName: _nameController.text,
        email: _emailController.text,
        course: _courseController.text,
        semester: _semester,
      );

      if (widget.student != null) {
        await widget.studentService.updateStudent(student);
      } else {
        await widget.studentService.addStudent(student);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.student != null ? 'Updated' : 'Added'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.student != null ? 'Edit Student' : 'Add Student'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: 'Course'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _semester,
              onChanged: (value) => setState(() => _semester = value),
              decoration: const InputDecoration(labelText: 'Semester'),
              items: List.generate(8, (i) => i + 1)
                  .map(
                    (semester) => DropdownMenuItem(
                      value: semester,
                      child: Text('Semester $semester'),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.student != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
