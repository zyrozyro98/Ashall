import 'package:flutter/material.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  // GoogleMapController? _mapC;
  final AuthService _authS = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshallTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Image/Logo
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AshallTheme.primaryColor, AshallTheme.primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 100, color: AshallTheme.secondaryColor),
                  const SizedBox(height: 10),
                  Text("أسهل - ASHALL", style: AshallTheme.titleStyle.copyWith(color: Colors.white, fontSize: 32)),
                  const Text("السوق.. بين يديك", style: TextStyle(color: Colors.white70, fontSize: 18)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  PremiumTextField(label: "البريد الإلكتروني", controller: _emailController, icon: Icons.email_outlined),
                  const SizedBox(height: 20),
                  PremiumTextField(label: "كلمة المرور", controller: _passController, isPassword: true, icon: Icons.lock_outline),
                  const SizedBox(height: 40),
                  PremiumButton(
                    text: "تسجيل الدخول",
                    isLoading: _isLoading,
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      var res = await _authS.signIn(_emailController.text, _passController.text);
                      setState(() => _isLoading = false);
                      if (res == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل تسجيل الدخول")));
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: Text("ليس لديك حساب؟ سجل الآن", style: TextStyle(color: AshallTheme.primaryColor)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
