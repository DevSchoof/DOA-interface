import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

GoRouter createRouter(AuthProvider auth) => GoRouter(
  initialLocation: '/login',
  refreshListenable: auth, // reavalia o redirect quando a sessão muda
  redirect: (context, state) {
    final loggedIn = auth.isAuthenticated;
    final onLogin = state.matchedLocation == '/login';

    if (!loggedIn) return onLogin ? null : '/login';
    if (onLogin) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ],
);
