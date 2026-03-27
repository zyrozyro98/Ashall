import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/style_constants.dart';
import '../widgets/premium_ui.dart';

import 'customer/wallet_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("الملف الشخصي"), backgroundColor: AshallTheme.primaryColor),
      body: FutureBuilder(
        future: auth.getUserData(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const CircleAvatar(radius: 60, backgroundColor: AshallTheme.primaryColor, child: Icon(Icons.person, size: 80, color: Colors.white)),
                const SizedBox(height: 20),
                Text(user.name, style: AshallTheme.titleStyle),
                Text(user.email, style: AshallTheme.subtitleStyle),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(color: AshallTheme.secondaryColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(user.role.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                PremiumButton(
                  text: "محفظتي",
                  icon: Icons.account_balance_wallet,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WalletScreen(userId: user.uid))),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    auth.signOut();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text("تسجيل الخروج", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
