import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/venues_provider.dart';
import 'providers/slots_provider.dart';
import 'providers/bookings_provider.dart';
import 'services/api_client.dart';
import 'screens/login_screen.dart';
import 'screens/venues_screen.dart';
import 'screens/my_bookings_screen.dart';

void main() async {
  // Required before any plugin (secure storage) is used before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();

  // AuthProvider is created first; ApiClient holds a closure over its token
  // so it always sends the current token without needing to be recreated.
  late final AuthProvider authProvider;

  final apiClient = ApiClient(
    baseUrl: 'http://localhost:3000', // iOS simulator → host machine
    getToken: () => authProvider.token,
  );

  authProvider = AuthProvider(apiClient, storage);

  // Restore a saved session before the first frame so the route guard
  // never flashes LoginScreen for a returning user.
  await authProvider.tryRestoreSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        Provider.value(value: apiClient),
        ChangeNotifierProvider(create: (_) => VenuesProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => SlotsProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => BookingsProvider(apiClient)),
      ],
      child: const QuickSlotApp(),
    ),
  );
}

class QuickSlotApp extends StatelessWidget {
  const QuickSlotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return MaterialApp(
      title: 'QuickSlot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      // Route guard: watching AuthProvider.status drives all navigation.
      // No explicit Navigator calls needed in LoginScreen or logout handlers.
      home: switch (status) {
        AuthStatus.unknown         => const _SplashScreen(),
        AuthStatus.unauthenticated => const LoginScreen(),
        AuthStatus.authenticated   => const _HomeShell(),
      },
    );
  }
}

// ── Home shell ────────────────────────────────────────────────────────────────

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  static const _screens = [VenuesScreen(), MyBookingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.stadium_outlined),  label: 'Venues'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline),  label: 'My Bookings'),
        ],
      ),
    );
  }
}

// Shown for the brief moment between app launch and tryRestoreSession completing.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
