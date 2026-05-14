import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../providers/system_settings_provider.dart';
import '../../../models/app_user.dart';
import '../../../utils/style_constants.dart';
import '../../../widgets/premium_ui.dart';

class AdminUserManagement extends StatefulWidget {
  const AdminUserManagement({super.key});

  @override
  State<AdminUserManagement> createState() => _AdminUserManagementState();
}

class _AdminUserManagementState extends State<AdminUserManagement> {
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
        // Premium Search Section
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: PremiumTextField(
            label: "البحث في قاعدة البيانات", 
            controller: _searchController, 
            icon: Icons.search_rounded,
            hint: "ابحث بالاسم أو البريد...",
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final allUsers = snapshot.data!.docs
                .map((doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>))
                .where((u) => u.name.toLowerCase().contains(_searchQuery) || u.email.toLowerCase().contains(_searchQuery))
                .toList();

              if (allUsers.isEmpty) return const Center(child: Text("لا توجد نتائج بحث"));

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: allUsers.length,
                itemBuilder: (context, i) {
                  final u = allUsers[i];
                  Color roleColor = _getRoleColor(u.role);
                  return PremiumCard(
                    padding: const EdgeInsets.all(10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(_getRoleIcon(u.role), color: roleColor, size: 24),
                      ),
                      title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              PremiumBadge(text: u.role.name.toUpperCase(), color: roleColor),
                              const SizedBox(width: 10),
                              Text("${u.balance} ${Provider.of<SystemSettingsProvider>(context).settings.currencySymbol}", style: TextStyle(fontWeight: FontWeight.w900, color: AshallTheme.secondaryColor, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      trailing: _buildActionsMenu(context, u),
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.customer: return Colors.blue;
      case UserRole.merchant: return Colors.orange;
      case UserRole.driver: return Colors.green;
      case UserRole.admin: return Colors.red;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.customer: return Icons.person_rounded;
      case UserRole.merchant: return Icons.storefront_rounded;
      case UserRole.driver: return Icons.delivery_dining_rounded;
      case UserRole.admin: return Icons.admin_panel_settings_rounded;
    }
  }

  Widget _buildActionsMenu(BuildContext context, AppUser user) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'role', child: ListTile(dense: true, leading: Icon(Icons.shield_outlined), title: Text("تغيير الدور"))),
        const PopupMenuItem(value: 'balance', child: ListTile(dense: true, leading: Icon(Icons.account_balance_wallet_outlined), title: Text("تعديل الرصيد"))),
        const PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline, color: Colors.red), title: Text("حظر / حذف المستخدم", style: TextStyle(color: Colors.red)))),
      ],
      onSelected: (val) {
        if (val == 'role') _showRoleChange(context, user);
        if (val == 'balance') _showBalanceEdit(context, user);
        if (val == 'delete') _showDeleteConfirmation(context, user);
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف", style: TextStyle(color: Colors.red)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text("هل أنت متأكد من حذف المستخدم أو حظره؟ سيتم مسح بياناته من النظام (\n${user.name}\n)."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: PremiumButton(
              text: "نعم، متأكد",
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حذف المستخدم بنجاح"), backgroundColor: Colors.red));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleChange(BuildContext context, AppUser user) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("تحديث صلاحيات المستخدم"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: UserRole.values.map((r) => ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: user.role == r ? const Icon(Icons.check_circle, color: Colors.green) : null,
          onTap: () async {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'role': r.index});
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        )).toList(),
      ),
    ));
  }

  void _showBalanceEdit(BuildContext context, AppUser user) {
    final controller = TextEditingController(text: user.balance.toString());
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("تعديل الرصيد"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: PremiumTextField(label: "المبلغ الجديد", controller: controller, icon: Icons.attach_money, keyboardType: TextInputType.number),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: PremiumButton(
            text: "حفظ", 
            onPressed: () async {
              double? amount = double.tryParse(controller.text);
              if (amount != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'balance': amount});
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ),
      ],
    ));
  }
}
