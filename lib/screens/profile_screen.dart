import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../services/database_service.dart';
import '../utils/style_constants.dart';
import '../widgets/premium_ui.dart';

import 'customer/wallet_screen.dart';
import 'settings/app_info_screen.dart';
import 'merchant/merchant_settings.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("الملف الشخصي"), backgroundColor: AshallTheme.primaryColor),
      body: StreamBuilder<AppUser?>(
        stream: auth.getUserStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data == null) return const Center(child: Text("المستخدم غير موجود"));
          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 65, 
                  backgroundColor: AshallTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: (user.profileImage != null && user.profileImage!.isNotEmpty) ? NetworkImage(user.profileImage!) : null,
                  child: (user.profileImage == null || user.profileImage!.isEmpty) ? const Icon(Icons.person, size: 80, color: AshallTheme.primaryColor) : null,
                ),
                const SizedBox(height: 25),
                Text(user.name, style: AshallTheme.titleStyle.copyWith(fontSize: 26)),
                Text(user.email, style: AshallTheme.subtitleStyle),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AshallTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AshallTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 10)]
                  ),
                  child: Text(user.role.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                ),
                const SizedBox(height: 20),
                PremiumButton(
                  text: "محفظتي",
                  icon: Icons.account_balance_wallet,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WalletScreen(userId: user.uid))),
                ),
                if (user.role == UserRole.merchant) ...[
                  const SizedBox(height: 10),
                  PremiumButton(
                    text: "إعدادات المتجر",
                    icon: Icons.store_rounded,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MerchantSettingsScreen(user: user))),
                  ),
                ],
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.phone_android, color: AshallTheme.primaryColor),
                  title: const Text("تغيير رقم الهاتف", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user.phone ?? "لم يتم تعيين رقم هاتف"),
                  trailing: const Icon(Icons.edit, size: 16),
                  onTap: () {
                    String currentPhone = user.phone ?? '+967';
                    showDialog(context: context, builder: (ctx) {
                      final phoneC = TextEditingController(text: currentPhone.startsWith('+967') ? currentPhone : '+967');
                      final otpC = TextEditingController();
                      String vId = "";
                      bool isVerifying = false;
                      bool isOtpSent = false;
                      
                      return StatefulBuilder(
                        builder: (context, setStateDialog) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text(isOtpSent ? "تحقق من الرمز" : "تغيير رقم الهاتف", style: AshallTheme.titleStyle),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isOtpSent) ...[
                                const Text("أدخل رقم الهاتف الجديد ليصلك كود التحقق", style: TextStyle(fontSize: 13, color: Colors.grey)),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: phoneC,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: "+9677xxxxxxxx",
                                    prefixIcon: const Icon(Icons.phone_android, color: AshallTheme.primaryColor),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                ),
                              ] else ...[
                                Text("تم إرسال كود التحقق للرقم ${phoneC.text}", style: const TextStyle(fontSize: 13, color: Colors.blue)),
                                const SizedBox(height: 15),
                                TextField(
                                  controller: otpC,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "أدخل الكود (6 أرقام)",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                ),
                              ],
                              if (isVerifying) const Padding(
                                padding: EdgeInsets.only(top: 15),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AshallTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              onPressed: isVerifying ? null : () async {
                                final db = DatabaseService();
                                setStateDialog(() => isVerifying = true);
                                try {
                                  if (!isOtpSent) {
                                    // Step 1: Check Pre-requisites & Send OTP
                                    bool hasActive = await db.hasActiveUserOrders(userId);
                                    if (hasActive) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا يمكن تغيير رقم الهاتف لوجود طلبات جارية")));
                                        Navigator.pop(ctx);
                                      }
                                      return;
                                    }
                                    
                                    if (user.lastPhoneChange != null) {
                                      final diff = DateTime.now().difference(user.lastPhoneChange!).inDays;
                                      if (diff < 30) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("لا يمكن تغيير رقم الهاتف إلا بعد مرور شهر من آخر تغيير. المتبقي ${30 - diff} يوم")));
                                          Navigator.pop(ctx);
                                        }
                                        return;
                                      }
                                    }
                                    
                                    final newPhone = phoneC.text.trim();
                                    if (!RegExp(r'^\+9677[0-9]{8}$').hasMatch(newPhone)) {
                                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("رقم الهاتف غير صحيح")));
                                      setStateDialog(() => isVerifying = false);
                                      return;
                                    }

                                    // Firebase Verify
                                    await FirebaseAuth.instance.verifyPhoneNumber(
                                      phoneNumber: newPhone,
                                      verificationCompleted: (PhoneAuthCredential cred) async {
                                         await auth.linkPhoneNumber(cred, newPhone);
                                         if (context.mounted) {
                                           Navigator.pop(ctx);
                                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم التحقق وتغيير الرقم تلقائياً")));
                                         }
                                      },
                                      verificationFailed: (err) {
                                        setStateDialog(() => isVerifying = false);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل التحقق: ${err.message}")));
                                      },
                                      codeSent: (v, t) {
                                        setStateDialog(() {
                                          vId = v;
                                          isOtpSent = true;
                                          isVerifying = false;
                                        });
                                      },
                                      codeAutoRetrievalTimeout: (v) => vId = v,
                                    );
                                  } else {
                                    // Step 2: Verify OTP
                                    final code = otpC.text.trim();
                                    if (code.length < 6) { throw Exception("أدخل الكود المكون من 6 أرقام"); }
                                    
                                    PhoneAuthCredential cred = PhoneAuthProvider.credential(verificationId: vId, smsCode: code);
                                    await auth.linkPhoneNumber(cred, phoneC.text.trim());
                                    
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تحديث الهاتف بنجاح"), backgroundColor: Colors.green));
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setStateDialog(() => isVerifying = false);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                                  }
                                }
                              },
                              child: Text(isOtpSent ? "تأكيد" : "إرسال الكود", style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AshallTheme.primaryColor),
                  title: const Text("الشروط والأحكام", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppInfoScreen(isTerms: true))),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AshallTheme.primaryColor),
                  title: const Text("عن التطبيق", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppInfoScreen(isTerms: false))),
                ),
                TextButton(
                  onPressed: () {
                    auth.signOut();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text("تسجيل الخروج", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
