import 'dart:async';
import '../../../core/services/api_service.dart';
import '../models/message_model.dart';

class ChatController {
  final _api = ApiService.instance;

  /// Fetch messages via Django REST API
  Future<List<MessageModel>> fetchMessages({required String otherUserId}) async {
    return await _api.fetchMessages(otherUserId);
  }

  /// Stream messages between two users in real-time using Django REST API
  Stream<List<MessageModel>> getMessagesStream({
    required String currentUserId,
    required String otherUserId,
  }) async* {
    while (true) {
      try {
        final messages = await _api.fetchMessages(otherUserId);
        yield messages;
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;
    return await _api.sendMessage(
      receiverId: receiverId,
      content: content.trim(),
    );
  }
}
