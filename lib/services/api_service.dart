import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://ghibliapi.vercel.app';

  Future<List<dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('$_baseUrl/$endpoint'));

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception(
        'Error al cargar los datos desde la api: ${response.statusCode}',
      );
    }
  }
}
