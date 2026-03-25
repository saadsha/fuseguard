import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/fault.dart';

class FaultService {
  final String baseUrl = Config.apiUrl;

  Future<List<Fault>> getFaults() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/faults'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Fault>.from(l.map((model) => Fault.fromJson(model)));
    } else {
      throw Exception('Failed to load fault history. Status: ${response.statusCode}');
    }
  }

  Future<bool> resolveFault(String faultId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/faults/$faultId/resolve'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }
}
