import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/article_provider.dart';

class ArticleSettingsTab extends StatelessWidget {
  const ArticleSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticleProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownField(
            'Writing Style:',
            provider.settings.writingStyle,
            ['Professional', 'Casual', 'Academic', 'Creative'],
            (value) => provider.updateSettings(writingStyle: value),
          ),
          _buildDropdownField(
            'Tone:',
            provider.settings.tone,
            ['Neutral', 'Formal', 'Friendly', 'Enthusiastic'],
            (value) => provider.updateSettings(tone: value),
          ),
          _buildDropdownField(
            'Length:',
            provider.settings.length,
            ['Short', 'Medium', 'Long'],
            (value) => provider.updateSettings(length: value),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
