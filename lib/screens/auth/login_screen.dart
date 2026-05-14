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
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header
            Container(
              height: size.height * 0.35,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AshallTheme.primaryColor,
                gradient: AshallTheme.premiumGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)]),
                        child: const Icon(Icons.shopping_bag_rounded, size: 50, color: AshallTheme.primaryColor),
                      ),
                      const SizedBox(height: 15),
                      const Text("أسهل", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const Text("كل ما تحتاجه في تطبيق واحد", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 40, 25, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("تسجيل الدخول", style: AshallTheme.titleStyle.copyWith(fontSize: 28)),
                  const SizedBox(height: 5),
                  Text("مرحباً بك مجدداً! نحن سعداء برؤيتك", style: AshallTheme.subtitleStyle),
                  const SizedBox(height: 30),
                  
                  PremiumTextField(
                    label: "البريد الإلكتروني", 
                    controller: _emailController, 
                    icon: Icons.email_outlined,
                    hint: "name@example.com",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  PremiumTextField(
                    label: "كلمة المرور", 
                    controller: _passController, 
                    isPassword: true, 
                    icon: Icons.lock_outline,
                    hint: "••••••••",
                  ),
                  
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {}, 
                      child: Text("نسيت كلمة المرور؟", style: TextStyle(color: AshallTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  PremiumButton(
                    text: "دخول الآن",
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Social Login Section
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("أو الدخول بواسطة", style: TextStyle(color: Colors.grey[400], fontSize: 12))),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialBtn(Icons.g_mobiledata_rounded, Colors.red, "Google"),
                      _buildSocialBtn(Icons.apple_rounded, Colors.black, "Apple"),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("ليس لديك حساب؟", style: AshallTheme.subtitleStyle),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: Text("سجل مجاناً", style: TextStyle(color: AshallTheme.secondaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialBtn(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال البريد وكلمة المرور")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authS.signIn(email, pass);
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _isLoading = false);
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
    }
  }
}
