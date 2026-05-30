import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../providers/system_settings_provider.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';
import '../customer/wallet_screen.dart';
import '../customer/support_chat_screen.dart';
import '../profile_screen.dart';
import 'merchant_orders.dart';

class MerchantDashboard extends StatefulWidget {
  final String uid;
  const MerchantDashboard({super.key, required this.uid});

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  final DatabaseService _db = DatabaseService();
  final List<String> _categories = ["مطاعم", "تموينات", "إلكترونيات", "ملابس", "صحة", "أخرى"];

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text("تسجيل الخروج", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: const Text("هل تريد بالتأكيد تسجيل الخروج من حساب المتجر؟"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("تراجع")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AshallTheme.primaryColor),
              onPressed: () => Navigator.pop(c, true),
              child: const Text("تسجيل الخروج", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await AuthService().signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل تسجيل الخروج: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          
          // Analytics & Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("الأداء العام للمتجر", style: AshallTheme.titleStyle.copyWith(fontSize: 22)),
                  const SizedBox(height: 20),
                  
                  // Sales Trend Chart
                  _buildSalesChart(),
                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard("إجمالي المنتجات", "products", Icons.inventory_2_rounded, Colors.blue)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildSummaryCard("طلبات نشطة", "orders", Icons.local_mall_rounded, Colors.orange, isOrder: true)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Inventory Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("كتالوج المنتجات", style: AshallTheme.titleStyle.copyWith(fontSize: 20)),
                      Text("إدارة وتحديث العناصر المتاحة في متجرك", style: AshallTheme.subtitleStyle.copyWith(fontSize: 12)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _addProductDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AshallTheme.secondaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.add_business_rounded, color: AshallTheme.secondaryColor),
                    ),
                  )
                ],
              ),
            ),
          ),

          _buildProductList(),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AshallTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text("لوحة تحكم المتجر", style: AshallTheme.titleStyle.copyWith(color: Colors.white, fontSize: 18)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: const BoxDecoration(gradient: AshallTheme.premiumGradient)),
            Positioned(
              right: 20,
              bottom: 60,
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data() as Map<String, dynamic>?;
                  bool isOpen = data?['isOnline'] ?? false;
                  return GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: isOpen ? Colors.green : Colors.red, size: 12),
                        const SizedBox(width: 8),
                        Text(isOpen ? "المتجر مفتوح" : "المتجر مغلق", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 5),
                        Transform.scale(
                          scale: 0.7,
                          child: Switch(
                            value: isOpen,
                            onChanged: (val) => FirebaseFirestore.instance.collection('users').doc(widget.uid).update({'isOnline': val}),
                            activeThumbColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              right: -30, top: -30,
              child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withValues(alpha: 0.05)),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: "الدعم الفني",
          icon: const Icon(Icons.support_agent_rounded, color: Colors.white), 
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupportChatScreen(userId: widget.uid)))
        ),
        IconButton(
          tooltip: "الطلبات",
          icon: const Icon(Icons.receipt_long_rounded, color: Colors.white), 
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MerchantOrdersScreen(merchantId: widget.uid)))
        ),
        IconButton(
          tooltip: "المحفظة",
          icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white), 
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WalletScreen(userId: widget.uid, isWithdrawMode: true)))
        ),
        IconButton(
          tooltip: "الإعدادات",
          icon: const Icon(Icons.settings_outlined, color: Colors.white), 
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.uid)))
        ),
        IconButton(
          tooltip: "تسجيل الخروج",
          icon: const Icon(Icons.logout_rounded, color: Colors.white), 
          onPressed: () => _handleLogout(context),
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("مخطط المبيعات الأسبوعي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                barGroups: [
                  _makeBarGroup(0, 4500, Colors.blue),
                  _makeBarGroup(1, 6200, Colors.teal),
                  _makeBarGroup(2, 5100, Colors.blue),
                  _makeBarGroup(3, 8900, AshallTheme.primaryColor),
                  _makeBarGroup(4, 7200, Colors.blue),
                  _makeBarGroup(5, 9500, Colors.green),
                  _makeBarGroup(6, 4800, Colors.blue),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        const days = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];
                        return Text(days[v.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey));
                      }
                    )
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              )
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 15,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String type, IconData icon, Color color, {bool isOrder = false}) {
    if (isOrder) {
      return StreamBuilder<List<AppOrder>>(
        stream: _db.getMerchantOrders(widget.uid),
        builder: (context, snap) {
          int count = 0;
          if (snap.hasData) {
            count = snap.data!.where((o) => o.status.index >= 0 && o.status.index <= 3).length;
          }
          String val = snap.hasData ? count.toString() : "...";
          return _buildCardUI(title, val, icon, color);
        },
      );
    } else {
      return StreamBuilder<List<Product>>(
        stream: _db.getMerchantProducts(widget.uid),
        builder: (context, snap) {
          int count = 0;
          if (snap.hasData) {
            count = snap.data!.length;
          }
          String val = snap.hasData ? count.toString() : "...";
          return _buildCardUI(title, val, icon, color);
        },
      );
    }
  }

  Widget _buildCardUI(String title, String val, IconData icon, Color color) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10), 
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), 
            child: Icon(icon, color: color, size: 24)
          ),
          const SizedBox(height: 12),
          Text(val, style: AshallTheme.titleStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(title, style: AshallTheme.subtitleStyle.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<List<Product>>(
      stream: _db.getMerchantProducts(widget.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        final products = snapshot.data!;
        
        if (products.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(50), 
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 20),
                    const Text("لا توجد منتجات في متجرك حالياً.\nابدأ بإضافة منتجك الأول!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ],
                )
              )
            )
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildProductCard(products[i]),
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
        border: Border.all(color: p.isAvailable ? Colors.transparent : Colors.red.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                child: p.imageUrl.startsWith('data:image') 
                  ? Image.memory(
                      base64Decode(p.imageUrl.split(',').last), 
                      width: 110, height: 110, fit: BoxFit.cover, 
                      errorBuilder: (c, e, s) => Container(width: 110, height: 110, color: Colors.grey[100], child: const Icon(Icons.inventory_2_rounded, color: Colors.grey))
                    )
                  : CachedNetworkImage(
                      key: ValueKey(p.imageUrl),
                      imageUrl: p.imageUrl.isEmpty ? 'error' : p.imageUrl, 
                      width: 110, height: 110, fit: BoxFit.cover, 
                      placeholder: (c,u) => Container(width: 110, height: 110, color: Colors.grey[50], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (c,u,e) => Container(width: 110, height: 110, color: Colors.grey[100], child: const Icon(Icons.inventory_2_rounded, color: Colors.grey)),
                    ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 15, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          SizedBox(
                            width: 30, height: 30,
                            child: PopupMenuButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[600]),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: Icon(Icons.edit_outlined), title: Text("تعديل البيانات"))),
                                PopupMenuItem(value: 'toggle_availability', child: ListTile(dense: true, leading: Icon(p.isAvailable ? Icons.visibility_off_outlined : Icons.visibility_outlined), title: Text(p.isAvailable ? "إخفاء (نفذ)" : "إظهار (متوفر)"))),
                                const PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline, color: Colors.red), title: Text("حذف كلي", style: TextStyle(color: Colors.red)))),
                              ],
                              onSelected: (val) {
                                 if (val == 'edit') _editProductDialog(context, p);
                                 if (val == 'toggle_availability') _db.updateProduct(p.id, {'isAvailable': !p.isAvailable});
                                 if (val == 'delete') _showDeleteConfirmation(context, p);
                              },
                            ),
                          ),
                        ],
                      ),
                      Text(p.category, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Consumer<SystemSettingsProvider>(
                            builder: (_, s, _) => Text("${p.price} ${s.settings.currencySymbol}", style: const TextStyle(color: AshallTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 16)),
                          ),
                          const Spacer(),
                          if (!p.isAvailable)
                            PremiumBadge(text: "غير متوفر", color: Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!p.isAvailable)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _addProductDialog(BuildContext context) {
    final settings = Provider.of<SystemSettingsProvider>(context, listen: false).settings;
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final descC = TextEditingController();
    String selectedCat = _categories[0];
    File? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("إضافة منتج جديد", style: AshallTheme.titleStyle.copyWith(fontSize: 22)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const Divider(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: isUploading 
                    ? const Center(child: Column(children: [SizedBox(height: 100), CircularProgressIndicator(), SizedBox(height: 20), Text("جاري معالجة الطلب...")] ))
                    : Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                              if (pickedFile != null) setDialogState(() => selectedImage = File(pickedFile.path));
                            },
                            child: Container(
                              height: 180, width: double.infinity,
                              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                              child: selectedImage == null ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 50, color: AshallTheme.primaryColor), SizedBox(height: 10), Text("اضغط لإضافة صورة المنتج")]) : ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(selectedImage!, fit: BoxFit.cover)),
                            ),
                          ),
                          const SizedBox(height: 25),
                          PremiumTextField(label: "اسم المنتج", controller: nameC, icon: Icons.shopping_bag_outlined, hint: "مثال: وجبة عائلية"),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            initialValue: selectedCat,
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                            onChanged: (v) => selectedCat = v!,
                            decoration: InputDecoration(
                              labelText: "التصنيف", 
                              prefixIcon: const Icon(Icons.category_outlined, color: AshallTheme.primaryColor),
                              filled: true, fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 20),
                          PremiumTextField(label: "السعر (${settings.currencySymbol})", controller: priceC, icon: Icons.payments_outlined, keyboardType: TextInputType.number),
                          const SizedBox(height: 20),
                          PremiumTextField(label: "الوصف التفصيلي", controller: descC, icon: Icons.description_outlined, hint: "اشرح مكونات المنتج أو مواصفاته..."),
                          const SizedBox(height: 40),
                        ],
                      ),
                ),
              ),
              if (!isUploading)
                PremiumButton(
                  text: "نشر في المتجر الآن", 
                  onPressed: () async {
                    if (nameC.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال اسم المنتج")));
                      return;
                    }
                    if (priceC.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال السعر")));
                      return;
                    }

                    setDialogState(() => isUploading = true);
                    try {
                      String imageUrl = '';
                      String tempId = DateTime.now().millisecondsSinceEpoch.toString();
                      
                      if (selectedImage != null) {
                        String? url = await StorageService().uploadProductImage(selectedImage!, "prod_$tempId.jpg");
                        if (url != null) imageUrl = url;
                      }
                      
                      // Get current merchant name dynamically
                      final profileDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
                      String mName = profileDoc.data()?['storeName'] ?? profileDoc.data()?['name'] ?? 'متجر أسهل';

                      await _db.addProduct(Product(
                        id: tempId, 
                        merchantId: widget.uid, 
                        merchantName: mName, 
                        name: nameC.text, 
                        description: descC.text, 
                        price: double.tryParse(priceC.text) ?? 0.0, 
                        imageUrl: imageUrl,
                        category: selectedCat,
                        isPromoted: false,
                      ));

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      
                      String successMsg = imageUrl.isNotEmpty 
                        ? "✅ تمت إضافة المنتج بنجاح!" 
                        : "⚠️ تمت الإضافة، لكن فشل رفع الصورة. سيظهر المنتج بدون صورة.";
                        
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(successMsg), 
                        backgroundColor: imageUrl.isNotEmpty ? Colors.green : Colors.orange
                      ));
                    } catch (e) {
                      setDialogState(() => isUploading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ فشل النشر: $e"), backgroundColor: Colors.red));
                    }
                  }
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: Text("هل أنت متأكد من حذف المنتج '${p.name}' نهائياً؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _db.deleteProduct(p.id);
            },
            child: const Text("حذف كلي", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editProductDialog(BuildContext context, Product p) {
    final settings = Provider.of<SystemSettingsProvider>(context, listen: false).settings;
    final nameC = TextEditingController(text: p.name);
    final priceC = TextEditingController(text: p.price.toString());
    final descC = TextEditingController(text: p.description);
    String selectedCat = _categories.contains(p.category) ? p.category : _categories[0];
    File? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("تعديل بيانات المنتج", style: AshallTheme.titleStyle.copyWith(fontSize: 22)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const Divider(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: isUploading 
                    ? const Center(child: Column(children: [SizedBox(height: 100), CircularProgressIndicator(), SizedBox(height: 20), Text("جاري معالجة الطلب...")] ))
                    : Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                              if (pickedFile != null) setDialogState(() => selectedImage = File(pickedFile.path));
                            },
                            child: Container(
                              height: 180, width: double.infinity,
                              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
                              child: selectedImage != null 
                                ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(selectedImage!, fit: BoxFit.cover))
                                : (p.imageUrl.startsWith('data:image') 
                                    ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(base64Decode(p.imageUrl.split(',').last), fit: BoxFit.cover))
                                    : (p.imageUrl.isNotEmpty
                                        ? ClipRRect(borderRadius: BorderRadius.circular(20), child: CachedNetworkImage(imageUrl: p.imageUrl, fit: BoxFit.cover))
                                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 50, color: AshallTheme.primaryColor), SizedBox(height: 10), Text("اضغط لتغيير صورة المنتج")]))),
                            ),
                          ),
                          const SizedBox(height: 25),
                          PremiumTextField(label: "اسم المنتج", controller: nameC, icon: Icons.shopping_bag_outlined, hint: "مثال: وجبة عائلية"),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            initialValue: selectedCat,
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                            onChanged: (v) => selectedCat = v!,
                            decoration: InputDecoration(
                              labelText: "التصنيف", 
                              prefixIcon: const Icon(Icons.category_outlined, color: AshallTheme.primaryColor),
                              filled: true, fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 20),
                          PremiumTextField(label: "السعر (${settings.currencySymbol})", controller: priceC, icon: Icons.payments_outlined, keyboardType: TextInputType.number),
                          const SizedBox(height: 20),
                          PremiumTextField(label: "الوصف التفصيلي", controller: descC, icon: Icons.description_outlined, hint: "اشرح مكونات المنتج أو مواصفاته..."),
                          const SizedBox(height: 40),
                        ],
                      ),
                ),
              ),
              if (!isUploading)
                PremiumButton(
                  text: "تحديث البيانات الآن", 
                  onPressed: () async {
                    if (nameC.text.isEmpty || priceC.text.isEmpty) return;
                    setDialogState(() => isUploading = true);
                    try {
                      String imageUrl = p.imageUrl;
                      
                      if (selectedImage != null) {
                        String? url = await StorageService().uploadProductImage(selectedImage!, "prod_${p.id}.jpg");
                        if (url != null) imageUrl = url;
                      }
                      
                      await _db.updateProduct(p.id, {
                        'name': nameC.text, 
                        'description': descC.text, 
                        'price': double.tryParse(priceC.text) ?? 0.0, 
                        'imageUrl': imageUrl,
                        'category': selectedCat,
                      });
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تمت تحديث بيانات المنتج بنجاح!"), backgroundColor: Colors.green));
                    } catch (e) {
                      setDialogState(() => isUploading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("فشل التحديث: $e"), backgroundColor: Colors.red));
                    }
                  }
                ),
            ],
          ),
        ),
      ),
    );
  }
}
