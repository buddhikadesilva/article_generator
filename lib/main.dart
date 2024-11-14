import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/article_provider.dart';
import 'screens/article_generator_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ArticleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced AI Article Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ArticleGeneratorScreen(),
    );
  }
}
