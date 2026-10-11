import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/personas_controller.dart';
import '../models/persona.dart';
import '../widgets/custom_loader.dart';
import '../widgets/persona_card.dart';

class PersonasListView extends StatefulWidget {
  const PersonasListView({super.key});

  @override
  State<PersonasListView> createState() => _PersonasListViewState();
}

class _PersonasListViewState extends State<PersonasListView> {
  final PersonasController _controller = PersonasController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  late Future<List<Persona>> _personasFuture;
  String _searchQuery = '';
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _cargarPersonas();
    _cargarBusquedas();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _cargarPersonas() {
    _personasFuture = _controller.fetchPersonas();
  }

  void _reintentar() {
    setState(_cargarPersonas);
  }

  Future<void> _cargarBusquedas() async {
    try {
      final searches = await _preferences.getStringList('personas_searches');
      if (!mounted) return;
      setState(() => _recentSearches = _combinarBusquedas(searches ?? []));
    } on MissingPluginException {
      debugPrint(
        'shared_preferences aún no está disponible; reinicia completamente la app.',
      );
    } catch (error, stackTrace) {
      debugPrint('No se pudo cargar el historial: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _guardarBusqueda(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;

    final searches = _combinarBusquedas([value, ..._recentSearches]);
    if (mounted) {
      setState(() => _recentSearches = searches);
    }

    try {
      await _preferences.setStringList('personas_searches', searches);
    } on MissingPluginException {
      debugPrint(
        'No se pudo guardar la búsqueda: reinicia completamente la app.',
      );
    } catch (error, stackTrace) {
      debugPrint('No se pudo guardar la búsqueda: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<String> _combinarBusquedas(Iterable<String> searches) {
    final unique = <String>[];
    for (final search in searches) {
      final value = search.trim();
      if (value.isNotEmpty &&
          !unique.any((item) => item.toLowerCase() == value.toLowerCase())) {
        unique.add(value);
      }
      if (unique.length == 5) break;
    }
    return unique;
  }

  Future<void> _seleccionarBusqueda(String search) async {
    _searchController
      ..text = search
      ..selection = TextSelection.collapsed(offset: search.length);
    _buscar(search);
    await _guardarBusqueda(search);
  }

  Future<void> _borrarHistorial() async {
    if (mounted) {
      setState(() => _recentSearches = []);
    }

    try {
      await _preferences.setStringList('personas_searches', []);
    } on MissingPluginException {
      debugPrint(
        'No se pudo borrar el historial: reinicia completamente la app.',
      );
    } catch (error, stackTrace) {
      debugPrint('No se pudo borrar el historial: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _buscar(String value) {
    final query = value.trim();
    setState(() => _searchQuery = query.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF315C43),
        title: SvgPicture.asset(
          'assets/images/Studio_Ghibli.svg',
          height: 38,
          width: 128,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        actions: [
          IconButton(
            onPressed: _reintentar,
            tooltip: 'Actualizar personajes',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Persona>>(
        future: _personasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoader(mensaje: 'Conociendo personajes...');
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.cloud_off_rounded,
              message: 'No pudimos cargar los personajes.',
              actionLabel: 'Reintentar',
              onAction: _reintentar,
            );
          }

          final personas = snapshot.data ?? <Persona>[];
          if (personas.isEmpty) {
            return _MessageState(
              icon: Icons.face_retouching_natural_outlined,
              message: 'No se encontraron personajes.',
              actionLabel: 'Actualizar',
              onAction: _reintentar,
            );
          }

          final filteredPersonas = personas
              .where(
                (item) =>
                    item.nombre.toLowerCase().contains(_searchQuery) ||
                    item.genero.toLowerCase().contains(_searchQuery),
              )
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              _reintentar();
              await _personasFuture;
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _WikiHero(
                    count: personas.length,
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    recentSearches: _recentSearches,
                    onChanged: _buscar,
                    onSubmitted: _guardarBusqueda,
                    onRecentSearchSelected: _seleccionarBusqueda,
                    onClearHistory: _borrarHistorial,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  sliver: filteredPersonas.isEmpty
                      ? SliverToBoxAdapter(
                          child: _MessageState(
                            icon: Icons.search_off_rounded,
                            message: 'No hay personajes que coincidan con tu búsqueda.',
                            actionLabel: 'Limpiar búsqueda',
                            onAction: () {
                              _searchController.clear();
                              _buscar('');
                            },
                          ),
                        )
                      : SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.crossAxisExtent >= 900
                                ? 4
                                : constraints.crossAxisExtent >= 600
                                ? 3
                                : 2;
                            return SliverGrid(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final persona = filteredPersonas[index];
                                return PersonaCard(
                                  persona: persona,
                                  onTap: () => _mostrarDetalles(persona),
                                );
                              }, childCount: filteredPersonas.length),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.78,
                                  ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarDetalles(Persona persona) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          persona.nombre,
          style: const TextStyle(
            color: Color(0xFF315C43),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edad: ${persona.edad}'),
            const SizedBox(height: 8),
            Text(
              'Género: ${persona.genero.isEmpty ? 'No disponible' : persona.genero}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _WikiHero extends StatelessWidget {
  final int count;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> recentSearches;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onRecentSearchSelected;
  final VoidCallback onClearHistory;

  const _WikiHero({
    required this.count,
    required this.controller,
    required this.focusNode,
    required this.recentSearches,
    required this.onChanged,
    required this.onSubmitted,
    required this.onRecentSearchSelected,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C8D64), Color(0xFF315C43)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERSONAJES',
            style: TextStyle(
              color: Color(0xFFF4D35E),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Explora el bosque Ghibli',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count personajes · perfiles y curiosidades de tus mundos favoritos.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: 'Buscar un personaje',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: focusNode,
            builder: (context, _) {
              if (!focusNode.hasFocus) return const SizedBox.shrink();
              return _SearchHistory(
                searches: recentSearches,
                onSelected: onRecentSearchSelected,
              );
            },
          ),
          if (recentSearches.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearHistory,
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text('Borrar historial'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchHistory extends StatelessWidget {
  final List<String> searches;
  final ValueChanged<String> onSelected;

  const _SearchHistory({required this.searches, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Historial de búsqueda',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (searches.isEmpty)
            const Text(
              'Aún no hay búsquedas guardadas.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            )
          else
            Material(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: searches
                    .map(
                      (search) => ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(
                          Icons.history_rounded,
                          color: Color(0xFF315C43),
                          size: 19,
                        ),
                        title: Text(
                          search,
                          style: const TextStyle(
                            color: Color(0xFF315C43),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.north_west_rounded,
                          color: Color(0xFF6B8170),
                          size: 17,
                        ),
                        onTap: () => onSelected(search),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
