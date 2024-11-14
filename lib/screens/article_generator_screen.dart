import 'package:flutter/material.dart';

import '../widgets/article_settings_tab.dart';
import '../widgets/model_settings_tab.dart';
import '../widgets/output_controls.dart';

class ArticleGeneratorScreen extends StatelessWidget {
  const ArticleGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Advanced AI Article Generator'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Model Settings'),
              Tab(text: 'Article Settings'),
            ],
          ),
        ),
        body: const Row(
          children: [
            // Left panel - Settings
            Expanded(
              flex: 1,
              child: Card(
                margin: EdgeInsets.all(8.0),
                child: TabBarView(
                  children: [
                    ModelSettingsTab(),
                    ArticleSettingsTab(),
                  ],
                ),
              ),
            ),
            // Right panel - Output
            Expanded(
              flex: 2,
              child: OutputPanel(),
            ),
          ],
        ),
      ),
    );
  }
}
