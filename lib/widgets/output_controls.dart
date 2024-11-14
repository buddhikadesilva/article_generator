import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/article_provider.dart';

class OutputPanel extends StatelessWidget {
  const OutputPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticleProvider>();

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Topic Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: provider.topicController,
              decoration: const InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: provider.isGenerating
                      ? null
                      : () => provider.generateArticle(),
                  child: Text(
                      provider.isGenerating ? 'Generating...' : 'Generate'),
                ),
                const SizedBox(width: 8),
                Text(provider.progressStatus),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    // Implement copy functionality
                  },
                ),
                IconButton(
                  icon: Icon(provider.settings.wordWrap
                      ? Icons.wrap_text
                      : Icons.wrap_text_outlined),
                  onPressed: () => provider.updateSettings(
                      wordWrap: !provider.settings.wordWrap),
                ),
                IconButton(
                  icon: const Icon(Icons.text_fields),
                  onPressed: () {
                    // Implement font size adjustment
                  },
                ),
              ],
            ),
          ),
          // Output TextField
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: provider.outputController,
                maxLines: null,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: provider.settings.fontSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
