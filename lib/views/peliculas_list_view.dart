import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controllers/peliculas_controller.dart';
import '../models/pelicula.dart';
import '../widgets/custom_loader.dart';
import '../widgets/pelicula_card.dart';

class FilmListView extends StatefulWidget {
  const FilmListView({super.key});

  @override
  State<FilmListView> createState() => _FilmListViewState();
}

class _FilmListViewState extends State<FilmListView> {
  final PeliculaController _controller = PeliculaController();
  late Future<List<Pelicula>> _peliculasFuture;

  @override
  void initState() {
    super.initState();
    _cargarPeliculas();
  }

  void _cargarPeliculas() {
    _peliculasFuture = _controller.fetchPeliculas();
  }

  void _reintentar() {
    setState(_cargarPeliculas);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E86A8),
        title: SvgPicture.asset(
          'assets/images/Studio_Ghibli.svg',
          height: 38,
          width: 128,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        actions: [
          IconButton(
            onPressed: _reintentar,
            tooltip: 'Actualizar películas',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Pelicula>>(
        future: _peliculasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoader(mensaje: 'Descubriendo películas...');
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'No pudimos cargar las películas.',
              onRetry: _reintentar,
            );
          }

          final peliculas = snapshot.data ?? <Pelicula>[];
          if (peliculas.isEmpty) {
            return _EmptyState(onRetry: _reintentar);
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reintentar();
              await _peliculasFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              itemCount: peliculas.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _ListHeader(count: peliculas.length);
                }

                final pelicula = peliculas[index - 1];
                return PeliculaCard(
                  pelicula: pelicula,
                  onTap: () => _mostrarDetalles(pelicula),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _mostrarDetalles(Pelicula pelicula) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pelicula.titulo,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${pelicula.tituloOriginal} · ${pelicula.fechaLanzamiento}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                pelicula.descripcion.isEmpty
                    ? 'Esta película no tiene una descripción disponible.'
                    : pelicula.descripcion,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DetailChip(
                    icon: Icons.person_outline_rounded,
                    label: pelicula.director,
                  ),
                  _DetailChip(
                    icon: Icons.schedule_rounded,
                    label: '${pelicula.tiempoDuracion} min',
                  ),
                  _DetailChip(
                    icon: Icons.star_rounded,
                    label: '${pelicula.calificacion.toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ListHeader extends StatelessWidget {
  final int count;

  const _ListHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Películas',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Guía comunitaria del universo de Studio Ghibli.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count títulos',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF246B94),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 17),
      label: Text(label.isEmpty ? 'No disponible' : label),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_filter_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text('No se encontraron películas.'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Actualizar')),
        ],
      ),
    );
  }
}
