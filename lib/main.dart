import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'utils/style_constants.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/phone_verification_enforcer.dart';
import 'screens/customer/customer_dashboard.dart';
import 'screens/merchant/merchant_dashboard.dart';
import 'screens/driver/driver_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'providers/cart_provider.dart';
import 'providers/system_settings_provider.dart';
import 'widgets/premium_ui.dart';
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

  // Optimizing Firestore for stability and gRPC connectivity
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
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
        ChangeNotifierProvider(create: (_) => SystemSettingsProvider()),
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
        routes: {
          '/login': (context) => const LoginScreen(),
          '/customer-dashboard': (context) => CustomerDashboard(uid: FirebaseAuth.instance.currentUser?.uid ?? ''),
          '/driver-dashboard': (context) => DriverDashboard(uid: FirebaseAuth.instance.currentUser?.uid ?? ''),
          '/merchant-dashboard': (context) => MerchantDashboard(uid: FirebaseAuth.instance.currentUser?.uid ?? ''),
        },
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
        if (user == null) return const LoginScreen();
        
        return StreamBuilder<AppUser?>(
          stream: authService.getUserStream(user.uid),
          builder: (context, userSnap) {
            // Very important: don't show full white loading if we already have the basic auth user
            if (userSnap.connectionState == ConnectionState.waiting) {
               return const Scaffold(
                 body: Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       CircularProgressIndicator(),
                       SizedBox(height: 20),
                       Text("برجاء الانتظار قليلاً..")
                     ]
                   )
                 )
               );
            }
            
            final appUser = userSnap.data;
            if (appUser == null) {
              // The stream is active but no data was found; the user document is likely missing.
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 80, color: Colors.orange),
                        const SizedBox(height: 25),
                        Text("مرحباً بك مجدداً!", style: AshallTheme.titleStyle),
                        const SizedBox(height: 10),
                        const Text(
                          "يبدو أن بياناتك لم تكتمل بعد على السحابة.\nسنقوم بإصلاح ذلك الآن.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 40),
                        PremiumButton(
                          text: "إصلاح حسابي الآن 🛠️",
                          onPressed: () async {
                            // Recovery logic: Create a default user doc from Auth user
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري إعادة بناء بياناتك...")));
                              await authService.syncUserDoc(user);
                            } catch (e) {
                              if (!context.mounted) return;
                              String msg = e.toString();
                              if (msg.contains("unavailable")) {
                                msg = "خادم البيانات غير متاح حالياً. يرجى التأكد من تشغيل (Firestore) في لوحة تحكم Firebase وتوفر الإنترنت.";
                              }
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل في الوصول للسحابة: $msg"), duration: const Duration(seconds: 8)));
                            }
                          },
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () => authService.signOut(),
                          child: const Text("تسجيل الخروج والمحاولة لاحقاً", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            // Maintenance Mode Check
            final settings = Provider.of<SystemSettingsProvider>(context).settings;
            if (settings.maintenanceMode && appUser.role != UserRole.admin) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.build_circle_rounded, size: 100, color: Colors.orange),
                        const SizedBox(height: 30),
                        Text("التطبيق في وضع الصيانة", style: AshallTheme.titleStyle.copyWith(fontSize: 24)),
                        const SizedBox(height: 15),
                        const Text(
                          "نحن نقوم حالياً ببعض التحديثات والتحسينات لضمان أفضل تجربة لك.\nسنعود للعمل قريباً جداً!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 40),
                        PremiumButton(
                          text: "تواصل مع الدعم",
                          onPressed: () {
                            // Link to support or just info
                          },
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () => authService.signOut(),
                          child: const Text("تسجيل الخروج", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Enforce phone verification for non-admin accounts
            if (!appUser.isPhoneVerified && appUser.role != UserRole.admin) {
              return PhoneVerificationEnforcerScreen(user: appUser);
            }

            // Success Case
            switch (appUser.role) {
              case UserRole.customer: return CustomerDashboard(uid: appUser.uid);
              case UserRole.merchant: return MerchantDashboard(uid: appUser.uid);
              case UserRole.driver: return DriverDashboard(uid: appUser.uid);
              case UserRole.admin: return const AdminDashboard();
            }
          },
        );
      },
    );
  }
}

