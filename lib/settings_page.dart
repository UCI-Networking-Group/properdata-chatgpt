import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chat_provider.dart';

class SettingsPage extends StatelessWidget {
  final TextEditingController _apiKeyController = TextEditingController();

  SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    _apiKeyController.text = context.read<ChatProvider>().apiKey;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text("OpenAI API Key"),
            onTap: () {},
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400, // Set your desired max width here
              ),
              child: TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    context.read<ChatProvider>().setApiKey(value);
                  }
                },
              ),
            ),
          ),
          ListTile(
            title: const Text('Reset Everything'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Everything'),
                  content: const Text(
                    'Are you sure you want to reset all settings? '
                    'This will clear all profiles and conversations.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        context.read<ChatProvider>().resetAll();
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      child: const Text('Yes'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('No'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
