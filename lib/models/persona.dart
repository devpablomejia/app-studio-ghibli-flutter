class Persona {
  String id;
  String nombre;
  String edad;
  String genero;

  Persona({
    required this.id,
    required this.nombre,
    required this.edad,
    required this.genero,
  });

  factory Persona.fromJson(Map<String, dynamic> json) {
    return Persona(
      id: _stringValue(json['id']),
      nombre: _stringValue(json['name']),
      edad: _stringValue(json['age'], fallback: 'Unknown'),
      genero: _stringValue(json['gender']),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}
