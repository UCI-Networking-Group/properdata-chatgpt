import 'dart:developer';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Message {
  final String role;
  final String id;
  String content;

  Message({required this.role, required this.content}) : id = const Uuid().v7();
}

class ChatSettings {
  final String name;
  final String model;
  final String systemPrompt;

  static const defaultChatSettings =
      ChatSettings(name: 'default', model: 'gpt-3.5-turbo', systemPrompt: '');

  const ChatSettings({this.name = '', this.model = '', this.systemPrompt = ''});
}

class Conversation {
  final String id;
  final String title;
  final List<Message> messages;

  Conversation({required this.id, required this.title, required this.messages});
}

class ChatProvider with ChangeNotifier {
  String? _apiKey = '';
  String? get apiKey => _apiKey;

  List<ChatSettings> _profiles = [
    ChatSettings.defaultChatSettings,
    ChatSettings(name: 'gpt-4o', model: 'gpt-4o', systemPrompt: ''),
  ];
  ChatSettings _currentProfile = ChatSettings.defaultChatSettings;

  List<ChatSettings> get profiles => _profiles;
  ChatSettings get currentProfile => _currentProfile;

  List<Conversation> _conversations = [];
  Conversation? _currentConversation;

  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;

  Message? _pendingMessage; // the message that is currently being updated
  bool get hasPendingMessage => _pendingMessage != null;
  bool _interruptFlag = false;

  ChatProvider(SharedPreferences prefs) {
    _apiKey = prefs.getString('api_key');

    if (_apiKey == null || _apiKey == '') {
      _apiKey = null;
      log('API key is not set.');
    } else {
      log('API key loaded.');
    }
  }

  void setApiKey(String apiKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('api_key', apiKey);
    _apiKey = apiKey;

    log('API key is set.');
  }

  void createConversation() {
    var uuid = const Uuid();
    var title = 'Chat 1';

    for (final conversation in _conversations) {
      final titleRegex = RegExp(r'Chat (\d+)');
      final match = titleRegex.firstMatch(conversation.title);

      if (match != null && conversation.title.compareTo(title) >= 0) {
        final number = int.parse(match.group(1)!);
        title = 'Chat ${number + 1}';
      }
    }

    final newConversation = Conversation(
      id: uuid.v7().toString(),
      title: title,
      messages: [],
    );

    _conversations.add(newConversation);
    _currentConversation = newConversation;
    notifyListeners();
  }

  void setCurrentProfile(ChatSettings profile) {
    _currentProfile = profile;
    notifyListeners();
  }

  void setCurrentConversation(String id) {
    log('Setting current conversation to $id');
    _currentConversation = _conversations.firstWhere((conv) => conv.id == id);
    notifyListeners();
  }

  void addMessageToCurrentConversation(Message message) {
    _currentConversation?.messages.add(message);
    notifyListeners();
  }

  void sendUserMessage(String content) {
    if (_currentConversation == null) {
      createConversation();
    }

    addMessageToCurrentConversation(Message(role: 'user', content: content));

    if (_pendingMessage == null) {
      _pendingMessage = Message(role: "assistant", content: "");
      addMessageToCurrentConversation(_pendingMessage!);
      _updatePendingMessage();
    }
  }

  Future<void> _updatePendingMessage() async {
    _pendingMessage!.content = '';
    notifyListeners();

    // Simulate a response from the assistant
    for (var character in 'This is a response.'.split('')) {
      _pendingMessage!.content += character;
      await Future.delayed(const Duration(milliseconds: 100));
      notifyListeners();

      if (_interruptFlag) break;
    }

    _pendingMessage = null;
    _interruptFlag = false;
    notifyListeners();
  }

  void interruptPendingMessage() {
    if (_pendingMessage != null) _interruptFlag = true;
  }

  void clearAllConversations() {
    _conversations.clear();
    _currentConversation = null;
    notifyListeners();
  }
}
