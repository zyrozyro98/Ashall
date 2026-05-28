import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/verification_service.dart';
import '../../providers/system_settings_provider.dart';
import '../../utils/style_constants.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/premium_ui.dart';

class PhoneVerificationEnforcerScreen extends StatefulWidget {
  final AppUser user;
  const PhoneVerificationEnforcerScreen({super.key, required this.user});

  @override
  State<PhoneVerificationEnforcerScreen> createState() => _PhoneVerificationEnforcerScreenState();
}

class _PhoneVerificationEnforcerScreenState extends State<PhoneVerificationEnforcerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;
  final SmartVerificationService _verifyS = SmartVerificationService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final sysSettings = Provider.of<SystemSettingsProvider>(context);

    // Read the verification token dynamically from Firestore if it exists
    return Scaffold(
      backgroundColor: AshallTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Pulsing Lock Icon (Artistic Touch)
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.2), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.05),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ]
                      ),
                      child: const Icon(
                        Icons.gpp_maybe_rounded,
                        size: 80,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Titles
                Text(
                  "مرحباً ${widget.user.name}",
                  textAlign: TextAlign.center,
                  style: AshallTheme.titleStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "خطوة واحدة وتستمتع بخدمات أسهل!",
                  textAlign: TextAlign.center,
                  style: AshallTheme.subtitleStyle.copyWith(fontSize: 15, color: AshallTheme.primaryColor),
                ),
                
                const SizedBox(height: 30),
                
                // Explanatory Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AshallTheme.softShadow,
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.security, color: AshallTheme.primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "لماذا توثيق رقم الهاتف إجباري؟",
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AshallTheme.primaryColor, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "لضمان أمان وسلامة جميع المستخدمين، ولمنع الحسابات المزيفة، يتطلب تفعيل حسابك توثيق رقم الهاتف عبر الواتساب عند تسجيل الدخول لأول مرة.",
                        style: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Phone Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AshallTheme.softShadow,
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "رقم الهاتف المسجل لحسابك",
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            PhoneUtils.formatForDisplay(widget.user.phone ?? ''),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AshallTheme.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showEditPhoneSheet(context, widget.user),
                            icon: const Icon(Icons.edit_rounded, size: 16, color: AshallTheme.secondaryColor),
                            label: Text(
                              "تعديل",
                              style: GoogleFonts.cairo(
                                color: AshallTheme.secondaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 35),
                
                // Main CTA Button
                PremiumButton(
                  text: "توثيق عبر الواتساب الآن 💬",
                  icon: Icons.chat_bubble_rounded,
                  isLoading: _isLoading,
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final adminPhone = sysSettings.settings.contactPhone;
                      final token = _verifyS.generateToken();
                      final rawPhone = widget.user.phone ?? '';
                      
                      // Save verification token in Firestore
                      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
                        'verificationToken': token,
                      });

                      // Start WhatsApp verification
                      await _verifyS.startWhatsAppVerification(
                        phone: rawPhone,
                        token: token,
                        adminPhone: adminPhone,
                      );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("تم فتح تطبيق الواتساب. يرجى إرسال الرسالة الجاهزة وانتظار التفعيل."),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 8),
                      ));
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("حدث خطأ أثناء محاولة فتح واتساب: $e"),
                        backgroundColor: Colors.red,
                      ));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                ),
                
                const SizedBox(height: 15),
                
                // Real-time Status Card
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
                  builder: (context, snapshot) {
                    String statusText = "بانتظار طلب التوثيق من قبلك...";
                    Color statusColor = Colors.grey;
                    IconData statusIcon = Icons.info_outline_rounded;
                    String? currentToken;

                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        currentToken = data['verificationToken'];
                        if (currentToken != null && currentToken.isNotEmpty) {
                          statusText = "بانتظار مراجعة وتفعيل المسؤول (الرمز المرسل: $currentToken)";
                          statusColor = Colors.orange;
                          statusIcon = Icons.hourglass_empty_rounded;
                        }
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "حالة التفعيل",
                                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  statusText,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 50),
                
                // Sign Out Option
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await authService.signOut();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل تسجيل الخروج: $e")));
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: Text(
                    "تسجيل الخروج والعودة",
                    style: GoogleFonts.cairo(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPhoneSheet(BuildContext context, AppUser user) {
    final phoneC = TextEditingController(text: user.phone?.replaceAll('+967', '') ?? '');
    final authService = Provider.of<AuthService>(context, listen: false);
    bool isSaving = false;

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
                Text(
                  "تعديل رقم الهاتف",
                  style: AshallTheme.titleStyle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  "يرجى كتابة رقم الهاتف اليمني الجديد بشكل صحيح. سيؤدي هذا لتحديث معلومات حسابك التلقائية.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 25),
                PremiumTextField(
                  label: "رقم الهاتف الجديد",
                  controller: phoneC,
                  icon: Icons.phone_android_rounded,
                  hint: "77xxxxxxx",
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 25),
                PremiumButton(
                  text: "حفظ وتعديل الرقم 💾",
                  isLoading: isSaving,
                  onPressed: () async {
                    final enteredPhone = phoneC.text.trim();
                    if (!PhoneUtils.isValidPhone(enteredPhone)) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text("يرجى إدخال رقم هاتف يمني صحيح (مثال: 777123456)"),
                        backgroundColor: Colors.red,
                      ));
                      return;
                    }

                    setStateSheet(() => isSaving = true);
                    try {
                      // Check active orders
                      bool hasActive = await DatabaseService().hasActiveUserOrders(user.uid);
                      if (hasActive) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("لا يمكن تغيير رقم الهاتف لوجود طلبات جارية")));
                          setStateSheet(() => isSaving = false);
                          return;
                      }

                      // Update using AuthService (which updates auth email + firestore phone/email)
                      await authService.updatePhoneAndEmail(enteredPhone);
                      
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text("تم تحديث رقم الهاتف بنجاح!"),
                        backgroundColor: Colors.green,
                      ));
                    } catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                        backgroundColor: Colors.red,
                      ));
                    } finally {
                      setStateSheet(() => isSaving = false);
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
