import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/responsive.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';

class _Destination {
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _Destination(this.path, this.label, this.icon, this.selectedIcon);
}

const _home = _Destination('/home', 'Início', Icons.home_outlined, Icons.home);
const _impact = _Destination(
  '/impact',
  'Impacto',
  Icons.bar_chart_outlined,
  Icons.bar_chart,
);

List<_Destination> _destinationsFor(UserRole? role) => switch (role) {
  UserRole.donor => const [
    _home,
    _Destination(
      '/donations',
      'Minhas doações',
      Icons.volunteer_activism_outlined,
      Icons.volunteer_activism,
    ),
    _impact,
  ],
  UserRole.institution => const [
    _home,
    _Destination('/search', 'Buscar', Icons.search, Icons.search),
    _Destination(
      '/requests',
      'Solicitações',
      Icons.assignment_outlined,
      Icons.assignment,
    ),
    _Destination(
      '/stock',
      'Estoque',
      Icons.inventory_2_outlined,
      Icons.inventory_2,
    ),
    _impact,
  ],
  UserRole.admin => const [
    _home,
    _Destination(
      '/admin/institutions',
      'Instituições',
      Icons.apartment_outlined,
      Icons.apartment,
    ),
    _Destination(
      '/admin/categories',
      'Categorias',
      Icons.category_outlined,
      Icons.category,
    ),
    _Destination(
      '/users/new',
      'Usuários',
      Icons.person_add_alt_outlined,
      Icons.person_add_alt_1,
    ),
    _impact,
  ],
  _ => const [_home],
};

/// Moldura de navegação das telas autenticadas.
/// Celular: barra inferior. Tablet: rail compacta. Desktop/web: rail estendida.
class AppShell extends StatelessWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final destinations = _destinationsFor(auth.user?.role);
    var selected = destinations.indexWhere(
      (d) => location == d.path || location.startsWith('${d.path}/'),
    );
    if (selected < 0) selected = 0;

    void go(int index) => context.go(destinations[index].path);

    if (destinations.length < 2) return Scaffold(body: child);

    final width = MediaQuery.sizeOf(context).width;

    if (width < Breakpoints.compact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: go,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = width >= Breakpoints.expanded;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selected,
            onDestinationSelected: go,
            extended: extended,
            labelType: extended ? null : NavigationRailLabelType.all,
            trailing: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (auth.user?.role == UserRole.donor ||
                      auth.user?.role == UserRole.institution)
                    IconButton(
                      tooltip: 'Meu cadastro',
                      icon: const Icon(Icons.account_circle_outlined),
                      onPressed: () => context.go('/profile'),
                    ),
                  IconButton(
                    tooltip: 'Sair',
                    icon: const Icon(Icons.logout),
                    onPressed: () => context.read<AuthProvider>().logout(),
                  ),
                ],
              ),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
