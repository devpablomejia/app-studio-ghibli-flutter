import '../models/persona.dart';
import '../services/api_service.dart';

class PersonasController {
  final ApiService _apiService = ApiService();

  Future<List<Persona>> fetchPersonas() async {
    try {
      final List<dynamic> data = await _apiService.get('people');
      return data
          .whereType<Map<String, dynamic>>()
          .map(Persona.fromJson)
          .toList();
    } catch (e) {
      throw Exception('Error en controlador de personas: $e');
    }
  }
}