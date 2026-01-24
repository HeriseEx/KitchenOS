import 'dart:async';
import 'package:flutter/foundation.dart';
import 'web_speech_types.dart';

/// Web Speech 服务 - Stub implementation for non-web platforms
class WebSpeechService extends ChangeNotifier {
  
  bool _isAvailable = false;
  bool _isListening = false;
  bool _isEnabled = false;
  String _lastWords = '';
  String _statusMessage = '仅支持 Web 平台';
  String _errorDetail = '';
  String _selectedLocaleId = 'zh-CN';
  
  // 命令回调
  Function(VoiceCommand)? onCommandRecognized;
  
  // Getters
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  bool get isEnabled => _isEnabled;
  String get lastWords => _lastWords;
  String get statusMessage => _statusMessage;
  String get errorDetail => _errorDetail;
  String get selectedLocaleId => _selectedLocaleId;
  
  /// 设置方言
  void setLocale(String localeId) {
    _selectedLocaleId = localeId;
    notifyListeners();
  }
  
  /// 获取当前方言名称
  String get currentLocaleName {
    return supportedLocales
        .firstWhere((l) => l.id == _selectedLocaleId, 
                    orElse: () => supportedLocales.first)
        .name;
  }

  /// 初始化语音识别
  Future<bool> initialize() async {
    _statusMessage = '仅支持 Web 平台';
    _isAvailable = false;
    notifyListeners();
    return false;
  }
  
  /// 开始监听
  Future<void> startListening() async {
    debugPrint('WebSpeech: Not supported on this platform');
  }
  
  /// 停止监听
  Future<void> stopListening() async {
    _isListening = false;
    notifyListeners();
  }
  
  /// 启用/禁用语音控制
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}
