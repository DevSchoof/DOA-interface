import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/brand.dart';
import 'core/config.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/push_provider.dart';
import 'providers/realtime_provider.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/chat_service.dart';
import 'services/donation_service.dart';
import 'services/donor_service.dart';
import 'services/http/http_auth_service.dart';
import 'services/http/http_category_service.dart';
import 'services/http/http_donation_service.dart';
import 'services/http/http_donor_service.dart';
import 'services/http/http_institution_service.dart';
import 'services/http/http_stock_impact_chat_services.dart';
import 'services/impact_service.dart';
import 'services/institution_service.dart';
import 'services/location_service.dart';
import 'services/push_service.dart';
import 'services/session_storage.dart';
import 'services/stock_service.dart';

final _messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Camada de rede: um único ponto que conhece a URL, o token e os erros da API.
  late final AuthProvider auth;
  final api = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    tokenProvider: () => auth.session?.token,
    // sessão expirada ou revogada: volta para o login
    onUnauthorized: () {
      if (auth.isAuthenticated) auth.logout();
    },
  );

  final AuthService authService = HttpAuthService(api);
  auth = AuthProvider(authService, const SessionStorage());
  await auth.restoreSession();

  // Push (FCM): só Android; em outras plataformas init() não faz nada.
  final pushService = PushService(api);
  await pushService.init();

  final DonorService donorService = HttpDonorService(api);
  final InstitutionService institutionService = HttpInstitutionService(api);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        Provider<DonorService>.value(value: donorService),
        Provider<InstitutionService>.value(value: institutionService),
        Provider<DonationService>.value(value: HttpDonationService(api)),
        Provider<CategoryService>.value(value: HttpCategoryService(api)),
        Provider<StockService>.value(value: HttpStockService(api)),
        Provider<ImpactService>.value(value: HttpImpactService(api)),
        Provider<ChatService>.value(value: HttpChatService(api)),
        Provider<LocationService>.value(value: const LocationService()),
        Provider<PushService>.value(value: pushService),
        ChangeNotifierProxyProvider<AuthProvider, PushProvider>(
          lazy: false, // ninguém lê o PushProvider: precisa existir para registrar o token
          create: (_) => PushProvider(pushService),
          update: (_, auth, push) => push!..sync(auth.session?.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(donorService, institutionService),
          update: (_, auth, profile) => profile!..sync(auth.user),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RealtimeProvider>(
          create: (_) => RealtimeProvider(ApiConfig.websocketUrl),
          update: (_, auth, realtime) => realtime!..sync(auth.session?.token),
        ),
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
  StreamSubscription<Map<String, dynamic>>? _events;
  StreamSubscription<String>? _pushTaps;

  @override
  void initState() {
    super.initState();
    _events = context.read<RealtimeProvider>().events.listen(_onEvent);
    // tocar numa notificação push abre a doação
    _pushTaps = context.read<PushService>().donationTaps.listen(
      (id) => _router.push('/donation/$id'),
    );
  }

  @override
  void dispose() {
    _events?.cancel();
    _pushTaps?.cancel();
    super.dispose();
  }

  /// Notificações em tempo real viram um aviso na tela.
  void _onEvent(Map<String, dynamic> event) {
    if (event['type'] != 'notification') return;

    final kind = event['event']?.toString();
    // O admin aprovou ou rejeitou: atualiza o status da instituição na hora.
    if (kind == 'INSTITUTION_APPROVED' || kind == 'INSTITUTION_REJECTED') {
      context.read<ProfileProvider>().refresh();
    }

    final title = event['title']?.toString() ?? '';
    final body = event['body']?.toString() ?? '';
    final donationId = event['donationId']?.toString();

    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Text(body.isEmpty ? title : '$title\n$body'),
          action: donationId == null
              ? null
              : SnackBarAction(
                  label: 'Ver',
                  onPressed: () => _router.push('/donation/$donationId'),
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dôa',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: Brand.theme(Brightness.light),
      darkTheme: Brand.theme(Brightness.dark),
      routerConfig: _router,
    );
  }
}
