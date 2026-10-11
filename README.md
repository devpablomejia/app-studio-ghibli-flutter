# PARTE C – Implementación de la aplicación

## implementación de la aplicación en Flutter, consumiendo el servicio API REST seleccionado y utilizando el mapeo de datos definido previamente.

### API

La API de Studio Ghibli cataloga las personas, los lugares y los objetos que aparecen en los mundos de Ghibli. Fue creada para ayudar a los usuarios a descubrir recursos, consumirlos mediante solicitudes HTTP e interactuar con ellos de la forma que les resulte más conveniente. La navegación se encuentra en la barra lateral izquierda, y la barra lateral derecha muestra ejemplos de objetos devueltos tras llamadas exitosas.

### Documentacion API

[Studio Ghibli API](https://ghibliapi.vercel.app/)

### Organizacion de carpetas

```
lib/
│
├── main.dart         
|
├── models/
│   └── pelicula.dart   
│   └── persona.dart 
│
├── controllers/
│   └── peliculas_controller.dart   
│   └── personas_controller.dart   
│
├── widgets/
│   ├── custom_loader.dart            
│   └── pelicula_card.dart       
│   └── persona_card.dart 
│
├── models/
│   └── api_service.dart  
|
└── views/
    └── peliculas_list_view.dart 
    └── personas_list_view.dart       

```

### Presentado por

- Pablo Miguel Mejia Rodriguez
- Yesica Alejandra Meza Acosta
- Ada Marcela Ruiz Olivo

_Facultad de Ingeniería, Tecnología en Desarrollo de Software, Algoritmo y Programación, Electiva II #2610_
