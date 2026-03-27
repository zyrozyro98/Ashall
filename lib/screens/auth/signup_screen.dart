import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _nameC = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  bool _isLoading = false;
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshallTheme.backgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: AshallTheme.primaryColor)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("إنشاء حساب جديد", style: AshallTheme.titleStyle.copyWith(fontSize: 30)),
            Text("انضم إلى أسرة أسهل اليوم", style: AshallTheme.subtitleStyle),
            const SizedBox(height: 30),
            
            PremiumTextField(label: "الاسم الكامل", controller: _nameC, icon: Icons.person_outline),
            const SizedBox(height: 20),
            PremiumTextField(label: "البريد الإلكتروني", controller: _emailC, icon: Icons.email_outlined),
            const SizedBox(height: 20),
            PremiumTextField(label: "كلمة المرور", controller: _passC, isPassword: true, icon: Icons.lock_outline),
            const SizedBox(height: 30),
            
            Text("سجل كـ:", style: AshallTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _roleOption("عميل", UserRole.customer),
                _roleOption("تاجر", UserRole.merchant),
                _roleOption("سائق", UserRole.driver),
              ],
            ),
            
            const SizedBox(height: 40),
            PremiumButton(
              text: "إنشاء الحساب",
              isLoading: _isLoading,
              onPressed: _handleSignup,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleOption(String title, UserRole role) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AshallTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AshallTheme.primaryColor),
        ),
        child: Text(title, style: TextStyle(color: isSelected ? Colors.white : AshallTheme.primaryColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _handleSignup() async {
    if (_emailC.text.isEmpty || _passC.text.isEmpty || _nameC.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    var res = await _auth.signUp(_emailC.text, _passC.text, _nameC.text, _selectedRole);
    setState(() => _isLoading = false);
    
    if (res != null) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل إنشاء الحساب")));
    }
  }
}
