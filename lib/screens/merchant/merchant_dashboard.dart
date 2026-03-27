import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';
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
  final StorageService _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("لوحة التحكم التاجر", style: AshallTheme.titleStyle.copyWith(color: Colors.white)),
        backgroundColor: AshallTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: AshallTheme.secondaryColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MerchantOrdersScreen(merchantId: widget.uid))),
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: AshallTheme.secondaryColor),
            onPressed: () => _addProductDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: AshallTheme.secondaryColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: widget.uid))),
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _db.getMerchantProducts(widget.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                child: ListTile(
                  leading: p.imageUrl.isNotEmpty 
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p.imageUrl, width: 50, height: 50, fit: BoxFit.cover))
                    : const Icon(Icons.shopping_bag, size: 40, color: AshallTheme.primaryColor),
                  title: Text(p.name, style: AshallTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text("${p.price} AED"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _db.deleteProduct(p.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _addProductDialog(BuildContext context) {
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final descC = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("إضافة صنف جديد"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setDialogState(() => selectedImage = File(pickedFile.path));
                    }
                  },
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
                    child: selectedImage == null 
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt), Text("اختر صورة")])
                      : Image.file(selectedImage!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 15),
                PremiumTextField(label: "اسم الصنف", controller: nameC),
                const SizedBox(height: 10),
                PremiumTextField(label: "السعر", controller: priceC),
                const SizedBox(height: 10),
                PremiumTextField(label: "الوصف", controller: descC),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
            PremiumButton(
              text: "إضافة",
              onPressed: () async {
                String imageUrl = '';
                String tempId = DateTime.now().millisecondsSinceEpoch.toString();
                
                if (selectedImage != null) {
                  imageUrl = await _storage.uploadProductImage(selectedImage!, tempId) ?? '';
                }

                await _db.addProduct(Product(
                  id: tempId, 
                  merchantId: widget.uid, 
                  merchantName: 'My Store', 
                  name: nameC.text, 
                  description: descC.text, 
                  price: double.tryParse(priceC.text) ?? 0.0, 
                  imageUrl: imageUrl
                ));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
