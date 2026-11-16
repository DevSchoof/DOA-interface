import 'package:go_router/go_router.dart';

import 'models/models.dart';
import 'providers/auth_provider.dart';
import 'screens/admin_categories_screen.dart';
import 'screens/admin_institutions_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/donation_detail_screen.dart';
import 'screens/donation_form_screen.dart';
import 'screens/donations_screen.dart';
import 'screens/home_screen.dart';
import 'screens/impact_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/register_user_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/search_donations_screen.dart';
import 'screens/stock_screen.dart';
import 'widgets/app_shell.dart';

/// Prefixo de rota -> único perfil que pode acessar.
const _roleGuards = <String, UserRole>{
  '/donations': UserRole.donor,
  '/search': UserRole.institution,
  '/requests': UserRole.institution,
  '/stock': UserRole.institution,
  '/admin': UserRole.admin,
  '/users': UserRole.admin,
};

GoRouter createRouter(AuthProvider auth) => GoRouter(
  initialLocation: '/login',
  refreshListenable: auth,
  redirect: (context, state) {
    final location = state.matchedLocation;
    final isPublic = location == '/login' || location == '/register';

    if (!auth.isAuthenticated) return isPublic ? null : '/login';
    if (isPublic) return '/home';

    for (final guard in _roleGuards.entries) {
      if (location.startsWith(guard.key) && auth.user?.role != guard.value) {
        return '/home';
      }
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/impact',
          builder: (context, state) => const ImpactScreen(),
        ),
        // doador
        GoRoute(
          path: '/donations',
          builder: (context, state) => const DonationsScreen(),
        ),
        GoRoute(
          path: '/donations/new',
          builder: (context, state) => const DonationFormScreen(),
        ),
        // doador e instituição
        GoRoute(
          path: '/donation/:id',
          builder: (context, state) =>
              DonationDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/donation/:id/edit',
          builder: (context, state) {
            final extra = state.extra;
            return DonationFormScreen(
              donation: extra is Donation ? extra : null,
              donationId: state.pathParameters['id'],
            );
          },
        ),
        GoRoute(
          path: '/donation/:id/chat',
          builder: (context, state) =>
              ChatScreen(donationId: state.pathParameters['id']!),
        ),
        // instituição
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchDonationsScreen(),
        ),
        GoRoute(
          path: '/requests',
          builder: (context, state) => const RequestsScreen(),
        ),
        GoRoute(path: '/stock', builder: (context, state) => const StockScreen()),
        // administrador
        GoRoute(
          path: '/admin/institutions',
          builder: (context, state) => const AdminInstitutionsScreen(),
        ),
        GoRoute(
          path: '/admin/categories',
          builder: (context, state) => const AdminCategoriesScreen(),
        ),
        GoRoute(
          path: '/users/new',
          builder: (context, state) => const RegisterUserScreen(),
        ),
      ],
    ),
  ],
);
