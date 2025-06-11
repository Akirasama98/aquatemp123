import 'package:flutter/material.dart';
import 'controllers/mqtt_controller.dart';
import 'controllers/auth_controller.dart';
import 'views/home_view.dart';
import 'views/update_temperature_view.dart';
import 'views/history_view.dart';
import 'views/profile_view.dart';
import 'views/login_view.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await AuthController.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late MqttController _mqttController;
  int _selectedIndex = 0;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    setState(() {
      _isAuthenticated = AuthController.isLoggedIn;
    });
    
    if (_isAuthenticated) {
      _initializeMqtt();
    }
  }

  void _initializeMqtt() {
    _mqttController = MqttController();
    _mqttController.setOnDataUpdateCallback(() {
      setState(() {
        // Update UI when data changes
      });
    });
  }

  void _onLoginSuccess() {
    _initializeMqtt();
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _onLogout() {
    _mqttController.disconnect();
    setState(() {
      _isAuthenticated = false;
      _selectedIndex = 0;
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaTemp Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
      ),
      home: _isAuthenticated ? _buildMainApp() : LoginView(onLoginSuccess: _onLoginSuccess),
    );
  }

  Widget _buildMainApp() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "AquaTemp Control",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade800,
              ],
            ),
          ),
        ),
      ),
      body: _selectedIndex == 0
          ? HomeView(
              controller: _mqttController,
              onModeToggle: () {
                setState(() {
                  // Mode toggle handled by controller
                });
              },
            )
          : _selectedIndex == 1
              ? UpdateTemperatureView(
                  controller: _mqttController,
                )
              : _selectedIndex == 2
                  ? HistoryView(
                      controller: _mqttController,
                    )
                  : ProfileView(
                      onLogout: _onLogout,
                    ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.thermostat),
            label: 'Update Suhu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
  @override
  void dispose() {
    if (_isAuthenticated) {
      _mqttController.disconnect();
    }
    super.dispose();
  }
}
