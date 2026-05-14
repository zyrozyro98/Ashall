import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../utils/style_constants.dart';

class SupportChatScreen extends StatefulWidget {
  final String userId;
  final String? adminId;
  const SupportChatScreen({super.key, required this.userId, this.adminId});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final SupportService _support = SupportService();
  final _msgC = TextEditingController();
  late final String _viewerId;

  @override
  void initState() {
    super.initState();
    _viewerId = widget.adminId ?? widget.userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.adminId != null ? "الرد على العملاء" : "الدعم المباشر"),
        backgroundColor: AshallTheme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: _support.getMessages(widget.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snapshot.data!;
                if (msgs.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      const Text("لا توجد رسائل حالياً", style: TextStyle(color: Colors.grey)),
                    ],
                  ));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    bool isMe = m.senderId == _viewerId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? AshallTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: Radius.circular(isMe ? 15 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 15),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(m.content, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(
                              "${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}", 
                              style: TextStyle(color: isMe ? Colors.white70 : Colors.grey[400], fontSize: 10)
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 25),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgC,
                    decoration: InputDecoration(
                      hintText: "اكتب رسالتك...",
                      fillColor: Colors.grey[100], filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  backgroundColor: AshallTheme.primaryColor,
                  elevation: 2,
                  onPressed: () {
                    if (_msgC.text.trim().isNotEmpty) {
                      _support.sendSupportMessage(widget.userId, _msgC.text.trim(), senderId: _viewerId);
                      _msgC.clear();
                    }
                  },
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
