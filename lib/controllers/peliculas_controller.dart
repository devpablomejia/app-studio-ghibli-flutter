import '../models/pelicula.dart';
import '../services/api_service.dart';

class PeliculaController {
  final ApiService _apiService = ApiService();

  Future<List<Pelicula>> fetchPeliculas() async {
    try {
      final List<dynamic> data = await _apiService.get('films');
      return data.map((json) => Pelicula.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error en controlador de peliculas: $e');
    }
  }
}
