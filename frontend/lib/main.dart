import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/api_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Note: Could not load .env file, using default API configuration: $e");
  }

  // Initialize API service (Django Backend + PostgreSQL)
  try {
    await ApiService.instance.init();
  } catch (e) {
    debugPrint("Error initializing ApiService: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dil Kaa Rista',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
