import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/transformer.dart';

class TransformerService {
  final String baseUrl = '${Config.apiUrl}/transformers';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Transformer>> getTransformers() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Transformer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transformers');
    }
  }

  Future<Transformer> createTransformer(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return Transformer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create transformer: ${response.body}');
    }
  }

  Future<void> deleteTransformer(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete transformer: ${response.body}');
    }
  }

  Future<Transformer> updateTransformer(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Transformer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update transformer: ${response.body}');
    }
  }
}
