import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/article_provider.dart';

class ModelSettingsTab extends StatelessWidget {
  const ModelSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticleProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Model:'),
            controller: TextEditingController(text: provider.settings.model),
            onChanged: (value) => provider.updateSettings(model: value),
          ),
          // ... other settings
        ],
      ),
    );
  }
}
