import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessage {
  final String senderId;
  final String content;
  final DateTime timestamp;

  SupportMessage({required this.senderId, required this.content, required this.timestamp});

  Map<String, dynamic> toMap() => {'senderId': senderId, 'content': content, 'timestamp': timestamp};
  factory SupportMessage.fromMap(Map<String, dynamic> map) => SupportMessage(
      senderId: map['senderId'], content: map['content'], timestamp: (map['timestamp'] as Timestamp).toDate());
}

class SupportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Send support request
  Future<void> sendSupportMessage(String userId, String content) async {
    await _db.collection('support_chats').doc(userId).collection('messages').add({
      'senderId': userId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Update main chat flag
    await _db.collection('support_chats').doc(userId).set({
      'userId': userId,
      'lastUpdate': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1)
    }, SetOptions(merge: true));
  }

  // Stream messages
  Stream<List<SupportMessage>> getMessages(String userId) {
    return _db.collection('support_chats').doc(userId).collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots().map((snap) =>
        snap.docs.map((doc) => SupportMessage.fromMap(doc.data())).toList());
  }

  // Admin: Get all active chats
  Stream<List<Map<String, dynamic>>> getActiveChats() {
    return _db.collection('support_chats').orderBy('lastUpdate', descending: true)
      .snapshots().map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}
