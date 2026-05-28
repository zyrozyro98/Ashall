import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../services/database_service.dart';
import '../utils/style_constants.dart';
import '../utils/phone_utils.dart';
import '../widgets/premium_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/verification_service.dart';
import '../providers/system_settings_provider.dart';

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
                // Phone Verification Premium Card
                InteractiveCard(
                  onTap: () => _showSmartVerificationBottomSheet(context, user),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: user.isPhoneVerified ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            user.isPhoneVerified ? Icons.verified_rounded : Icons.gpp_maybe_rounded,
                            color: user.isPhoneVerified ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("رقم الهاتف والتوثيق", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                user.phone ?? "لم يتم تعيين رقم هاتف",
                                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: user.isPhoneVerified ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            user.isPhoneVerified ? "موثق" : "تفعيل الآن",
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
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

  void _showSmartVerificationBottomSheet(BuildContext context, AppUser user) {
    final phoneC = TextEditingController(text: user.phone ?? '+967');
    final SmartVerificationService verifyS = SmartVerificationService();
    final auth = Provider.of<AuthService>(context, listen: false);
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: user.isPhoneVerified ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user.isPhoneVerified ? Icons.verified_user_rounded : Icons.security_rounded,
                    size: 60,
                    color: user.isPhoneVerified ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user.isPhoneVerified ? "حسابك موثق ومحمي" : "توثيق الحساب الذكي",
                  style: AshallTheme.titleStyle.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  user.isPhoneVerified 
                    ? "رقم هاتفك موثق بنجاح. يمكنك تغييره إذا أردت ولكن ستحتاج إلى توثيقه مرة أخرى."
                    : "نستخدم تقنية التوثيق عبر الواتساب لضمان أمان حسابك وسهولة التفعيل مجاناً وبدون رسائل نصية معقدة.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 25),
                PremiumTextField(
                  label: "رقم الهاتف",
                  controller: phoneC,
                  icon: Icons.phone_android_rounded,
                  hint: "+9677xxxxxxxx",
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                PremiumButton(
                  text: user.isPhoneVerified ? "تحديث وتوثيق الرقم الجديد" : "بدء التوثيق عبر الواتساب",
                  icon: Icons.chat_bubble_rounded,
                  isLoading: isLoading,
                  onPressed: () async {
                    if (!PhoneUtils.isValidPhone(phoneC.text)) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text("يرجى إدخال رقم هاتف يمني صحيح (مثال: 777123456)"),
                        backgroundColor: Colors.red,
                      ));
                      return;
                    }

                    setStateSheet(() => isLoading = true);
                    try {
                      final normalized = PhoneUtils.normalizePhone(phoneC.text);
                      final formattedPhone = "+$normalized";
                      final adminPhone = Provider.of<SystemSettingsProvider>(ctx, listen: false).settings.contactPhone;
                      final token = verifyS.generateToken();
                      
                      // Check for active orders if changing phone
                      if (user.phone != null && user.phone != formattedPhone) {
                          bool hasActive = await DatabaseService().hasActiveUserOrders(user.uid);
                          if (hasActive) {
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("لا يمكن تغيير رقم الهاتف لوجود طلبات جارية")));
                              setStateSheet(() => isLoading = false);
                              return;
                          }
                          
                          // Update email in Auth and phone in Firestore
                          await auth.updatePhoneAndEmail(phoneC.text);
                      }

                      // Update verification token in Firestore
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'verificationToken': token,
                      });

                      // Launch WhatsApp
                      await verifyS.startWhatsAppVerification(
                        phone: formattedPhone,
                        token: token,
                        adminPhone: adminPhone,
                      );
                      
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text("تم فتح الواتساب. أرسل الرسالة ثم انتظر تفعيل حسابك"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 10),
                      ));
                    } catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red));
                    } finally {
                      setStateSheet(() => isLoading = false);
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
