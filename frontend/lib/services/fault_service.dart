import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class Fault {
  final String id;
  final String transformerId;
  final String transformerName;
  final String location;
  final String fuseId;
  final String faultType;
  final String status;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  Fault({
    required this.id,
    required this.transformerId,
    required this.transformerName,
    required this.location,
    required this.fuseId,
    required this.faultType,
    required this.status,
    required this.detectedAt,
    this.resolvedAt,
  });

  factory Fault.fromJson(Map<String, dynamic> json) {
    return Fault(
      id: json['_id'] ?? '',
      transformerId: json['transformerId']['_id'] ?? '',
      transformerName: json['transformerId']['transformerId'] ?? 'Unknown',
      location: json['transformerId']['location'] ?? 'Unknown location',
      fuseId: json['fuseId'] ?? '',
      faultType: json['faultType'] ?? '',
      status: json['status'] ?? 'Active',
      detectedAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    );
  }
}
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
