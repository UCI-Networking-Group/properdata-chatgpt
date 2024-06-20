import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chat_provider.dart';

class ProfileManagementPage extends StatelessWidget {
  const ProfileManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (context, chatProvider, child) {
      final widgets = <Widget>[];

      widgets.add(Row(
        children: [
          ElevatedButton(
            child: const Text('New Profile'),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => ChatSettingsDialog(
                profile: ChatSettings(
                  name: 'New Profile',
                  model: ChatSettings.defaultProfiles[0].model,
                ),
              ),
            ),
          ),
        ],
      ));

      widgets.addAll(
          chatProvider.profiles.map<Widget>((e) => ProfileCard(e)).toList());

      return Scaffold(
        appBar: AppBar(title: const Text('Profile Management')),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [Wrap(children: widgets)],
            ),
          ),
        ),
      );
    });
  }
}

class ProfileCard extends StatelessWidget {
  final ChatSettings profile;

  const ProfileCard(this.profile, {super.key});

  @override
  Widget build(BuildContext context) {
    final buttonRow = <Widget>[
      TextButton(
        child: const Text('New Chat'),
        onPressed: () {
          context.read<ChatProvider>()
            ..setCurrentProfile(profile)
            ..createConversation();
          Navigator.pop(context);
        },
      )
    ];

    if (!profile.isDefault) {
      buttonRow.addAll([
        const SizedBox(width: 4),
        TextButton(
          child: const Text('Edit'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => ChatSettingsDialog(profile: profile),
            );
          },
        ),
        const SizedBox(width: 4),
        TextButton(
          child: const Text('Remove'),
          onPressed: () =>
              context.read<ChatProvider>().removeProfile(profile.id),
        ),
      ]);
    }

    return SizedBox(
      width: 400,
      child: Card(
        child: Column(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.album),
              title: Text(profile.name),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: buttonRow,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatSettingsDialog extends StatefulWidget {
  final ChatSettings profile;

  const ChatSettingsDialog({super.key, required this.profile});

  @override
  ChatSettingsDialogState createState() {
    return ChatSettingsDialogState();
  }
}

class ChatSettingsDialogState extends State<ChatSettingsDialog> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  final _formKey = GlobalKey<FormState>();

  String? name;
  String? model;
  String? systemPrompt;

  @override
  Widget build(BuildContext context) {
    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: widget.profile.name,
            decoration: const InputDecoration(
              labelText: 'Name',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 0.0),
              ),
            ),
            onChanged: (value) => name = value,
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: widget.profile.systemPrompt,
            decoration: const InputDecoration(
              labelText: 'System Prompt',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 0.0),
              ),
            ),
            keyboardType: TextInputType.multiline,
            minLines: 4,
            maxLines: 4,
            onChanged: (value) => systemPrompt = value,
          ),
          const SizedBox(height: 10),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Model',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 0.0),
              ),
            ),
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: widget.profile.model),
              optionsBuilder: (TextEditingValue textEditingValue) {
                return context
                    .read<ChatProvider>()
                    .modelList
                    .where((element) => element.contains(textEditingValue.text))
                    .toList();
              },
              onSelected: (value) => model = value,
            ),
          ),
        ],
      ),
    );

    return AlertDialog(
      title: const Text('Profile Settings'),
      content: SizedBox(
        width: 400,
        child: form,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final profile = ChatSettings(
              name: name ?? widget.profile.name,
              model: model ?? widget.profile.model,
              systemPrompt: systemPrompt ?? widget.profile.systemPrompt,
              id: widget.profile.id,
            );
            context.read<ChatProvider>().updateProfile(profile);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
