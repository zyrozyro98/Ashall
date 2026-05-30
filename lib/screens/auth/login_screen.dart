import 'package:flutter/material.dart';
import '../../utils/style_constants.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/premium_ui.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
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
                    label: "رقم الهاتف أو البريد الإلكتروني", 
                    controller: _phoneController, 
                    icon: Icons.phone_android_rounded,
                    hint: "+9677xxxxxxxx أو البريد الإلكتروني",
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

  void _handleLogin() async {
    final input = _phoneController.text.trim();
    final pass = _passController.text.trim();
    if (input.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال رقم الهاتف أو البريد الإلكتروني مع كلمة المرور")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Smart Email Fallback: If the user inputs an email (like an admin zyrozyro98@gmail.com), use it.
      // Otherwise, assume it's a phone number and generate the mapped email.
      String loginEmail;
      if (input.contains('@')) {
        loginEmail = input;
      } else {
        String normalized = PhoneUtils.normalizePhone(input);
        if (normalized.isEmpty || normalized.length < 9) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("يرجى إدخال رقم هاتف صحيح"),
            backgroundColor: Colors.red,
          ));
          setState(() => _isLoading = false);
          return;
        }
        loginEmail = "$normalized@ashall.com";
      }
      
      await _authS.signIn(loginEmail, pass);
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
