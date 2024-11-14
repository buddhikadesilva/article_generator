import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
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
      home: const ArticleGenerator(),
    );
  }
}

class ArticleGenerator extends StatefulWidget {
  const ArticleGenerator({super.key});

  @override
  ArticleGeneratorState createState() => ArticleGeneratorState();
}

class ArticleGeneratorState extends State<ArticleGenerator>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  // Model settings
  String _model = 'llama3';
  String _temperature = '0.7';
  String _maxTokens = '2000';
  String _topP = '0.9';
  String _serverUrl = 'http://localhost:11434';
  bool _enableStreaming = true;

  // Article settings
  String _writingStyle = 'Professional';
  String _tone = 'Neutral';
  String _length = 'Medium';

  // Format settings
  double _fontSize = 11;
  bool _wordWrap = true;

  bool _isGenerating = false;
  String _progressStatus = 'Ready';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  Future<void> _generateArticle() async {
    if (_topicController.text.trim().isEmpty) {
      _showWarning('Please enter a topic');
      return;
    }

    setState(() {
      _isGenerating = true;
      _progressStatus = 'Generating article...';
      _outputController.clear();
    });

    try {
      final prompt = _createPrompt();

      if (_enableStreaming) {
        await _handleStreamingGeneration(prompt);
      } else {
        await _handleSingleGeneration(prompt);
      }
    } catch (e) {
      setState(() {
        _progressStatus = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  String _createPrompt() {
    return '''Write a ${_length.toLowerCase()} article about ${_topicController.text}.
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
            setState(() {
              _outputController.text = accumulatedText;
            });
          }
        } catch (e) {
          print('Error parsing JSON: $e');
        }
      }
    }

    if (_isGenerating) {
      setState(() {
        _progressStatus = 'Article generated successfully!';
      });
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
      setState(() {
        _outputController.text = json['response'];
        _progressStatus = 'Article generated successfully!';
      });
    } else {
      throw Exception('Failed to generate article: ${response.statusCode}');
    }
  }

  Future<void> _saveArticle() async {
    if (_outputController.text.trim().isEmpty) {
      _showWarning('No article to save');
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
        await file.writeAsString(_outputController.text);
        setState(() {
          _progressStatus = 'Article saved successfully!';
        });
      }
    } catch (e) {
      _showError('Failed to save file: $e');
    }
  }

  void _copyToClipboard() {
    if (_outputController.text.trim().isEmpty) {
      _showWarning('No article to copy');
      return;
    }

    Clipboard.setData(ClipboardData(text: _outputController.text));
    setState(() {
      _progressStatus = 'Article copied to clipboard';
    });
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced AI Article Generator'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Model Settings'),
            Tab(text: 'Article Settings'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildModelSettings(),
                _buildArticleSettings(),
              ],
            ),
          ),
          _buildTopicSection(),
          _buildFormatControls(),
          Expanded(
            flex: 4,
            child: _buildOutputArea(),
          ),
          _buildControlButtons(),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildModelSettings() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingField(
              'Model:', _model, (value) => setState(() => _model = value)),
          _buildSettingField('Temperature:', _temperature,
              (value) => setState(() => _temperature = value)),
          _buildSettingField('Max Tokens:', _maxTokens,
              (value) => setState(() => _maxTokens = value)),
          _buildSettingField(
              'Top P:', _topP, (value) => setState(() => _topP = value)),
          _buildSettingField('Server URL:', _serverUrl,
              (value) => setState(() => _serverUrl = value)),
          SwitchListTile(
            title: const Text('Enable streaming'),
            value: _enableStreaming,
            onChanged: (value) => setState(() => _enableStreaming = value),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleSettings() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownSetting(
            'Writing Style:',
            _writingStyle,
            ['Professional', 'Casual', 'Academic', 'Creative'],
            (value) => setState(() => _writingStyle = value!),
          ),
          _buildDropdownSetting(
            'Tone:',
            _tone,
            ['Neutral', 'Positive', 'Critical', 'Humorous'],
            (value) => setState(() => _tone = value!),
          ),
          _buildDropdownSetting(
            'Length:',
            _length,
            ['Short', 'Medium', 'Long', 'Comprehensive'],
            (value) => setState(() => _length = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingField(
      String label, String value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Text('Topic: '),
          Expanded(
            child: TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text('Font Size: '),
          SizedBox(
            width: 100,
            child: Slider(
              value: _fontSize,
              min: 8,
              max: 24,
              divisions: 16,
              label: _fontSize.round().toString(),
              onChanged: (value) => setState(() => _fontSize = value),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              const Text('Word Wrap: '),
              Switch(
                value: _wordWrap,
                onChanged: (value) => setState(() => _wordWrap = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutputArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _outputController,
        maxLines: null,
        style: TextStyle(fontSize: _fontSize),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Generated Article',
        ),
        readOnly: true,
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _isGenerating ? null : _generateArticle,
            child: const Text('Generate Article'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isGenerating
                ? () => setState(() {
                      _isGenerating = false;
                      _progressStatus = 'Generation stopped by user';
                    })
                : null,
            child: const Text('Stop Generation'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => setState(() {
              _outputController.clear();
              _progressStatus = 'Ready';
            }),
            child: const Text('Clear'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _saveArticle,
            child: const Text('Save Article'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _copyToClipboard,
            child: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_isGenerating) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(_progressStatus),
        ],
      ),
    );
  }
}
