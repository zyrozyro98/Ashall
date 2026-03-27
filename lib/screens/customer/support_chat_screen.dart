import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../utils/style_constants.dart';
import '../../widgets/premium_ui.dart';

class SupportChatScreen extends StatefulWidget {
  final String userId;
  const SupportChatScreen({super.key, required this.userId});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final SupportService _support = SupportService();
  final _msgC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الدعم الفني"),
        backgroundColor: AshallTheme.primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: _support.getMessages(widget.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    bool isMe = m.senderId == widget.userId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AshallTheme.primaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(m.content, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(child: PremiumTextField(label: "اكتب رسالتك...", controller: _msgC)),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send, color: AshallTheme.primaryColor, size: 30),
                  onPressed: () {
                    if (_msgC.text.isNotEmpty) {
                      _support.sendSupportMessage(widget.userId, _msgC.text);
                      _msgC.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
