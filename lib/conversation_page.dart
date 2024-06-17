import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_list_view/flutter_list_view.dart';

import 'chat_provider.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Expanded(
            flex: 4,
            child: ConversationBox(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: MessageInputBar()),
          ),
        ],
      ),
    );
  }
}

class ConversationBox extends StatelessWidget {
  const ConversationBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.currentConversation == null) {
          return Center(
            child: Text((chatProvider.apiKey == null)
                ? 'API key not set. Please set an API key in the settings.'
                : 'No conversation selected.'),
          );
        }

        final itemCount = chatProvider.currentConversation!.messages.length;

        return FlutterListView(
          reverse: true,
          delegate: FlutterListViewDelegate(
            (BuildContext context, int index) {
              final message = chatProvider
                  .currentConversation!.messages[itemCount - 1 - index];

              var alignment = Alignment.center;
              var color = Colors.black;

              switch (message.role) {
                case 'user':
                  alignment = Alignment.centerRight;
                  color = Colors.grey;
                  break;
                case 'assistant':
                  alignment = Alignment.centerLeft;
                  color = Colors.blueAccent;
                  break;
                default:
                  log('Unknown role: ${message.role}');
              }

              return ListTile(
                title: Align(
                  alignment: alignment,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: SelectableText(
                      message.content,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
            childCount: chatProvider.currentConversation!.messages.length,
            keepPosition: true,
            keepPositionOffset: 80,
            onItemKey: (index) => chatProvider
                .currentConversation!.messages[itemCount - 1 - index].id,
          ),
        );
      },
    );
  }
}

class MessageInputBar extends StatelessWidget {
  MessageInputBar({super.key});

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    void send() {
      if (_controller.text.isNotEmpty) {
        context.read<ChatProvider>().sendUserMessage(_controller.text);
        _controller.clear();
      }
    }

    void interrupt() {
      context.read<ChatProvider>().interruptPendingMessage();
    }

    return Row(children: [
      Expanded(
        child: TextField(
          controller: _controller,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Type a message...',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      context.watch<ChatProvider>().hasPendingMessage
          ? IconButton(
              icon: const Icon(Icons.stop_circle),
              onPressed: interrupt,
            )
          : IconButton(
              icon: const Icon(Icons.send),
              onPressed: send,
            ),
    ]);
  }
}
