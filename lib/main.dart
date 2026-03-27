import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'utils/style_constants.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_dashboard.dart';
import 'screens/merchant/merchant_dashboard.dart';
import 'screens/driver/driver_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'providers/cart_provider.dart';
import 'models/app_user.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Background Handler registration
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Initialize App Notifications
  await NotificationService().init();
  
  runApp(const AshallApp());
}

class AshallApp extends StatelessWidget {
  const AshallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'أسهل - ASHALL',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AshallTheme.primaryColor,
          scaffoldBackgroundColor: AshallTheme.backgroundColor,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder<User?>(
      stream: authService.userStatus,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }
        
        return StreamBuilder<AppUser?>(
          stream: authService.getUserStream(user.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            
            final appUser = userSnap.data;
            if (appUser == null) {
              // Wait for user doc creation, with a fallback to sign out if stuck
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      const Text("جاري تجهيز بيانات حسابك..."),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => authService.signOut(),
                        child: const Text("تسجيل الخروج"),
                      )
                    ],
                  ),
                ),
              );
            }
            
            switch (appUser.role) {
              case UserRole.customer:
                return CustomerDashboard(uid: appUser.uid);
              case UserRole.merchant:
                return MerchantDashboard(uid: appUser.uid);
              case UserRole.driver:
                return DriverDashboard(uid: appUser.uid);
              case UserRole.admin:
                return const AdminDashboard();
            }
          },
        );
      },
    );
  }
}
