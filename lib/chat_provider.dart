import 'dart:async';
import 'dart:developer';

import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_openai/dart_openai.dart';

class Message {
  final String role;
  final String id;
  String content;

  Message({required this.role, required this.content}) : id = const Uuid().v7();

  OpenAIChatCompletionChoiceMessageModel toOpenAIMessage() {
    return OpenAIChatCompletionChoiceMessageModel(
      role: OpenAIChatMessageRole.values.firstWhere(
        (e) => e.toString().endsWith('.$role'),
        orElse: () => OpenAIChatMessageRole.user,
      ),
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(content)
      ],
    );
  }
}

class ChatSettings {
  final String name;
  final String model;
  final String systemPrompt;

  static const defaultChatSettings = ChatSettings(
      name: 'gpt-3.5-turbo', model: 'gpt-3.5-turbo', systemPrompt: '');

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

  final List<ChatSettings> _profiles = [
    ChatSettings.defaultChatSettings,
    const ChatSettings(name: 'gpt-4o', model: 'gpt-4o', systemPrompt: ''),
    const ChatSettings(
      name: 'ChatGPT Test',
      model: 'gpt-4o',
      systemPrompt:
          'You are ChatGPT, a large language model trained by OpenAI.',
    ),
  ];
  ChatSettings _currentProfile = ChatSettings.defaultChatSettings;

  List<ChatSettings> get profiles => _profiles;
  ChatSettings get currentProfile => _currentProfile;

  final List<Conversation> _conversations = [];
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
      OpenAI.apiKey = _apiKey!;
      log('API key loaded.');
    }
  }

  void setApiKey(String apiKey) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('api_key', apiKey);
    OpenAI.apiKey = _apiKey = apiKey;

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
    log('Current profile set to ${profile.name}.');
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
      final context = [..._currentConversation!.messages];

      _pendingMessage = Message(role: "assistant", content: "");
      addMessageToCurrentConversation(_pendingMessage!);

      _streamResponse(context);
    }
  }

  Future<void> _streamResponse(List<Message> context) async {
    _pendingMessage!.content = '';
    notifyListeners();

    final messages = context.map((m) => m.toOpenAIMessage()).toList();

    // Add system prompt if available
    if (_currentProfile.systemPrompt.isNotEmpty) {
      log('System prompt: ${_currentProfile.systemPrompt}');

      messages.insert(
        0,
        Message(role: 'system', content: _currentProfile.systemPrompt)
            .toOpenAIMessage(),
      );
    }

    final chatStream = OpenAI.instance.chat.createStream(
      model: _currentProfile.model,
      messages: messages,
    );

    final completer = Completer<bool>();

    final subscriber = chatStream.listen(
      (streamChatCompletion) {
        if (_interruptFlag) {
          completer.complete(false);
          return;
        }

        final newContent = streamChatCompletion.choices.first.delta.content;
        _pendingMessage!.content += newContent?.first?.text ?? '';
        notifyListeners();
      },
      onDone: () {
        completer.complete(true);
      },
      onError: (error) {
        log('Error: $error');
        completer.completeError(error);
      },
      cancelOnError: true,
    );

    final chatFinished = await completer.future;

    if (!chatFinished) {
      await subscriber.cancel();
      log('Chat was interrupted.');
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
