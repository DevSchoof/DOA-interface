import 'package:go_router/go_router.dart';

import 'models/models.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/institution_approval_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_donor_screen.dart';
import 'screens/register_institution_screen.dart';
import 'screens/register_user_screen.dart';

GoRouter createRouter(AuthProvider auth) => GoRouter(
  initialLocation: '/login',
  refreshListenable: auth,
  redirect: (context, state) {
    final loggedIn = auth.isAuthenticated;
    final location = state.matchedLocation;

    if (!loggedIn) return location == '/login' ? null : '/login';
    if (location == '/login') return '/home';

    // Cadastro de usuário só para administrador.
    if (location == '/users/new' && auth.user?.role != UserRole.admin) {
      return '/home';
    }

    // Cadastro de doador só para o perfil Doador.
    if (location == '/donors/new' && auth.user?.role != UserRole.donor) {
      return '/home';
    }

    // Cadastro de instituição só para o perfil Instituição.
    if (location == '/institutions/new' &&
        auth.user?.role != UserRole.institution) {
      return '/home';
    }

    // Homologação de instituições só para administrador.
    if (location == '/admin/institutions' &&
        auth.user?.role != UserRole.admin) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/users/new',
      builder: (context, state) => const RegisterUserScreen(),
    ),
    GoRoute(
      path: '/donors/new',
      builder: (context, state) => const RegisterDonorScreen(),
    ),
    GoRoute(
      path: '/institutions/new',
      builder: (context, state) => const RegisterInstitutionScreen(),
    ),
    GoRoute(
      path: '/admin/institutions',
      builder: (context, state) => const InstitutionApprovalScreen(),
    ),
  ],
);
