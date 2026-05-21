import 'package:flutter/material.dart';
import 'models/vehicle.dart';
import 'services/api_service.dart';
import 'views/catalog_view.dart';
import 'views/detail_view.dart';
import 'views/login_view.dart';
import 'views/admin_dashboard_view.dart';

void main() {
  runApp(const UsedCarStorefrontApp());
}

class UsedCarStorefrontApp extends StatelessWidget {
  const UsedCarStorefrontApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Used Car Digital Storefront',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // Deep navy blue (premium automotive theme)
          brightness: Brightness.light,
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF0EA5E9), // Accent cyan
          background: const Color(0xFFF8FAFC), // Slate 50
          surface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          brightness: Brightness.dark,
          primary: const Color(0xFF38BDF8), // Light blue accent
          secondary: const Color(0xFF0EA5E9),
          background: const Color(0xFF0B0F19), // Dark steel blue
          surface: const Color(0xFF1E293B), // Slate 800
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF151F32), // Dark slate cards
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0F19),
          foregroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      themeMode: ThemeMode.system, // Auto dark/light
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Navigation State
  String _currentScreen = 'catalog'; // 'catalog', 'detail', 'login', 'admin'
  Vehicle? _selectedVehicle;

  // Admin Auth State
  String? _adminToken;
  String? _adminName;

  bool _loadingSharedCar = false;
  String _shareError = '';

  @override
  void initState() {
    super.initState();
    _handleSharedLinkOnStartup();
  }

  // Deep linking: If "?car=X" parameter exists on startup, fetch details and load the detail view.
  void _handleSharedLinkOnStartup() {
    final params = Uri.base.queryParameters;
    if (params.containsKey('car')) {
      final carIdStr = params['car'];
      final carId = int.tryParse(carIdStr ?? '');
      if (carId != null) {
        _loadSharedCar(carId);
      }
    }
  }

  Future<void> _loadSharedCar(int id) async {
    setState(() {
      _loadingSharedCar = true;
      _shareError = '';
    });

    try {
      final vehicle = await ApiService.getVehicleByID(id);
      setState(() {
        _selectedVehicle = vehicle;
        _currentScreen = 'detail';
        _loadingSharedCar = false;
      });
    } catch (e) {
      setState(() {
        _shareError = 'Gagal memuat detail mobil dari tautan: $e';
        _loadingSharedCar = false;
      });
    }
  }

  void _navigateToCatalog() {
    setState(() {
      _selectedVehicle = null;
      _currentScreen = 'catalog';
      // Reset the browser URL search params to clean the state if they navigate back to home
      if (Uri.base.queryParameters.containsKey('car')) {
        // Soft refresh without reloading page (standard Flutter behavior)
        // We let the SPA handle internally
      }
    });
  }

  void _navigateToDetail(Vehicle vehicle) {
    setState(() {
      _selectedVehicle = vehicle;
      _currentScreen = 'detail';
    });
  }

  void _navigateToLogin() {
    setState(() {
      _currentScreen = _adminToken != null ? 'admin' : 'login';
    });
  }

  void _handleLoginSuccess(String token, String name) {
    setState(() {
      _adminToken = token;
      _adminName = name;
      _currentScreen = 'admin';
    });
  }

  void _handleLogout() {
    setState(() {
      _adminToken = null;
      _adminName = null;
      _currentScreen = 'catalog';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingSharedCar) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Memuat mobil pilihan Anda...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _currentScreen == 'admin'
          ? null // Admin view handles its own AppBar
          : AppBar(
              title: Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TUNAS JAYA MOTOR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Premium Used Car Digital Storefront',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    ],
                  ),
                ],
              ),
              actions: [
                if (_currentScreen == 'catalog')
                  TextButton.icon(
                    onPressed: _navigateToLogin,
                    icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
                    label: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
                  )
                else if (_currentScreen == 'detail' || _currentScreen == 'login')
                  TextButton.icon(
                    onPressed: _navigateToCatalog,
                    icon: const Icon(Icons.grid_view, color: Colors.white),
                    label: const Text('Lihat Katalog', style: TextStyle(color: Colors.white)),
                  ),
                const SizedBox(width: 12),
              ],
            ),
      body: Column(
        children: [
          if (_shareError.isNotEmpty)
            Container(
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              width: double.infinity,
              child: Row(
                children: [
                  Icon(Icons.warning, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_shareError, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _shareError = ''),
                  )
                ],
              ),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildActiveScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveScreen() {
    switch (_currentScreen) {
      case 'catalog':
        return CatalogView(
          key: const ValueKey('catalog'),
          onSelectVehicle: _navigateToDetail,
        );
      case 'detail':
        return DetailView(
          key: ValueKey('detail_${_selectedVehicle?.id}'),
          vehicle: _selectedVehicle!,
          onBack: _navigateToCatalog,
        );
      case 'login':
        return LoginView(
          key: const ValueKey('login'),
          onLoginSuccess: _handleLoginSuccess,
          onCancel: _navigateToCatalog,
        );
      case 'admin':
        return AdminDashboardView(
          key: const ValueKey('admin'),
          token: _adminToken!,
          adminName: _adminName!,
          onLogout: _handleLogout,
        );
      default:
        return const Center(child: Text('Screen not found'));
    }
  }
}
