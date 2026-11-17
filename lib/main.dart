import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'firebase_options.dart';
import 'features/catalog/presentation/catalog_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/shopping/presentation/shopping_history_screen.dart';
import 'features/shopping/presentation/shopping_plans_screen.dart';
import 'features/shopping/presentation/shopping_trips_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object {
    // O app continua disponível offline quando a inicialização da nuvem falha.
  }
  runApp(const ProviderScope(child: MercadoApp()));
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
      title: 'Nosso Mercadinho',
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
      home: const MercadoHome(),
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
