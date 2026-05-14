import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../providers/system_settings_provider.dart';
import '../../../models/product.dart';
import '../../../utils/style_constants.dart';
import '../../../widgets/premium_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminProductModeration extends StatefulWidget {
  const AdminProductModeration({super.key});

  @override
  State<AdminProductModeration> createState() => _AdminProductModerationState();
}

class _AdminProductModerationState extends State<AdminProductModeration> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Premium Search Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: PremiumTextField(
            label: "البحث في المنتجات", 
            controller: _searchController, 
            icon: Icons.search_rounded,
            hint: "اسم المنتج أو التاجر...",
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final allProducts = snapshot.data!.docs
                .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                .where((p) => p.name.toLowerCase().contains(_searchQuery) || p.merchantName.toLowerCase().contains(_searchQuery))
                .toList();

              if (allProducts.isEmpty) return const Center(child: Text("لا توجد منتجات"));

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  childAspectRatio: 0.72, 
                  crossAxisSpacing: 15, 
                  mainAxisSpacing: 5,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: allProducts.length,
                itemBuilder: (context, i) {
                  final p = allProducts[i];
                  return PremiumCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: CachedNetworkImage(
                                  imageUrl: p.imageUrl.isNotEmpty ? p.imageUrl : 'https://placehold.co/600x400',
                                  fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                                ),
                              ),
                              if (p.isPromoted)
                                const Positioned(
                                  top: 10, right: 10,
                                  child: PremiumBadge(text: "مهم", color: Colors.amber),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                              Text(p.merchantName, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${p.price} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", style: const TextStyle(color: AshallTheme.secondaryColor, fontWeight: FontWeight.w900, fontSize: 13)),
                                  _buildProductActions(context, p),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductActions(BuildContext context, Product p) {
    return PopupMenuButton(
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.more_horiz_rounded, size: 16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'promote', 
          child: ListTile(dense: true, leading: Icon(p.isPromoted ? Icons.star_border : Icons.star, color: Colors.amber), title: Text(p.isPromoted ? "إلغاء الترويج" : "ترقية المنتج"))
        ),
        PopupMenuItem(
          value: 'disable', 
          child: ListTile(dense: true, leading: Icon(p.isAvailable ? Icons.visibility_off_outlined : Icons.visibility_outlined), title: Text(p.isAvailable ? "إخفاء من المتجر" : "إظهار في المتجر"))
        ),
        const PopupMenuItem(
          value: 'delete', 
          child: ListTile(dense: true, leading: Icon(Icons.delete_outline, color: Colors.red), title: Text("حذف كلي", style: TextStyle(color: Colors.red)))
        ),
      ],
      onSelected: (val) async {
        if (val == 'promote') await FirebaseFirestore.instance.collection('products').doc(p.id).update({'isPromoted': !p.isPromoted});
        if (val == 'disable') await FirebaseFirestore.instance.collection('products').doc(p.id).update({'isAvailable': !p.isAvailable});
        if (val == 'delete') await FirebaseFirestore.instance.collection('products').doc(p.id).delete();
      },
    );
  }
}
