import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/bus_model.dart';
import '../models/stop_model.dart';
import '../models/daily_manifest_model.dart';
import '../config/supabase_config.dart';

class BusService {
  static const String baseUrl = '${SupabaseConfig.projectUrl}/rest/v1';

  /// Retrieves all buses from the backend
  Future<List<Bus>> getAllBuses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buses'),
        headers: SupabaseConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((bus) => Bus.fromJson(bus)).toList();
      } else {
        throw Exception('Failed to load buses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching buses: $e');
    }
  }

  /// Gets a specific bus by ID
  Future<Bus?> getBusById(int busId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/buses?id=eq.$busId'),
        headers: SupabaseConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.isNotEmpty ? Bus.fromJson(data[0]) : null;
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching bus: $e');
    }
  }

  /// Gets all students assigned to a specific bus
  Future<List<Map<String, dynamic>>> getStudentsByBusId(int busId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/daily_manifests?allocated_bus_id=eq.$busId&select=*,students(*)',
        ),
        headers: SupabaseConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load bus students: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching bus students: $e');
    }
  }

  /// Gets students on a specific bus with payment status
  Future<List<Map<String, dynamic>>> getStudentsWithPaymentByBus(
    int busId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/daily_manifests?allocated_bus_id=eq.$busId&select=*,students(*,payments(*))',
        ),
        headers: SupabaseConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  /// Gets daily manifest for a specific bus
  Future<List<DailyManifest>> getDailyManifestByBus(int busId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily_manifests?allocated_bus_id=eq.$busId'),
        headers: SupabaseConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((manifest) => DailyManifest.fromJson(manifest))
            .toList();
      } else {
        throw Exception('Failed to load manifest: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching manifest: $e');
    }
  }

  /// Adds a new bus
  Future<Bus> addBus(int busNumber, int totalCapacity) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/buses'),
        headers: SupabaseConfig.getHeaders(),
        body: jsonEncode({
          'bus_number': busNumber,
          'total_capacity': totalCapacity,
        }),
      );

      if (response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        return Bus.fromJson(data[0]);
      } else {
        throw Exception('Failed to add bus: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding bus: $e');
    }
  }

  /// Updates an existing bus
  Future<Bus> updateBus(int busId, int busNumber, int totalCapacity) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/buses?id=eq.$busId'),
        headers: SupabaseConfig.getHeaders(),
        body: jsonEncode({
          'bus_number': busNumber,
          'total_capacity': totalCapacity,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return Bus.fromJson(data[0]);
      } else {
        throw Exception('Failed to update bus: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating bus: $e');
    }
  }

  /// Deletes a bus
  Future<void> deleteBus(int busId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/buses?id=eq.$busId'),
        headers: SupabaseConfig.getHeaders(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete bus: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting bus: $e');
    }
  }

  /// Gets all stops
  Future<List<Stop>> getAllStops() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stops'),
        headers: SupabaseConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((stop) => Stop.fromJson(stop)).toList();
      } else {
        throw Exception('Failed to load stops: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stops: $e');
    }
  }

  /// Updates stop latitude/longitude in the backend.
  Future<void> updateStopLocation(
    int stopId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/stops?id=eq.$stopId'),
        headers: SupabaseConfig.getHeaders(),
        body: jsonEncode({'lat': latitude, 'long': longitude}),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to update stop location: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating stop location: $e');
    }
  }

  /// Gets stop links (adjacency matrix) from the backend
  Future<List<Map<String, dynamic>>> getStopLinks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stop_links'),
        headers: SupabaseConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load stop links: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Adds a stop-to-stop edge in stop_links.
  Future<void> addStopLink(int fromStopId, int toStopId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stop_links'),
        headers: SupabaseConfig.getHeaders(),
        body: jsonEncode({
          'from_stop_id': fromStopId,
          'to_stop_id': toStopId,
        }),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw Exception('Failed to add stop link: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding stop link: $e');
    }
  }

  /// Deletes a stop-to-stop edge in both directions.
  Future<void> deleteStopLink(int fromStopId, int toStopId) async {
    try {
      Future<void> deleteDirected(int fromId, int toId) async {
        final response = await http.delete(
          Uri.parse(
            '$baseUrl/stop_links?from_stop_id=eq.$fromId&to_stop_id=eq.$toId',
          ),
          headers: SupabaseConfig.getHeaders(),
        );

        if (response.statusCode != 200 && response.statusCode != 204) {
          throw Exception('Failed to delete stop link: ${response.statusCode}');
        }
      }

      await deleteDirected(fromStopId, toStopId);
      await deleteDirected(toStopId, fromStopId);
    } catch (e) {
      throw Exception('Error deleting stop link: $e');
    }
  }
}
