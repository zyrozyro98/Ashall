import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../../../models/product.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/system_settings_provider.dart';
import '../../../utils/style_constants.dart';
import '../../../widgets/premium_ui.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Header Image & Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.45,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: AshallTheme.primaryColor,
                leading: const SizedBox.shrink(), // Custom back button used below
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Hero(
                    tag: product.id,
                    child: product.imageUrl.startsWith('data:image') 
                      ? Image.memory(
                          base64Decode(product.imageUrl.split(',').last), 
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image_outlined)),
                        )
                      : CachedNetworkImage(
                          imageUrl: product.imageUrl.isNotEmpty ? product.imageUrl : 'https://placehold.co/800x600',
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(color: Colors.grey[100]),
                          errorWidget: (c, u, e) => Container(color: AshallTheme.primaryColor, child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 50)),
                        ),
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -30, 0),
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 25),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.category, style: TextStyle(color: AshallTheme.secondaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                                const SizedBox(height: 8),
                                Text(product.name, style: AshallTheme.titleStyle.copyWith(fontSize: 28, height: 1.1)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 18),
                                    SizedBox(width: 4),
                                    Text("4.9", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12, backgroundColor: AshallTheme.primaryColor.withValues(alpha: 0.1),
                            child: const Icon(Icons.store, size: 14, color: AshallTheme.primaryColor),
                          ),
                          const SizedBox(width: 8),
                          Text(product.merchantName, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          const Text("بائع موثوق", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      
                      const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider(height: 1)),
                      
                      Text("عن المنتج", style: AshallTheme.titleStyle.copyWith(fontSize: 18)),
                      const SizedBox(height: 12),
                      Text(
                        product.description.isNotEmpty ? product.description : "نقدم لك هذا المنتج بأفضل جودة وسعر منافس. تم اختياره بعناية لضمان رضائك التام مع نظام أسهل للتوصيل السريع والآمن.",
                        style: AshallTheme.bodyStyle.copyWith(height: 1.8, color: Colors.black54, fontSize: 15),
                      ),
                      
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: AshallTheme.backgroundColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withValues(alpha: 0.1))),
                        child: Row(
                          children: [
                            const Icon(Icons.delivery_dining, color: AshallTheme.primaryColor),
                            const SizedBox(width: 15),
                            const Expanded(child: Text("توصيل سريع مجاني للطلبات فوق 5000", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                            const Icon(Icons.chevron_left, color: Colors.grey),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 150), // Extra space for button
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Custom Top Bar with Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: GlassContainer(
                    blur: 10, borderRadius: 15, padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: GlassContainer(
                    blur: 10, borderRadius: 15, padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Cart Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("إجمالي السعر", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        Consumer<SystemSettingsProvider>(
                          builder: (_, s, _) => Text("${product.price} ${s.settings.currencySymbol}", style: TextStyle(color: AshallTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 22)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: PremiumButton(
                      text: "أضف للسلة",
                      icon: Icons.add_shopping_cart,
                      onPressed: () {
                        bool added = Provider.of<CartProvider>(context, listen: false).addItem(product.id, product.name, product.price, product.merchantId);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(added ? "تمت الإضافة!" : "موجود بالفعل في السلة"),
                          backgroundColor: added ? AshallTheme.successColor : Colors.orange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
