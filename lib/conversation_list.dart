import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:markdown_widget/markdown_widget.dart';

import 'chat_provider.dart';

class ConversationList extends StatelessWidget {
  const ConversationList({super.key});

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
              return MessageBox(message: message);
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

class MessageBox extends StatefulWidget {
  final Message message;

  const MessageBox({super.key, required this.message});

  @override
  State<MessageBox> createState() => _MessageBoxState();
}

class _MessageBoxState extends State<MessageBox> {
  bool showToolbar = false;

  @override
  Widget build(BuildContext context) {
    var alignment = Alignment.center;
    var color = Colors.black;
    var hasToolbar = false;
    var padding = EdgeInsets.zero;
    Widget? leading;

    switch (widget.message.role) {
      case 'user':
        padding = const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 4.0);
        leading = const Column(children: []);
        alignment = Alignment.centerRight;
        color = Colors.blue[100]!;
        hasToolbar = false;
        break;
      case 'assistant':
        padding = const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0);
        leading = const Icon(Icons.auto_awesome);
        alignment = Alignment.centerLeft;
        color = Colors.transparent;
        hasToolbar = true;
        break;
      default:
        log('Unknown role: ${widget.message.role}');
    }

    return ListTile(
      leading: leading,
      titleAlignment: ListTileTitleAlignment.top,
      title: Align(
        alignment: alignment,
        child: MouseRegion(
          onEnter: (_) => setState(() => showToolbar = true),
          onExit: (_) => setState(() => showToolbar = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: MarkdownBlock(
                  data: widget.message.content,
                  //style: const TextStyle(color: Colors.white),
                ),
              ),
              Visibility(
                maintainSize: hasToolbar,
                maintainAnimation: true,
                maintainState: true,
                visible: showToolbar && hasToolbar,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => {
                        Clipboard.setData(
                          ClipboardData(text: widget.message.content),
                        )
                      },
                      icon: const Icon(Icons.copy, size: 20),
                      constraints: const BoxConstraints(),
                      tooltip: 'Copy',
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
