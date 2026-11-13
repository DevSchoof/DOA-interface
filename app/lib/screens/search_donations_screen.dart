import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/async_loader.dart';
import '../core/responsive.dart';
import '../core/state_views.dart';
import '../models/models.dart';
import '../providers/profile_provider.dart';
import '../services/api_exception.dart';
import '../services/donation_service.dart';
import '../services/location_service.dart';
import '../widgets/donation_card.dart';

/// CSU04: a instituição busca doações das categorias que aceita, por raio e
/// proximidade. Com o GPS ligado, a distância parte de onde o aparelho está.
class SearchDonationsScreen extends StatefulWidget {
  const SearchDonationsScreen({super.key});

  @override
  State<SearchDonationsScreen> createState() => _SearchDonationsScreenState();
}

class _SearchDonationsScreenState extends State<SearchDonationsScreen> {
  String? _categoryId;
  double _radius = 50; // raio padrão da regra de negócio
  double _radiusDraft = 50;
  GeoPoint? _point; // posição do aparelho (null = usa a cadastrada da instituição)
  bool _locating = false;
  int _version = 0;

  Future<void> _open(Donation d) async {
    await context.push('/donation/${d.id}');
    if (mounted) setState(() => _version++);
  }

  Future<void> _toggleGps(bool on) async {
    if (!on) {
      setState(() => _point = null);
      return;
    }
    final location = context.read<LocationService>();
    setState(() => _locating = true);
    try {
      final point = await location.current();
      if (mounted) setState(() => _point = point);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final service = context.read<DonationService>();

    Widget body;
    if (profile.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!profile.isInstitutionApproved) {
      body = const EmptyState(
        icon: Icons.lock_clock,
        message: 'A busca é liberada depois que o administrador aprovar o '
            'cadastro da instituição.',
      );
    } else {
      final accepted = profile.institution!.categories;
      body = Column(
        children: [
          _Filters(
            categories: accepted,
            categoryId: _categoryId,
            radius: _radiusDraft,
            gpsOn: _point != null,
            locating: _locating,
            onCategory: (id) => setState(() => _categoryId = id),
            onRadiusChanged: (v) => setState(() => _radiusDraft = v),
            onRadiusEnd: (v) => setState(() {
              _radius = v;
              _radiusDraft = v;
            }),
            onGps: _toggleGps,
          ),
          Expanded(
            child: AsyncLoader<List<Donation>>(
              key: ValueKey('$_categoryId-$_radius-${_point?.latitude}-$_version'),
              load: () => service.listAvailable(
                categoryId: _categoryId,
                radiusKm: _radius,
                latitude: _point?.latitude,
                longitude: _point?.longitude,
              ),
              builder: (context, donations, reload) => RefreshIndicator(
                onRefresh: reload,
                child: donations.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 48),
                          EmptyState(
                            icon: Icons.search_off,
                            message: 'Nenhuma doação disponível com esses filtros.',
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          ResponsiveWrap(
                            children: [
                              for (final d in donations)
                                DonationCard(
                                  donation: d,
                                  showDonor: true,
                                  showDistance: true,
                                  onTap: () => _open(d),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar doações')),
      body: ContentWidth(child: body),
    );
  }
}

class _Filters extends StatelessWidget {
  final List<FoodCategory> categories;
  final String? categoryId;
  final double radius;
  final bool gpsOn;
  final bool locating;
  final ValueChanged<String?> onCategory;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onRadiusEnd;
  final ValueChanged<bool> onGps;

  const _Filters({
    required this.categories,
    required this.categoryId,
    required this.radius,
    required this.gpsOn,
    required this.locating,
    required this.onCategory,
    required this.onRadiusChanged,
    required this.onRadiusEnd,
    required this.onGps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<String?>(
              initialValue: categoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Categoria (das que você aceita)',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                for (final c in categories)
                  DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: onCategory,
            ),
          ),
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Raio: ${radius.round()} km',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Slider(
                  value: radius,
                  min: 5,
                  max: 100,
                  divisions: 19,
                  label: '${radius.round()} km',
                  onChanged: onRadiusChanged,
                  onChangeEnd: onRadiusEnd,
                ),
              ],
            ),
          ),
          FilterChip(
            avatar: locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: const Text('Usar minha localização'),
            selected: gpsOn,
            onSelected: locating ? null : onGps,
          ),
        ],
      ),
    );
  }
}
