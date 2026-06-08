import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../models/order.dart';
import '../../../widgets/premium_ui.dart';

class AdminReviewManagement extends StatelessWidget {
  const AdminReviewManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PremiumSectionTitle(title: "مراجعات وتقييمات العملاء", icon: Icons.star_rate_rounded),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders')
                .where('rating', isGreaterThan: 0)
                .orderBy('rating', descending: false) // Lowest ratings first for attention
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.reviews_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text("لا توجد مراجعات حالياً", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                physics: const BouncingScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final order = AppOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                  final rating = (doc.data() as Map<String, dynamic>)['rating'] as num? ?? 0.0;
                  final feedback = (doc.data() as Map<String, dynamic>)['feedback'] as String? ?? 'لا يوجد تعليق مضاف';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
                      border: rating <= 2 ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1.5) : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            PremiumBadge(text: "طلب #${order.id.substring(0, 6)}", color: Colors.blueGrey),
                            RatingBarIndicator(
                              rating: rating.toDouble(),
                              itemBuilder: (context, index) => const Icon(Icons.star_rounded, color: Colors.amber),
                              itemCount: 5,
                              itemSize: 20.0,
                              direction: Axis.horizontal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          feedback,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: feedback == 'لا يوجد تعليق مضاف' ? Colors.grey : Colors.black87,
                            fontStyle: feedback == 'لا يوجد تعليق مضاف' ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("العميل", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                Text(order.customerId.substring(0, 8), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("التاجر", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                Text(order.merchantId.substring(0, 8), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("السائق", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                Text(order.driverId?.substring(0, 8) ?? 'غير محدد', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                FirebaseFirestore.instance.collection('orders').doc(order.id).update({
                                  'rating': FieldValue.delete(),
                                  'feedback': FieldValue.delete(),
                                });
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم إزالة المراجعة"), backgroundColor: Colors.red));
                              },
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                              tooltip: "حذف المراجعة",
                            ),
                          ],
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
}
