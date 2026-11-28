import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';
import 'app_providers.dart';
import 'firebase_options.dart';
import 'features/cloud/presentation/auth_screen.dart';
import 'features/catalog/presentation/catalog_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/shopping/presentation/shopping_history_screen.dart';
import 'features/shopping/presentation/shopping_plans_screen.dart';
import 'features/shopping/presentation/shopping_trips_screen.dart';

const bool _pilotWebBuild = bool.fromEnvironment('MERCADO_PILOT_WEB');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? firebaseInitializationError;
  try {
    await Firebase.initializeApp(
      options: kIsWeb
          ? (_pilotWebBuild
                ? PilotFirebaseOptions.web
                : DefaultFirebaseOptions.web)
          : null,
    );
  } on Object {
    firebaseInitializationError =
        'Não foi possível conectar ao serviço de conta.';
  }
  runApp(
    ProviderScope(
      overrides: [
        firebaseInitializationErrorProvider.overrideWithValue(
          firebaseInitializationError,
        ),
      ],
      child: const MercadoApp(),
    ),
  );
}

class MercadoApp extends ConsumerWidget {
  const MercadoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider).asData?.value ?? false;
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176B52),
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176B52),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: isPilotBuild ? 'Nosso Mercadinho — Piloto' : 'Nosso Mercadinho',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializationError = ref.watch(firebaseInitializationErrorProvider);
    if (initializationError != null) {
      return _ServiceUnavailableScreen(message: initializationError);
    }

    final authState = ref.watch(authStateProvider);
    ref.watch(cloudHouseholdsProvider);
    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _ServiceUnavailableScreen(
        message: 'Não foi possível verificar sua sessão. Tente novamente.',
      ),
      data: (account) =>
          account == null ? const AuthScreen() : const MercadoHome(),
    );
  }
}

class _ServiceUnavailableScreen extends StatelessWidget {
  const _ServiceUnavailableScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 56),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'O mercado permanece fechado até que o serviço de conta '
                  'esteja disponível.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MercadoHome extends StatefulWidget {
  const MercadoHome({super.key});

  @override
  State<MercadoHome> createState() => _MercadoHomeState();
}

class _MercadoHomeState extends State<MercadoHome> {
  int _selectedDestination = 0;

  @override
  Widget build(BuildContext context) {
    final Widget page = switch (_selectedDestination) {
      0 => ShoppingPlansScreen(onOpenTrip: _openTrip),
      1 => ShoppingTripsScreen(onOpenTrip: _openTrip),
      2 => const ShoppingHistoryScreen(),
      3 => const CatalogScreen(
        key: ValueKey('catalog'),
        showNavigationBar: true,
      ),
      _ => const SettingsScreen(),
    };

    return Scaffold(
      body: page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedDestination,
        onDestinationSelected: (index) {
          setState(() => _selectedDestination = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Listas',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Compras',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_basket_outlined),
            selectedIcon: Icon(Icons.shopping_basket),
            label: 'Produtos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  void _openTrip(int tripId) {
    setState(() => _selectedDestination = 1);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShoppingTripDetailScreen(tripId: tripId),
      ),
    );
  }
}
