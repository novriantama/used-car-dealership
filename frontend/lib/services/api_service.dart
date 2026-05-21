import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/vehicle.dart';
import '../models/transaction.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      final baseUri = Uri.parse(Uri.base.toString());
      final host = baseUri.host.isEmpty ? 'localhost' : baseUri.host;
      // If running in local Flutter dev server (random port), point directly to backend exposed on 8080.
      // Otherwise, point to the current host and port (which is port 8000 in Docker and mapped to Nginx's proxy).
      if (baseUri.port != 8000 && baseUri.port != 80) {
        return 'http://$host:8080/api';
      }
      return 'http://$host:${baseUri.port}/api';
    }
    return 'http://10.0.2.2:8080/api'; // Android emulator fallback to dev port 8080
  }

  // Fetch all vehicles with optional filters
  static Future<Map<String, dynamic>> getVehicles({
    String search = '',
    String make = '',
    String model = '',
    String transmission = '',
    String plateType = '',
    String taxStatus = '',
    int? priceMin,
    int? priceMax,
    int? yearMin,
    int? yearMax,
    int page = 1,
    int limit = 12,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search.isNotEmpty) queryParams['search'] = search;
    if (make.isNotEmpty) queryParams['make'] = make;
    if (model.isNotEmpty) queryParams['model'] = model;
    if (transmission.isNotEmpty) queryParams['transmission'] = transmission;
    if (plateType.isNotEmpty) queryParams['plate_type'] = plateType;
    if (taxStatus.isNotEmpty) queryParams['tax_status'] = taxStatus;
    if (priceMin != null) queryParams['price_min'] = priceMin.toString();
    if (priceMax != null) queryParams['price_max'] = priceMax.toString();
    if (yearMin != null) queryParams['year_min'] = yearMin.toString();
    if (yearMax != null) queryParams['year_max'] = yearMax.toString();

    final uri = Uri.parse('$baseUrl/vehicles').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];
        final List<Vehicle> list = data.map((json) => Vehicle.fromJson(json)).toList();
        return {
          'vehicles': list,
          'total': decoded['total'] ?? 0,
          'page': decoded['page'] ?? 1,
          'limit': decoded['limit'] ?? 12,
        };
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Fetch a single vehicle by ID
  static Future<Vehicle> getVehicleByID(int id) async {
    final uri = Uri.parse('$baseUrl/vehicles/$id');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return Vehicle.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load vehicle details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Admin Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final uri = Uri.parse('$baseUrl/admin/login');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body); // Contains "token" and "name"
      } else {
        final decoded = json.decode(response.body);
        throw Exception(decoded['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Authentication error: $e');
    }
  }

  // Create Vehicle listing (Protected)
  static Future<Vehicle> createVehicle(Vehicle vehicle, String token) async {
    final uri = Uri.parse('$baseUrl/vehicles');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(vehicle.toJson()),
      );

      if (response.statusCode == 201) {
        return Vehicle.fromJson(json.decode(response.body));
      } else {
        final decoded = json.decode(response.body);
        throw Exception(decoded['error'] ?? 'Failed to create listing');
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }

  // Update Vehicle listing (Protected)
  static Future<Vehicle> updateVehicle(Vehicle vehicle, String token) async {
    final uri = Uri.parse('$baseUrl/vehicles/${vehicle.id}');
    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(vehicle.toJson()),
      );

      if (response.statusCode == 200) {
        return Vehicle.fromJson(json.decode(response.body));
      } else {
        final decoded = json.decode(response.body);
        throw Exception(decoded['error'] ?? 'Failed to update listing');
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }

  // Delete Vehicle listing (Protected)
  static Future<void> deleteVehicle(int id, String token) async {
    final uri = Uri.parse('$baseUrl/vehicles/$id');
    try {
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final decoded = json.decode(response.body);
        throw Exception(decoded['error'] ?? 'Failed to delete listing');
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }

  // --- POS / Transactions ---

  // Create a new sale transaction (Protected)
  static Future<Transaction> createTransaction(
      Map<String, dynamic> data, String token) async {
    final uri = Uri.parse('$baseUrl/transactions');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      if (response.statusCode == 201) {
        return Transaction.fromJson(json.decode(response.body));
      } else {
        final decoded = json.decode(response.body);
        throw Exception(decoded['error'] ?? 'Failed to create transaction');
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }

  // Get all transactions (Protected)
  static Future<Map<String, dynamic>> getTransactions(
    String token, {
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];
        return {
          'transactions':
              data.map((j) => Transaction.fromJson(j)).toList(),
          'total': decoded['total'] ?? 0,
        };
      } else {
        final decoded = json.decode(response.body);
        throw Exception(decoded['error'] ?? 'Failed to fetch transactions');
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }

  // Get a single transaction by ID (Protected)
  static Future<Transaction> getTransactionById(
      int id, String token) async {
    final uri = Uri.parse('$baseUrl/transactions/$id');
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return Transaction.fromJson(json.decode(response.body));
      } else {
        final decoded = json.decode(response.body);
        throw Exception(decoded['error'] ?? 'Transaction not found');
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }

  // Upload multiple images (Protected)
  static Future<List<String>> uploadImages(
      List<PlatformFile> files, String token) async {
    final uri = Uri.parse('$baseUrl/upload');
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      for (final file in files) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              file.bytes!,
              filename: file.name,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> urls = decoded['urls'] ?? [];
        return urls.cast<String>();
      } else {
        final decoded = json.decode(response.body);
        throw Exception(decoded['error'] ?? 'Failed to upload images');
      }
    } catch (e) {
      throw Exception('API error: $e');
    }
  }

  // Resolve relative local image paths to absolute API backend URLs
  static String getImageUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    final apiBase = baseUrl;
    final origin = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;
    return '$origin$url';
  }
}
