import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/db_init_stub.dart' if (dart.library.io) 'services/db_init_io.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/vitals/heart_rate_screen.dart';
import 'screens/vitals/spo2_screen.dart';
import 'screens/vitals/temperature_screen.dart';
import 'screens/rppg/rppg_scan_screen.dart';
import 'screens/ai_chat/ai_chat_screen.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/doctor/doctor_warroom_screen.dart';
import 'screens/doctor/patient_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/maps/nearby_hospitals_screen.dart';
import 'screens/period_tracker/period_tracker_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/doctor/doctor_portal_screen.dart';
import 'screens/face_mesh/face_mesh_screen.dart';
import 'screens/wellness/wellness_screen.dart';
import 'providers/theme_provider.dart';
import 'screens/vitals/spo2_ecg_temp_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initDesktopDatabase();
  
  await Hive.initFlutter();
  runApp(const ProviderScope(child: VitalSenseApp()));
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
      routes: [
        GoRoute(path: 'heart-rate', builder: (_, __) => const HeartRateScreen()),
        GoRoute(path: 'spo2', builder: (_, __) => const SpO2Screen()),
        GoRoute(path: 'temperature', builder: (_, __) => const TemperatureScreen()),
        GoRoute(path: 'rppg', builder: (_, __) => const RPPGScanScreen()),
        GoRoute(path: 'chat', builder: (_, __) => const AIChatScreen()),
        GoRoute(path: 'alerts', builder: (_, __) => const AlertsScreen()),
        GoRoute(path: 'reports', builder: (_, __) => const ReportsScreen()),
        GoRoute(path: 'nearby-hospitals', builder: (_, __) => const NearbyHospitalsScreen()),
        GoRoute(path: 'period-tracker', builder: (_, __) => const PeriodTrackerScreen()),
        GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(
          path: 'patient/:id',
          builder: (ctx, state) => PatientDetailScreen(patientId: state.pathParameters['id']!),
        ),
        GoRoute(path: 'admin', builder: (_, __) => const AdminScreen()),
        GoRoute(path: 'doctor', builder: (_, __) => const DoctorPortalScreen()),
        GoRoute(path: 'face-mesh', builder: (_, __) => const FaceMeshScreen()),
        GoRoute(path: 'wellness', builder: (_, __) => const WellnessScreen()),
      ],
    ),
  ],
);

class VitalSenseApp extends ConsumerWidget {
  const VitalSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'VitalSense',
      debugShowCheckedModeBanner: false,
      theme: VitalSenseTheme.lightTheme,
      darkTheme: VitalSenseTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
    );
  }
}
