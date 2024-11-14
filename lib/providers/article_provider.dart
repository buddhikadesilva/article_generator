import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/article_settings.dart';
import 'package:http/http.dart' as http;

class ArticleProvider with ChangeNotifier {
  final ArticleSettings settings = ArticleSettings();
  final TextEditingController topicController = TextEditingController();
  final TextEditingController outputController = TextEditingController();

  bool _isGenerating = false;
  String _progressStatus = 'Ready';

  bool get isGenerating => _isGenerating;
  String get progressStatus => _progressStatus;

  // Model settings
  final String _model = 'llama3';
  final String _temperature = '0.7';
  final String _maxTokens = '2000';
  final String _topP = '0.9';
  final String _serverUrl = 'http://localhost:11434';
  final bool _enableStreaming = true;

  // Article settings
  final String _writingStyle = 'Professional';
  final String _tone = 'Neutral';
  final String _length = 'Medium';

  // Format settings
  final double _fontSize = 11;
  final bool _wordWrap = true;

  void updateSettings({
    String? model,
    String? temperature,
    String? maxTokens,
    String? topP,
    String? serverUrl,
    bool? enableStreaming,
    String? writingStyle,
    String? tone,
    String? length,
    double? fontSize,
    bool? wordWrap,
  }) {
    if (model != null) settings.model = model;
    if (temperature != null) settings.temperature = temperature;
    if (maxTokens != null) settings.maxTokens = maxTokens;
    if (topP != null) settings.topP = topP;
    if (serverUrl != null) settings.serverUrl = serverUrl;
    if (enableStreaming != null) settings.enableStreaming = enableStreaming;
    if (writingStyle != null) settings.writingStyle = writingStyle;
    if (tone != null) settings.tone = tone;
    if (length != null) settings.length = length;
    if (fontSize != null) settings.fontSize = fontSize;
    if (wordWrap != null) settings.wordWrap = wordWrap;
    notifyListeners();
  }

  // Add your existing generation methods here, modified to use the provider
  Future<void> generateArticle() async {
    if (topicController.text.trim().isEmpty) {
      throw Exception('Please enter a topic');
    }

    _isGenerating = true;
    _progressStatus = 'Generating article...';
    outputController.clear();
    notifyListeners();

    try {
      final prompt = _createPrompt();
      if (settings.enableStreaming) {
        await _handleStreamingGeneration(prompt);
      } else {
        await _handleSingleGeneration(prompt);
      }
    } catch (e) {
      _progressStatus = 'Error: ${e.toString()}';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // ... Add other methods from your original class, modified to use the provider

  String _createPrompt() {
    return '''Write a ${_length.toLowerCase()} article about ${topicController.text}.
    Style: $_writingStyle
    Tone: $_tone
    
    The article should be well-structured with:
    - An engaging introduction
    - Well-organized main body paragraphs
    - A meaningful conclusion
    
    Make it informative and maintain a ${_writingStyle.toLowerCase()} tone throughout.''';
  }

  Future<void> _handleStreamingGeneration(String prompt) async {
    final url = Uri.parse('$_serverUrl/api/generate');
    final request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'model': _model,
      'prompt': prompt,
      'stream': true,
      'temperature': double.parse(_temperature),
      'top_p': double.parse(_topP),
      'max_tokens': int.parse(_maxTokens),
    });

    final response = await request.send();
    String accumulatedText = '';

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      if (!_isGenerating) break;

      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.isEmpty) continue;
        try {
          final json = jsonDecode(line);
          if (json['response'] != null) {
            accumulatedText += json['response'];
            //    setState(() {
            outputController.text = accumulatedText;
            //   });
          }
        } catch (e) {
          print('Error parsing JSON: $e');
        }
      }
    }

    if (_isGenerating) {
      // setState(() {
      _progressStatus = 'Article generated successfully!';
      //  });
    }
  }

  Future<void> _handleSingleGeneration(String prompt) async {
    final response = await http.post(
      Uri.parse('$_serverUrl/api/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': _model,
        'prompt': prompt,
        'stream': false,
        'temperature': double.parse(_temperature),
        'top_p': double.parse(_topP),
        'max_tokens': int.parse(_maxTokens),
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      //setState(() {
      outputController.text = json['response'];
      _progressStatus = 'Article generated successfully!';
      //});
    } else {
      throw Exception('Failed to generate article: ${response.statusCode}');
    }
  }

  Future<void> _saveArticle(BuildContext context) async {
    if (outputController.text.trim().isEmpty) {
      _showWarning('No article to save', context);
      return;
    }

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Article',
        fileName:
            'article_${DateTime.now().toString().replaceAll(':', '-')}.txt',
        allowedExtensions: ['txt', 'md'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(outputController.text);
        //  setState(() {
        _progressStatus = 'Article saved successfully!';
        // });
      }
    } catch (e) {
      _showError('Failed to save file: $e', context);
    }
  }

  void _copyToClipboard(BuildContext context) {
    if (outputController.text.trim().isEmpty) {
      _showWarning('No article to copy', context);
      return;
    }

    Clipboard.setData(ClipboardData(text: outputController.text));
    // setState(() {
    _progressStatus = 'Article copied to clipboard';
    // });
  }

  void _showWarning(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  void _showError(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
