import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../providers/cart_provider.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/database_service.dart';
import '../profile_screen.dart';
import 'wallet_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshallTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Premium Custom App Bar
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: AshallTheme.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AshallTheme.primaryColor, AshallTheme.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 80.0, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("أهلاً بك في أسهل 👋", style: AshallTheme.titleStyle.copyWith(color: Colors.white, fontSize: 28)),
                      const SizedBox(height: 5),
                      const Text("تصفح أحدث العروض والمنتجات خصيصاً لك", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_balance_wallet, color: AshallTheme.secondaryColor),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WalletScreen(userId: widget.uid))),
              ),
              IconButton(
                icon: const Icon(Icons.person, color: AshallTheme.secondaryColor),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.uid))),
              ),
              Consumer<CartProvider>(
                builder: (_, cart, ch) => Badge(
                  label: Text(cart.itemCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: AshallTheme.secondaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () => _showCart(context, cart),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),

          // Search Box Sliver
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "ما الذي تبحث عنه اليوم؟",
                    hintStyle: AshallTheme.subtitleStyle.copyWith(fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AshallTheme.primaryColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
          ),

          // Carousel Ads Section
          SliverToBoxAdapter(
            child: StreamBuilder<List<Product>>(
              stream: _db.getPromotedProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 160, 
                      autoPlay: true, 
                      enlargeCenterPage: true,
                      viewportFraction: 0.85,
                    ),
                    items: snapshot.data!.map((p) => Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AshallTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                        image: p.imageUrl.isNotEmpty 
                          ? DecorationImage(image: NetworkImage(p.imageUrl), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken))
                          : null,
                        gradient: p.imageUrl.isEmpty ? const LinearGradient(colors: [AshallTheme.primaryColor, AshallTheme.secondaryColor]) : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: AshallTheme.secondaryColor, borderRadius: BorderRadius.circular(8)),
                              child: const Text("عـرض ممـيز", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 5),
                            Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                );
              },
            ),
          ),

          // Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text("أحدث المنتجات", style: AshallTheme.titleStyle.copyWith(fontSize: 22)),
            ),
          ),

          // Products Grid
          StreamBuilder<List<Product>>(
            stream: _db.getAllProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator())));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text("لا توجد منتجات متاحة حالياً", style: AshallTheme.subtitleStyle),
                    ),
                  ),
                );
              }
              
              final products = snapshot.data!.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _buildProductCard(products[i]),
                    childCount: products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    childAspectRatio: 0.68, 
                    crossAxisSpacing: 15, 
                    mainAxisSpacing: 15,
                  ),
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom Padding
        ],
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                color: Colors.grey.shade100,
              ),
              clipBehavior: Clip.hardEdge,
              child: p.imageUrl.isNotEmpty 
                ? Image.network(p.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.fastfood, size: 40, color: Colors.grey))
                : const Icon(Icons.local_mall, size: 50, color: Colors.grey),
            ),
          ),
          // Product Details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: AshallTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(p.merchantName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${p.price.toStringAsFixed(1)} د.إ", style: AshallTheme.titleStyle.copyWith(fontSize: 16, color: AshallTheme.secondaryColor)),
                    InkWell(
                      onTap: () {
                        bool added = Provider.of<CartProvider>(context, listen: false).addItem(p.id, p.name, p.price);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        if (added) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text("تم إضافة الصنف")]),
                            backgroundColor: AshallTheme.accentColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Row(children: [Icon(Icons.warning, color: Colors.white), SizedBox(width: 10), Text("موجود مسبقاً!")]),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AshallTheme.primaryColor, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCart(BuildContext context, CartProvider cart) {
    PaymentMethod selectedMethod = PaymentMethod.cash;
    final codeC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text("سلة المشتريات", style: AshallTheme.titleStyle),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, i) {
                    final item = cart.items.values.toList()[i];
                    return ListTile(title: Text(item.name), subtitle: Text("${item.quantity} x ${item.price}"), trailing: Text("${item.quantity * item.price} AED"));
                  },
                ),
              ),
              const Divider(),
              const Text("اختر طريقة الدفع", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ListTile(
                title: const Text("دفع عند الاستلام"),
                leading: Radio<PaymentMethod>(value: PaymentMethod.cash, groupValue: selectedMethod, onChanged: (v) => setSheetState(() => selectedMethod = v!)),
              ),
              ListTile(
                title: const Text("رصيد التطبيق (المحفظة)"),
                leading: Radio<PaymentMethod>(value: PaymentMethod.balance, groupValue: selectedMethod, onChanged: (v) => setSheetState(() => selectedMethod = v!)),
              ),
              ListTile(
                title: const Text("كود محفظة جوالي"),
                leading: Radio<PaymentMethod>(value: PaymentMethod.walletCode, groupValue: selectedMethod, onChanged: (v) => setSheetState(() => selectedMethod = v!)),
              ),
              if (selectedMethod == PaymentMethod.walletCode)
                PremiumTextField(label: "أدخل كود الدفع للمحفظة", controller: codeC),
              const SizedBox(height: 20),
              PremiumButton(
                text: "تأكيد الطلب (${cart.totalAmount} AED)",
                onPressed: () async {
                  await _db.createOrder(AppOrder(
                    id: '', 
                    customerId: widget.uid, 
                    merchantId: 'mixed', 
                    items: cart.items.values.toList(), 
                    totalPrice: cart.totalAmount, 
                    status: OrderStatus.pending, 
                    timestamp: DateTime.now(),
                    paymentMethod: selectedMethod,
                    walletCode: selectedMethod == PaymentMethod.walletCode ? codeC.text : null,
                  ));
                  cart.clearCart();
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SuccessScreen(title: "تم الطلب!", message: "طلبك قيد المعالجة، بانتظار تأكيد الدفع إذا لم يكن كاش")));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
