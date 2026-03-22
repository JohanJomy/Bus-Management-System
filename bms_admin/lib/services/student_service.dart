import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/student_model.dart';
import '../models/payment_model.dart';
import '../config/supabase_config.dart';

class StudentService {
  static const String baseUrl = '${SupabaseConfig.projectUrl}/rest/v1';

  /// Retrieves all students
  Future<List<Student>> getAllStudents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students'),
        headers: SupabaseConfig.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((student) => Student.fromJson(student)).toList();
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching students: $e');
    }
  }

  /// Gets a specific student by ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students?id=eq.$studentId'),
        headers: SupabaseConfig.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.isNotEmpty ? Student.fromJson(data[0]) : null;
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching student: $e');
    }
  }

  /// Gets all students with their payment information
  Future<List<Map<String, dynamic>>> getAllStudentsWithPayments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students?select=*,payments(*)'),
        headers: SupabaseConfig.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load students with payments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching students with payments: $e');
    }
  }

  /// Gets students by boarding stop
  Future<List<Student>> getStudentsByBoardingStop(String stopId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students?boarding_stop_id=eq.$stopId'),
        headers: SupabaseConfig.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((student) => Student.fromJson(student)).toList();
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching students by stop: $e');
    }
  }

  /// Updates a student
  Future<Student> updateStudent(Student student) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/students?id=eq.${student.id}'),
        headers: SupabaseConfig.getHeaders(),
        body: jsonEncode(student.toJson()),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return Student.fromJson(data[0]);
      } else {
        throw Exception('Failed to update student: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating student: $e');
    }
  }

  /// Adds a new student
  Future<Student> addStudent(Student student) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/students'),
        headers: SupabaseConfig.getHeaders(),
        body: jsonEncode(student.toJson()),
      );
      
      if (response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return Student.fromJson(data[0]);
      } else {
        throw Exception('Failed to add student: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding student: $e');
    }
  }

  /// Deletes a student by ID
  Future<void> deleteStudent(String studentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/students?id=eq.$studentId'),
        headers: SupabaseConfig.getHeaders(),
      );
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete student: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting student: $e');
    }
  }

  /// Gets all payments for a student
  Future<List<Payment>> getStudentPayments(String studentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments?student_id=eq.$studentId'),
        headers: SupabaseConfig.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((payment) => Payment.fromJson(payment)).toList();
      } else {
        throw Exception('Failed to load payments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching payments: $e');
    }
  }

  /// Gets students who have paid fees
  Future<List<Student>> getStudentsWithPaidFees() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students?select=*,payments(*)'),
        headers: SupabaseConfig.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final students = data.map((student) => Student.fromJson(student)).toList();
        // Filter students with paid fees
        return students.where((student) => (student.toJson()['payments'] as List?)?.isNotEmpty ?? false).toList();
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching students with paid fees: $e');
    }
  }

  /// Gets students who have NOT paid fees
  Future<List<Student>> getStudentsWithUnpaidFees() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students?select=*,payments(*)'),
        headers: SupabaseConfig.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final students = data.map((student) => Student.fromJson(student)).toList();
        // Filter students without paid fees
        return students.where((student) => (student.toJson()['payments'] as List?)?.isEmpty ?? true).toList();
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching students with unpaid fees: $e');
    }
  }

  /// Search students by name or email
  Future<List<Student>> searchStudents(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/students?or=(full_name.ilike.%$query%,email.ilike.%$query%)'),
        headers: SupabaseConfig.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((student) => Student.fromJson(student)).toList();
      } else {
        throw Exception('Failed to search students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching students: $e');
    }
  }
}
