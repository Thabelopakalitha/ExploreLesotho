// lib/services/chat_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/conversation.dart';
import '../models/message.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class ChatRecipient {
  final String id;
  final String name;
  final String role;
  final String? email;

  ChatRecipient({
    required this.id,
    required this.name,
    required this.role,
    this.email,
  });

  factory ChatRecipient.fromJson(Map<String, dynamic> json) {
    return ChatRecipient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown User',
      role: json['role']?.toString() ?? 'tourist',
      email: json['email']?.toString(),
    );
  }
}

class ChatService {
  final String baseUrl = Constants.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Conversation>> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversations'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final conversations = (data['conversations'] as List? ?? [])
          .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
          .toList();
      return conversations;
    } catch (_) {
      return [];
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversations/$conversationId/messages'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return (data['messages'] as List? ?? [])
          .map((item) => Message.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ChatRecipient>> getRecipients() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/recipients'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return (data['recipients'] as List? ?? [])
          .map((item) => ChatRecipient.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Conversation?> createConversation({
    required String participantId,
    String? listingId,
    String? bookingId,
    String? initialMessage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/conversations'),
        headers: await _getHeaders(),
        body: json.encode({
          'participantId': participantId,
          'listingId': listingId,
          'bookingId': bookingId,
          'initialMessage': initialMessage,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final conversation = data['conversation'];
      if (conversation is! Map<String, dynamic>) {
        return null;
      }
      return Conversation.fromJson(conversation);
    } catch (_) {
      return null;
    }
  }

  Future<Message?> sendMessage({
    required String conversationId,
    required String content,
    String contentType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/conversations/$conversationId/messages'),
        headers: await _getHeaders(),
        body: json.encode({
          'content': content,
          'contentType': contentType,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final message = data['message'];
      if (message is! Map<String, dynamic>) {
        return null;
      }
      return Message.fromJson(message);
    } catch (_) {
      return null;
    }
  }

  Future<bool> markConversationAsRead(String conversationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/conversations/$conversationId/read'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/chat/conversations/$conversationId'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
