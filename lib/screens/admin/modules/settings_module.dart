import 'package:flutter/material.dart';
import '../../../models/system_settings.dart';
import '../../../services/database_service.dart';
import '../../../utils/style_constants.dart';
import '../../../widgets/premium_ui.dart';

class AdminSettingsModule extends StatefulWidget {
  const AdminSettingsModule({super.key});

  @override
  State<AdminSettingsModule> createState() => _AdminSettingsModuleState();
}

class _AdminSettingsModuleState extends State<AdminSettingsModule> {
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;
  
  // Controllers
  final _currencyCtrl = TextEditingController();
  final _symbolCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _minTotalCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _timeoutCtrl = TextEditingController();
  bool _maintenance = false;

  @override
  void dispose() {
    _currencyCtrl.dispose();
    _symbolCtrl.dispose();
    _countryCtrl.dispose();
    _regionCtrl.dispose();
    _feeCtrl.dispose();
    _minTotalCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _aboutCtrl.dispose();
    _termsCtrl.dispose();
    _timeoutCtrl.dispose();
    super.dispose();
  }

  void _initFields(AppSystemSettings s) {
    if (_isInitialized) return;
    _currencyCtrl.text = s.currency;
    _symbolCtrl.text = s.currencySymbol;
    _countryCtrl.text = s.country;
    _regionCtrl.text = s.region;
    _feeCtrl.text = s.defaultDeliveryFee.toString();
    _minTotalCtrl.text = s.minOrderTotal.toString();
    _phoneCtrl.text = s.contactPhone;
    _emailCtrl.text = s.supportEmail;
    _aboutCtrl.text = s.aboutApp;
    _termsCtrl.text = s.termsOfService;
    _timeoutCtrl.text = s.orderConfirmationTimeoutMinutes.toString();
    _maintenance = s.maintenanceMode;
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppSystemSettings>(
      stream: _db.getSystemSettings(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("خطأ في الاتصال بقاعدة البيانات: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        _initFields(snapshot.data!);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PremiumSectionTitle(title: "الجغرافيا والعملة", icon: Icons.public_rounded),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildTextField("العملة", _currencyCtrl, Icons.money_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField("رمز العملة", _symbolCtrl, Icons.currency_exchange_rounded)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildTextField("الدولة", _countryCtrl, Icons.flag_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField("المنطقة", _regionCtrl, Icons.map_rounded)),
                  ],
                ),
                
                const SizedBox(height: 30),
                const PremiumSectionTitle(title: "الإعدادات التشغيلية والمالية", icon: Icons.settings_suggest_rounded),
                const SizedBox(height: 15),
                _buildTextField("رسوم التوصيل الافتراضية", _feeCtrl, Icons.delivery_dining_rounded, isNumber: true),
                _buildTextField("الحد الأدنى للطلب", _minTotalCtrl, Icons.shopping_cart_checkout_rounded, isNumber: true),
                _buildTextField("وقت انتظار تأكيد الطلب (دقائق)", _timeoutCtrl, Icons.timer_outlined, isNumber: true),
                
                const SizedBox(height: 30),
                const PremiumSectionTitle(title: "معلومات التواصل والدعم", icon: Icons.contact_support_rounded),
                const SizedBox(height: 15),
                _buildTextField("هاتف المتجر", _phoneCtrl, Icons.phone_rounded),
                _buildTextField("البريد الإلكتروني للدعم", _emailCtrl, Icons.email_rounded),
                
                const SizedBox(height: 30),
                const PremiumSectionTitle(title: "النصوص والمحتوى", icon: Icons.article_rounded),
                const SizedBox(height: 15),
                _buildTextField("عن التطبيق", _aboutCtrl, Icons.info_outline_rounded, maxLines: 3),
                _buildTextField("الشروط والأحكام", _termsCtrl, Icons.gavel_rounded, maxLines: 5),

                const SizedBox(height: 30),
                const PremiumSectionTitle(title: "حالة النظام", icon: Icons.admin_panel_settings_rounded),
                const SizedBox(height: 10),
                PremiumCard(
                  child: SwitchListTile(
                    title: const Text("وضع الصيانة", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("عند التفعيل، سيتوقف التطبيق عن العمل للمستخدمين العاديين لإجراء التحديثات"),
                    value: _maintenance,
                    activeThumbColor: AshallTheme.primaryColor,
                    onChanged: (val) => setState(() => _maintenance = val),
                  ),
                ),
                
                const SizedBox(height: 40),
                PremiumButton(
                  text: "حفظ كل الإعدادات",
                  icon: Icons.save_rounded,
                  onPressed: _saveSettings,
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AshallTheme.primaryColor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.white,
          alignLabelWithHint: maxLines > 1,
        ),
        validator: (v) => v!.isEmpty ? "هذا الحقل مطلوب" : null,
      ),
    );
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final newSettings = AppSystemSettings(
        currency: _currencyCtrl.text,
        currencySymbol: _symbolCtrl.text,
        country: _countryCtrl.text,
        region: _regionCtrl.text,
        defaultDeliveryFee: double.tryParse(_feeCtrl.text) ?? 15.0,
        minOrderTotal: double.tryParse(_minTotalCtrl.text) ?? 30.0,
        contactPhone: _phoneCtrl.text,
        supportEmail: _emailCtrl.text,
        aboutApp: _aboutCtrl.text,
        termsOfService: _termsCtrl.text,
        orderConfirmationTimeoutMinutes: int.tryParse(_timeoutCtrl.text) ?? 10,
        maintenanceMode: _maintenance,
      );
      
      await _db.updateSystemSettings(newSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم تحديث إعدادات النظام بنجاح"), backgroundColor: Colors.green),
        );
      }
    }
  }
}
