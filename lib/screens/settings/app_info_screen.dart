import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/system_settings_provider.dart';
import '../../utils/style_constants.dart';

class AppInfoScreen extends StatelessWidget {
  final bool isTerms;
  const AppInfoScreen({super.key, required this.isTerms});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SystemSettingsProvider>(context).settings;
    final title = isTerms ? "الشروط والأحكام" : "عن التطبيق";
    final content = isTerms ? settings.termsOfService : settings.aboutApp;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AshallTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: content.trim().isEmpty
          ? const Center(
              child: Text(
                "لا توجد معلومات متاحة حالياً.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : Markdown(
              data: content,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(25),
            ),
    );
  }
}
