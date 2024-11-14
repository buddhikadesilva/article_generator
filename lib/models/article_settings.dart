class ArticleSettings {
  String model;
  String temperature;
  String maxTokens;
  String topP;
  String serverUrl;
  bool enableStreaming;
  String writingStyle;
  String tone;
  String length;
  double fontSize;
  bool wordWrap;

  ArticleSettings({
    this.model = 'llama3',
    this.temperature = '0.7',
    this.maxTokens = '2000',
    this.topP = '0.9',
    this.serverUrl = 'http://localhost:11434',
    this.enableStreaming = true,
    this.writingStyle = 'Professional',
    this.tone = 'Neutral',
    this.length = 'Medium',
    this.fontSize = 11,
    this.wordWrap = true,
  });
}
