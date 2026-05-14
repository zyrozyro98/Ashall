import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/cart_provider.dart';
import '../../providers/system_settings_provider.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/app_user.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../profile_screen.dart';
import 'wallet_screen.dart';
import 'order_history.dart';
import 'product_detail_screen.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';
import '../success_screen.dart';

class CustomerDashboard extends StatefulWidget {
  final String uid;
  const CustomerDashboard({super.key, required this.uid});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final DatabaseService _db = DatabaseService();
  String _searchQuery = "";
  String _selectedCategory = "الكل";
  int _currentTab = 0;

  final List<Map<String, dynamic>> _categoriesData = [
    {"name": "الكل", "icon": Icons.grid_view_rounded},
    {"name": "مطاعم", "icon": Icons.restaurant_rounded},
    {"name": "تموينات", "icon": Icons.shopping_basket_rounded},
    {"name": "إلكترونيات", "icon": Icons.devices_other_rounded},
    {"name": "ملابس", "icon": Icons.checkroom_rounded},
    {"name": "صحة", "icon": Icons.medical_services_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshallTheme.backgroundColor,
      body: _buildPageContent(),
      floatingActionButton: Consumer<CartProvider>(
        builder: (_, cart, _1) => cart.itemCount > 0 ? FloatingActionButton.extended(
          onPressed: () => _showCart(context, cart),
          backgroundColor: AshallTheme.secondaryColor,
          icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
          label: Text("إتمام الطلب (${cart.itemCount})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ) : const SizedBox.shrink(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          selectedItemColor: AshallTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _currentTab = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "الرئيسية"),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: "طلباتي"),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: "محفظتي"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "حسابي"),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_currentTab) {
      case 0: return _buildHomeHome();
      case 1: return OrderHistoryScreen(userId: widget.uid);
      case 2: return WalletScreen(userId: widget.uid);
      case 3: return ProfileScreen(userId: widget.uid);
      default: return _buildHomeHome();
    }
  }

  Widget _buildHomeHome() {
    return RefreshIndicator(
      color: AshallTheme.primaryColor,
      onRefresh: () async {
        setState(() {}); // Trigger rebuild
        await Future.delayed(const Duration(seconds: 1));
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          
          // Location Indicator
          _buildLocationIndicator(),
          
          // Search & Category Filters
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 10),
                _buildCategoryList(),
              ],
            ),
          ),
  
          // Promoted Section (Carousel)
          _buildPromotedSection(),
  
          // Horizontal Featured Section
          _buildHorizontalFeatured(),
  
          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("جميع المنتجات", style: AshallTheme.titleStyle.copyWith(fontSize: 20)),
                  GestureDetector(
                    onTap: () {}, 
                    child: Text("عرض الكل", style: TextStyle(color: AshallTheme.secondaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
  
          // Products Grid
          _buildProductGrid(),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: AshallTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground, StretchMode.zoomBackground],
        centerTitle: false,
        titlePadding: const EdgeInsets.only(right: 20, bottom: 20),
        title: FutureBuilder<AppUser?>(
          future: _db.getUserProfile(widget.uid),
          builder: (context, userSnap) {
            final user = userSnap.data;
            String name = user?.name.split(' ').first ?? "زائر";
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("أهلاً بك، $name 👋", style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                Text("سوق أسهل الذكي", style: AshallTheme.titleStyle.copyWith(color: Colors.white, fontSize: 18, height: 1.1)),
              ],
            );
          }
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AshallTheme.premiumGradient,
              ),
            ),
            Positioned(
              top: -40,
              left: -40,
              child: CircleAvatar(radius: 120, backgroundColor: Colors.white.withValues(alpha: 0.03)),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              child: FutureBuilder<AppUser?>(
                future: _db.getUserProfile(widget.uid),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  return GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: Column(
                      children: [
                        const Text("رصيدك", style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text("${snap.data!.balance.toStringAsFixed(0)} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", 
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: GlassContainer(
        opacity: 0.8,
        borderRadius: 20,
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: AshallTheme.bodyStyle,
          decoration: InputDecoration(
            hintText: "ابحث عن منتجك المفضل...",
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
            prefixIcon: const Icon(Icons.search_rounded, color: AshallTheme.primaryColor),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AshallTheme.primaryColor, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.tune, color: Colors.white, size: 18),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationIndicator() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AshallTheme.secondaryColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("التوصيل إلى الموقع الحالي", style: TextStyle(color: AshallTheme.subtitleColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text("صنعاء، حي حدة - اليمن", style: AshallTheme.bodyStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
              child: const Icon(Icons.keyboard_arrow_down, color: AshallTheme.primaryColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _categoriesData.length,
        itemBuilder: (context, i) {
          final cat = _categoriesData[i];
          final isSelected = _selectedCategory == cat['name'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['name']),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 55, height: 55,
                    decoration: BoxDecoration(
                      color: isSelected ? AshallTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: isSelected ? [BoxShadow(color: AshallTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                    ),
                    child: Icon(cat['icon'], color: isSelected ? Colors.white : AshallTheme.primaryColor, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'], 
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? AshallTheme.primaryColor : AshallTheme.textColor, 
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontFamily: GoogleFonts.cairo().fontFamily,
                    )
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalFeatured() {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<Product>>(
        stream: _db.getAllProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final featured = snapshot.data!.take(5).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("منتجات رائجة 🚀", style: AshallTheme.titleStyle.copyWith(fontSize: 20)),
                  ],
                ),
              ),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 20),
                  itemCount: featured.length,
                  itemBuilder: (context, i) => Container(
                    width: 170,
                    margin: const EdgeInsets.only(right: 15, bottom: 10),
                    child: _buildProductCard(featured[i]),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildPromotedSection() {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<Product>>(
        stream: _db.getPromotedProducts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                child: Text("عروض حصرية 🔥", style: AshallTheme.titleStyle.copyWith(fontSize: 20)),
              ),
              CarouselSlider(
                options: CarouselOptions(
                  height: 180, 
                  autoPlay: true, 
                  enlargeCenterPage: true, 
                  viewportFraction: 0.85,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                ),
                items: snapshot.data!.map((p) => _buildBannerCard(p)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerCard(Product p) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CachedNetworkImage(
              imageUrl: p.imageUrl.isNotEmpty ? p.imageUrl : 'https://placehold.co/600x400',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumBadge(text: "عرض محدود", color: AshallTheme.secondaryColor),
                const SizedBox(height: 8),
                Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                // Banner Price (if any)
                Consumer<SystemSettingsProvider>(
                  builder: (_, s, _) => Text("${p.price} ${s.settings.currencySymbol} - اطلب الآن", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<List<Product>>(
      stream: _db.getAllProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 15, mainAxisSpacing: 15
              ),
              delegate: SliverChildBuilderDelegate((_, _) => const PremiumSkeleton(), childCount: 6),
            ),
          );
        }
        
        final list = snapshot.data!.where((p) {
          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCat = _selectedCategory == "الكل" || p.category == _selectedCategory;
          return matchesSearch && matchesCat;
        }).toList();

        if (list.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(50.0),
              child: Column(children: [Icon(Icons.search_off, size: 80, color: Colors.grey), SizedBox(height: 10), Text("لم يتم العثور على نتائج")]),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.68, 
              crossAxisSpacing: 15, 
              mainAxisSpacing: 15
            ),
            delegate: SliverChildBuilderDelegate((context, i) => _buildProductCard(list[i]), childCount: list.length),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product p) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'product-${p.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), 
                      child: p.imageUrl.startsWith('data:image') 
                        ? Image.memory(
                            base64Decode(p.imageUrl.split(',').last), 
                            fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                          )
                        : CachedNetworkImage(
                            imageUrl: p.imageUrl.isEmpty ? 'error' : p.imageUrl, 
                            fit: BoxFit.cover, 
                            width: double.infinity, height: double.infinity,
                            placeholder: (context, url) => Container(color: Colors.grey[50]),
                            errorWidget: (c, u, e) => Container(color: Colors.grey[50], child: const Icon(Icons.fastfood_rounded, color: Colors.grey)),
                          )
                    ),
                  ),
                  // Store Status Overlay
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(p.merchantId).snapshots(),
                    builder: (context, snap) {
                      final data = snap.data?.data() as Map<String, dynamic>?;
                      bool isOnline = data?['isOnline'] ?? true;
                      if (isOnline) return const SizedBox.shrink();
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                            child: const Text("مغلق حالياً", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text("4.9", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: AshallTheme.titleStyle.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(p.merchantName, style: TextStyle(color: Colors.grey[500], fontSize: 11), maxLines: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Consumer<SystemSettingsProvider>(
                        builder: (_, s, _) => Text("${p.price} ${s.settings.currencySymbol}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 15)),
                      ),
                      GestureDetector(
                        onTap: () {
                          bool added = Provider.of<CartProvider>(context, listen: false).addItem(p.id, p.name, p.price, p.merchantId);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(added ? "تمت الإضافة بنجاح" : "المنتج موجود مسبقاً"),
                            backgroundColor: added ? AshallTheme.primaryColor : Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            duration: const Duration(seconds: 1),
                          ));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AshallTheme.premiumGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: AshallTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        ),
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

  void _showCart(BuildContext context, CartProvider cart) {
    // Existing cart implementation is already good, keeping it but showing as premium dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PremiumCartSheet(cart: cart, uid: widget.uid, db: _db),
    );
  }
}

class _PremiumCartSheet extends StatefulWidget {
  final CartProvider cart;
  final String uid;
  final DatabaseService db;
  const _PremiumCartSheet({required this.cart, required this.uid, required this.db});

  @override
  State<_PremiumCartSheet> createState() => _PremiumCartSheetState();
}

class _PremiumCartSheetState extends State<_PremiumCartSheet> {
  PaymentMethod _method = PaymentMethod.cash;
  final _codeC = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _codeC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final settings = Provider.of<SystemSettingsProvider>(context).settings;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Text("سلة مشترياتك", style: AshallTheme.titleStyle.copyWith(fontSize: 24)),
          const SizedBox(height: 10),
          cart.items.isEmpty 
            ? Expanded(child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_shopping_cart_rounded, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 15),
                const Text("سلتك فارغة تماماً", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            )))
            : Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, i) {
                final item = cart.items.values.toList()[i];
                return Card(
                  elevation: 0, color: Colors.grey[50], 
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${item.price} ${settings.currencySymbol}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.orange), 
                          onPressed: () => cart.removeByOne(item.productId)
                        ),
                        Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AshallTheme.primaryColor), 
                          onPressed: () => cart.addItem(item.productId, item.name, item.price, item.merchantId)
                        ),
                        const SizedBox(width: 10),
                        Text("${item.quantity * item.price} ${settings.currencySymbol}", style: const TextStyle(color: AshallTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          _buildMethod(PaymentMethod.cash, "دفع عند الاستلام", Icons.money),
          StreamBuilder(
            stream: widget.db.getUserStream(widget.uid),
            builder: (context, snapshot) {
              double bal = 0.0;
              if (snapshot.hasData) bal = (snapshot.data!.data() as Map<String, dynamic>?)?['balance'] ?? 0.0;
              return _buildMethod(PaymentMethod.balance, "محفظة التطبيق (رصيدك: $bal ${settings.currencySymbol})", Icons.account_balance_wallet);
            },
          ),
          _buildMethod(PaymentMethod.walletCode, "تحويل بنكي / محفظة جوال", Icons.smartphone),
          if (_method == PaymentMethod.walletCode) PremiumTextField(label: "كود التحويل / رقم الحوالة", controller: _codeC),
          const SizedBox(height: 20),
          if (cart.totalAmount < settings.minOrderTotal && cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                "الحد الأدنى للطلب هو ${settings.minOrderTotal} ${settings.currencySymbol}. يرجى إضافة المزيد من المنتجات.",
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          PremiumButton(
            text: _isPlacingOrder 
                ? "جاري إرسال الطلبات..." 
                : (cart.items.isEmpty ? "إغلاق السلة" : "إتمام الطلبات (${cart.totalAmount} ${settings.currencySymbol})"),
            onPressed: () async {
              if (cart.items.isEmpty) {
                Navigator.pop(context);
                return;
              }
              if (cart.totalAmount < settings.minOrderTotal) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                   content: Text("عذراً، يجب أن يكون إجمالي الطلب ${settings.minOrderTotal} ${settings.currencySymbol} على الأقل"),
                   backgroundColor: Colors.red,
                 ));
                 return;
              }
              if (_method == PaymentMethod.walletCode && _codeC.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                   content: Text("يرجى إدخال رقم الحوالة أو كود التحويل لمتابعة الطلب"),
                   backgroundColor: Colors.orange,
                ));
                return;
              }

              setState(() => _isPlacingOrder = true);

              final userProfile = await widget.db.getUserProfile(widget.uid);
              if (userProfile?.phone == null || userProfile!.phone!.isEmpty) {
                 setState(() => _isPlacingOrder = false);
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                     content: Text("يرجى إضافة رقم الهاتف من خلال حسابك لإتمام الطلب"),
                     backgroundColor: Colors.red,
                   ));
                 }
                 return;
              }

              // Group items by merchantId
              final Map<String, List<OrderItem>> groups = {};
              for (var item in cart.items.values) {
                groups.putIfAbsent(item.merchantId, () => []).add(item);
              }

              
              // Get dummy customer location or try real with timeout
              GeoPoint cLoc = const GeoPoint(25.2048, 55.2708);
              try {
                final locService = LocationService();
                bool hasPerm = await locService.checkPermissions();
                if (hasPerm) {
                  // Use a timeout to prevent hanging forever if GPS is weak or permissions are weird
                  final pos = await locService.streamLocationUpdates().first.timeout(const Duration(seconds: 4));
                  if (pos.latitude != null && pos.longitude != null) {
                    cLoc = GeoPoint(pos.latitude!, pos.longitude!);
                  }
                }
              } catch (_) {
                // If anything fails, stick to dummy UAE loc
              }

              // Prepare orders list for each merchant
              final List<AppOrder> finalOrders = [];
              for (var entry in groups.entries) {
                final mId = entry.key;
                final mItems = entry.value;
                final total = mItems.fold(0.0, (val, i) => val + (i.price * i.quantity));

                finalOrders.add(AppOrder(
                  id: '', 
                  customerId: widget.uid, 
                  merchantId: mId, 
                  items: mItems, 
                  totalPrice: total, 
                  status: OrderStatus.pending, 
                  timestamp: DateTime.now(),
                  paymentMethod: _method, 
                  walletCode: _method == PaymentMethod.walletCode ? _codeC.text : null,
                  customerLoc: cLoc,
                  merchantLoc: const GeoPoint(25.208, 55.275), // Dummy merchant loc
                  deliveryFee: settings.defaultDeliveryFee,
                ));
              }

              try {
                // Atomic place orders with balance check
                await widget.db.placeOrders(finalOrders, widget.uid, _method);
                
                widget.cart.clearCart();
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SuccessScreen(title: "تم الطلب!", message: "تم إرسال طلباتك للمتاجر المعنية بنجاح")));
              } catch (e) {
                if (!context.mounted) {
                   setState(() => _isPlacingOrder = false);
                   return;
                }
                setState(() => _isPlacingOrder = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMethod(PaymentMethod m, String title, IconData icon) {
    return RadioListTile<PaymentMethod>(
      value: m, groupValue: _method, 
      onChanged: (v) => setState(() => _method = v!),
      title: Text(title), secondary: Icon(icon, color: AshallTheme.primaryColor),
    );
  }
}
