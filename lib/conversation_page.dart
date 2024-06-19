import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:markdown_widget/markdown_widget.dart';

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
                child: const MessageInputBar()),
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
            child: Text((chatProvider.apiKey == '')
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
              Widget? leading;

              switch (message.role) {
                case 'user':
                  leading = const Column(children: []);
                  alignment = Alignment.centerRight;
                  color = Colors.blue[100]!;
                  break;
                case 'assistant':
                  leading = const Icon(Icons.auto_awesome);
                  alignment = Alignment.centerLeft;
                  color = Colors.transparent;
                  break;
                default:
                  log('Unknown role: ${message.role}');
              }

              return ListTile(
                leading: leading,
                titleAlignment: ListTileTitleAlignment.top,
                title: Align(
                  alignment: alignment,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 4.0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: MarkdownBlock(
                      data: message.content,
                      //style: const TextStyle(color: Colors.white),
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

class MessageInputBar extends StatefulWidget {
  const MessageInputBar({super.key});

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final TextEditingController _controller = TextEditingController();

  FocusNode? _focusNode;

  @override
  void initState() {
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.physicalKey == PhysicalKeyboardKey.enter &&
            !HardwareKeyboard.instance.physicalKeysPressed.any(
              (key) => <PhysicalKeyboardKey>{
                PhysicalKeyboardKey.shiftLeft,
                PhysicalKeyboardKey.shiftRight,
              }.contains(key),
            )) {
          // Enter (but not shift) pressed
          _send();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (_controller.text.isNotEmpty) {
      context.read<ChatProvider>().sendUserMessage(_controller.text);
      _controller.clear();
    }
  }

  void _interrupt() {
    context.read<ChatProvider>().interruptPendingMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _controller,
          keyboardType: TextInputType.multiline,
          focusNode: _focusNode,
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
              onPressed: _interrupt,
            )
          : IconButton(
              icon: const Icon(Icons.send),
              onPressed: _send,
            ),
    ]);
  }
}
