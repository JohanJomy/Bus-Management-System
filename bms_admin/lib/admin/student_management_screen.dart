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
  final StudentService _studentService = StudentService();
  final TextEditingController _searchController = TextEditingController();

  List<Student> _students = [];
  List<Student> _filteredStudents = [];
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
      setState(() {
        _students = students;
        _filteredStudents = students;
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
    setState(() {
      _filteredStudents = _students
          .where(
            (student) =>
                student.fullName.toLowerCase().contains(query) ||
                student.email.toLowerCase().contains(query),
          )
          .toList();
    });
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor(context),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Management',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: onSurface(context),
                ),
              ),
              ElevatedButton.icon(
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
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Expanded(child: Center(child: Text(_errorMessage!)))
          else if (_filteredStudents.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No students found',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor(context)),
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
                            child: Text(
                              'Active Student Directory',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: onSurface(context),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
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
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.all(8),
                                child: _buildStudentCard(
                                  _filteredStudents[index],
                                ),
                              ),
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
                          child: Text(
                            'Active Student Directory',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: onSurface(context),
                            ),
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
                        const Divider(height: 1),
                        Container(
                          color: inputFillColor(context),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'NAME',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: onSurfaceVariant(context),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'EMAIL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
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
                                    letterSpacing: 0.8,
                                    color: onSurfaceVariant(context),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'SEMESTER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
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
                                    letterSpacing: 0.8,
                                    color: onSurfaceVariant(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _filteredStudents.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              final sem = student.semester ?? 0;
                              final semProgress = sem <= 0
                                  ? 0.0
                                  : (sem.clamp(1, 8) / 8);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 11,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.1),
                                            child: Text(
                                              _initials(student.fullName),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
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
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: onSurfaceVariant(context),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _courseChipColor(
                                            context,
                                            student.course,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          student.course?.isNotEmpty == true
                                              ? student.course!
                                              : 'N/A',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: onSurface(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Semester ${student.semester ?? 'N/A'}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: onSurface(context),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            height: 3,
                                            width: 80,
                                            decoration: BoxDecoration(
                                              color: inputFillColor(context),
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: semProgress,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(99),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              size: 18,
                                              color: onSurfaceVariant(context),
                                            ),
                                            onPressed: () =>
                                                _showEditStudentDialog(student),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                            ),
                                            onPressed: () =>
                                                _showDeleteConfirmation(
                                                  student,
                                                ),
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
