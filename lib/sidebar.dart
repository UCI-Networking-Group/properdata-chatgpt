import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chat_provider.dart';
import 'settings_page.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey[200],
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: ProfileSelectionWidget(),
          ),
          const Expanded(
            child: ConversationList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
              child: const Text('Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationList extends StatelessWidget {
  const ConversationList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return ListView.builder(
          itemCount: chatProvider.conversations.length,
          itemBuilder: (context, index) {
            final conversationCount = chatProvider.conversations.length;
            final conversation =
                chatProvider.conversations[conversationCount - 1 - index];

            return Material(
              color: Colors.transparent,
              child: ListTile(
                title: Text(conversation.title),
                onTap: () {
                  chatProvider.setCurrentConversation(conversation.id);
                },
                selected:
                    identical(chatProvider.currentConversation, conversation),
                selectedTileColor: Colors.grey[300],
              ),
            );
          },
        );
      },
    );
  }
}

class ProfileSelectionWidget extends StatelessWidget {
  const ProfileSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        var items = chatProvider.profiles
            .map((ChatSettings item) => DropdownMenuItem<ChatSettings>(
                  value: item,
                  child: Text(item.name),
                ))
            .toList();

        return Row(children: [
          Expanded(
            child: DropdownButton<ChatSettings>(
              value: chatProvider.currentProfile,
              onChanged: (ChatSettings? newValue) {
                chatProvider.setCurrentProfile(newValue!);
              },
              items: items,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              chatProvider.createConversation();
            },
          ),
        ]);
      },
    );
  }
}
