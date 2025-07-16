import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'stores/settings_store.dart';
import 'stores/display_store.dart';
import 'stores/parameter_store.dart';
import 'stores/websocket_store.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const HardwareControllerApp());
}

class HardwareControllerApp extends StatelessWidget {
  const HardwareControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsStore()),
        ChangeNotifierProvider(create: (context) => DisplayStore(context.read<SettingsStore>())),
        ChangeNotifierProxyProvider<DisplayStore, ParameterStore>(
          create: (context) => ParameterStore(context.read<DisplayStore>()),
          update: (context, displayStore, parameterStore) => parameterStore ?? ParameterStore(displayStore),
        ),
        ChangeNotifierProxyProvider<ParameterStore, WebSocketStore>(
          create: (context) => WebSocketStore(context.read<ParameterStore>()),
          update: (context, parameterStore, webSocketStore) => webSocketStore ?? WebSocketStore(parameterStore),
        ),
      ],
      child: Consumer<SettingsStore>(
        builder: (context, settingsStore, child) {
          return MaterialApp(
            title: 'Hardware Controller',
            theme: settingsStore.themeData,
            home: const AppInitializer(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String _initializationStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _initializationStatus = 'Loading settings...';
      });
      
      // Initialize settings store
      final settingsStore = context.read<SettingsStore>();
      await settingsStore.initialize();
      
      setState(() {
        _initializationStatus = 'Connecting to WebSocket...';
      });
      
      // Initialize WebSocket connection - this will receive real parameters from server
      final webSocketStore = context.read<WebSocketStore>();
      await webSocketStore.initialize();
      
      setState(() {
        _initializationStatus = 'Waiting for parameters...';
      });
      
      // Wait a moment for WebSocket to receive parameters
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _initializationStatus = 'Ready';
        _isInitialized = true;
      });
      
    } catch (e) {
      setState(() {
        _initializationStatus = 'Error: $e';
      });
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Initialization Error'),
            content: Text('Failed to initialize app: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _initializeApp(); // Retry
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
              ),
              const SizedBox(height: 20),
              Text(
                _initializationStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const MainScreen();
  }
}
