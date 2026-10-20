import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'services/donor_service.dart';
import 'services/mock_donor_service.dart';
import 'services/mock_auth_service.dart';
import 'services/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Troque MockAuthService pela implementação HTTP quando a API existir.
  final AuthService authService = MockAuthService();
  final auth = AuthProvider(authService, const SessionStorage());
  await auth.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<DonorService>.value(value: MockDonorService()),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: const DoaApp(),
    ),
  );
}

class DoaApp extends StatefulWidget {
  const DoaApp({super.key});

  @override
  State<DoaApp> createState() => _DoaAppState();
}

class _DoaAppState extends State<DoaApp> {
  late final _router = createRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dôa',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      routerConfig: _router,
    );
  }
}
