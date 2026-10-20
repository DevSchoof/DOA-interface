import 'package:go_router/go_router.dart';

import 'models/models.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
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
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/users/new',
      builder: (context, state) => const RegisterUserScreen(),
    ),
  ],
);
