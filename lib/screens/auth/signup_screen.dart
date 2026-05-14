import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';
import '../../services/verification_service.dart';
import '../../providers/system_settings_provider.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _nameC = TextEditingController();
  final _phoneC = TextEditingController(text: '+967');
  UserRole _selectedRole = UserRole.customer;
  bool _isLoading = false;
  final AuthService _auth = AuthService();
  final SmartVerificationService _verifyS = SmartVerificationService();
  String? _verificationToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              decoration: const BoxDecoration(
                color: AshallTheme.primaryColor,
                gradient: AshallTheme.premiumGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    const Text("إنشاء حساب جديد", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    const Text("انضم إلى آلاف المستخدمين والشركاء", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Role Selection (Interactive Tabs)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      children: [
                        Expanded(child: _roleTab("عميل", UserRole.customer, Icons.person_search_rounded)),
                        Expanded(child: _roleTab("تاجر", UserRole.merchant, Icons.storefront_rounded)),
                        Expanded(child: _roleTab("سائق", UserRole.driver, Icons.delivery_dining_rounded)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  PremiumTextField(
                    label: "الاسم الكامل", 
                    controller: _nameC, 
                    icon: Icons.person_outline,
                    hint: "مثال: أحمد محمد",
                  ),
                  const SizedBox(height: 15),
                  PremiumTextField(
                    label: "البريد الإلكتروني", 
                    controller: _emailC, 
                    icon: Icons.email_outlined,
                    hint: "name@example.com",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  PremiumTextField(
                    label: "رقم الهاتف (للتوثيق)", 
                    controller: _phoneC, 
                    icon: Icons.phone_android,
                    hint: "+9677xxxxxxxx",
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),
                  PremiumTextField(
                    label: "كلمة المرور", 
                    controller: _passC, 
                    isPassword: true, 
                    icon: Icons.lock_outline,
                    hint: "••••••••",
                  ),
                  
                  const SizedBox(height: 30),
                  
                  PremiumButton(
                    text: "إنشاء الحساب والتحقق",
                    isLoading: _isLoading,
                    onPressed: _handleSignup,
                  ),
                  
                  const SizedBox(height: 15),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("أو تفعيل مجاني ذكي", style: TextStyle(color: Colors.grey, fontSize: 10))),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  PremiumButton(
                    text: "التحقق عبر الواتساب (مجاناً)",
                    icon: Icons.chat_bubble_outline_rounded,
                    secondary: true,
                    onPressed: _handleWhatsAppVerify,
                  ),
                  
                  const SizedBox(height: 25),
                  
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: "لديك حساب بالفعل؟ ",
                          style: AshallTheme.subtitleStyle,
                          children: [
                            TextSpan(
                              text: "سجل دخولك", 
                              style: TextStyle(color: AshallTheme.primaryColor, fontWeight: FontWeight.bold)
                            ),
                          ]
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleTab(String title, UserRole role, IconData icon) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AshallTheme.primaryColor : Colors.grey[500], size: 20),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: isSelected ? AshallTheme.primaryColor : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleWhatsAppVerify() async {
    if (_phoneC.text.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال رقم هاتف صحيح")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      _verificationToken = _verifyS.generateToken();
      final adminPhone = Provider.of<SystemSettingsProvider>(context, listen: false).settings.contactPhone;
      
      await _verifyS.startWhatsAppVerification(
        phone: _phoneC.text, 
        token: _verificationToken!, 
        adminPhone: adminPhone,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("تم فتح الواتساب. أرسل الرسالة ثم انتظر تفعيل حسابك"),
        duration: Duration(seconds: 10),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSignup() async {
    final email = _emailC.text.trim();
    final pass = _passC.text.trim();
    final name = _nameC.text.trim();
    final phone = _phoneC.text.trim();

    if (email.isEmpty || pass.isEmpty || name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى ملء جميع الحقول")));
      return;
    }
    
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("كلمة المرور يجب أن تكون 6 أحرف على الأقل")));
      return;
    }

    // Lenient phone check: Must contain at least 9 digits
    if (!RegExp(r'^[0-9+]{9,15}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال رقم هاتف صحيح")));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      // 1. Create account directly via Email/Pass
      await _auth.signUp(email, pass, name, _selectedRole, phone: phone);
      
      if (!mounted) return;
      
      // 2. Success Feedback
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("تم إنشاء الحساب! سيتم تفعيله بعد التحقق من رسالة الواتساب."),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ));
      
      // 3. Move to home (they will be restricted if not verified)
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_formatError(e)), 
        backgroundColor: Colors.red
      ));
    }
  }

  String _formatError(dynamic e) {
    return e.toString().replaceFirst('Exception: ', '');
  }
}
