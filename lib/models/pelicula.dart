class Pelicula {
  String id;
  String titulo;
  String tituloOriginal;
  String tituloRomance;
  String descripcion;
  String director;
  String productor;
  String fechaLanzamiento;
  int tiempoDuracion;
  double calificacion;

  Pelicula({
    required this.id,
    required this.titulo,
    required this.tituloOriginal,
    required this.tituloRomance,
    required this.descripcion,
    required this.director,
    required this.productor,
    required this.fechaLanzamiento,
    required this.tiempoDuracion,
    required this.calificacion,
  });

  factory Pelicula.fromJson(Map<String, dynamic> json) {
    return Pelicula(
      id: json['id'] ?? '',
      titulo: json['title'] ?? '',
      tituloOriginal: json['original_title'] ?? '',
      tituloRomance: json['original_title_romanised'] ?? '',
      descripcion: json['description'] ?? '',
      director: json['director'] ?? '',
      productor: json['producer'] ?? '',
      fechaLanzamiento: json['release_date'] ?? '',
      tiempoDuracion: int.tryParse(json['running_time'] ?? '0') ?? 0,
      calificacion: double.tryParse(json['rt_score'] ?? '0.0') ?? 0.0,
    );
  }
}
