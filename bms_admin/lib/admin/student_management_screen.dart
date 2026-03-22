import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final StudentService _studentService = StudentService();
  
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String? _errorMessage;
  TextEditingController _searchController = TextEditingController();

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
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _students
          .where((student) =>
              student.fullName.toLowerCase().contains(query) ||
              student.email.toLowerCase().contains(query))
          .toList();
    });
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddStudentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Student'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search students by name or email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(child: Text(_errorMessage!)),
            )
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
              child: Card(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;
                    
                    if (isSmallScreen) {
                      // Mobile: Card-based list
                      return SingleChildScrollView(
                        child: Column(
                          children: _filteredStudents
                              .map((student) => Padding(
                            padding: const EdgeInsets.all(8),
                            child: _buildStudentCard(student),
                          ))
                              .toList(),
                        ),
                      );
                    } else {
                      // Desktop: DataTable
                      return SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Course')),
                            DataColumn(label: Text('Semester')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _filteredStudents.map((student) {
                            return DataRow(
                              cells: [
                                DataCell(Text(student.fullName)),
                                DataCell(Text(student.email)),
                                DataCell(Text(student.course ?? 'N/A')),
                                DataCell(Text(student.semester?.toString() ?? 'N/A')),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () =>
                                            _showEditStudentDialog(student),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () =>
                                            _showDeleteConfirmation(student),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    }
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _showEditStudentDialog(student),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      color: Colors.red,
                      onPressed: () => _showDeleteConfirmation(student),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Email: ${student.email}', style: const TextStyle(fontSize: 12)),
            Text('Course: ${student.course ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
            Text('Semester: ${student.semester ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
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
        content: Text(
          'Are you sure you want to delete ${student.fullName}?',
        ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.student?.fullName ?? '',
    );
    _emailController = TextEditingController(
      text: widget.student?.email ?? '',
    );
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
        id: widget.student?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
              '${widget.student != null ? "Updated" : "Added"} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
              decoration: const InputDecoration(
                labelText: 'Full Name *',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(
                labelText: 'Course',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _semester,
              onChanged: (value) => setState(() => _semester = value),
              decoration: const InputDecoration(labelText: 'Semester'),
              items: List.generate(8, (i) => i + 1)
                  .map((semester) => DropdownMenuItem(
                    value: semester,
                    child: Text('Semester $semester'),
                  ))
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
