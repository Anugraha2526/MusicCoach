import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/instrument_item.dart';
import '../config/api_config.dart';

class InstrumentService {
  // Fetch all instruments from the API
  static Future<List<InstrumentItem>> fetchInstruments() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.instruments),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => InstrumentItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load instruments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching instruments: $e');
    }
  }

  // Fetch a single instrument by ID
  static Future<InstrumentItem?> fetchInstrumentById(int id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.instrumentById(id)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return InstrumentItem.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

