import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'chat_provider.dart';
import 'conversation_list.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Expanded(
            flex: 4,
            child: ConversationList(),
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
              tooltip: 'Interrupt',
              onPressed: _interrupt,
            )
          : IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'Send',
              onPressed: _send,
            ),
    ]);
  }
}
