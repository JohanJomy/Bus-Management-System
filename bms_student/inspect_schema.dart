import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient('https://lnssskyfwshwextaecdx.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxuc3Nza3lmd3Nod2V4dGFlY2R4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MDkwNTksImV4cCI6MjA4ODE4NTA1OX0.80dphTCVyBmPCQW-taGVfXuERaOu06R1mlFMZ80FjeM');

  try {
    // Fetch one student record to see all columns
    final response = await client.from('students').select().limit(1);
    if (response != null && (response as List).isNotEmpty) {
      print('Columns in students table: ${(response[0] as Map).keys}');
      print('First row data: ${response[0]}');
    } else {
      print('No students found.');
    }
  } catch (e) {
    print('Error: $e');
  }
}
