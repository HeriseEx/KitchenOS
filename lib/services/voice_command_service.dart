import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// 语音命令类型
enum VoiceCommand {
  nextStep,     // 下一步
  complete,     // 完成
  pause,        // 暂停
  resume,       // 继续
  unknown,      // 未知命令
}

/// 语音命令服务
/// 用于烹饪过程中的语音控制
class VoiceCommandService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  
  bool _isAvailable = false;
  bool _isListening = false;
  bool _isEnabled = false;
  String _lastWords = '';
  String _statusMessage = '未初始化';
  String _errorDetail = '';
  
  // 命令回调
  Function(VoiceCommand)? onCommandRecognized;
  
  // Getters
  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  bool get isEnabled => _isEnabled;
  String get lastWords => _lastWords;
  String get statusMessage => _statusMessage;
  String get errorDetail => _errorDetail;
  
  /// 初始化语音识别
  Future<bool> initialize() async {
    try {
      // Web平台检查
      if (kIsWeb) {
        debugPrint('Voice: Running on Web platform');
      }
      
      _statusMessage = '正在初始化...';
      notifyListeners();
      
      _isAvailable = await _speechToText.initialize(
        onStatus: _onStatus,
        onError: (error) {
          debugPrint('Voice error: ${error.errorMsg}');
          _errorDetail = error.errorMsg;
          
          // 提供更友好的错误信息
          if (error.errorMsg.contains('not-allowed') || 
              error.errorMsg.contains('permission')) {
            _statusMessage = '请允许麦克风权限';
          } else if (error.errorMsg.contains('network')) {
            _statusMessage = '网络错误';
          } else {
            _statusMessage = '识别错误';
          }
          notifyListeners();
        },
      );
      
      if (_isAvailable) {
        _statusMessage = '语音识别就绪';
        _errorDetail = '';
      } else {
        // 检查具体原因
        if (kIsWeb) {
          _statusMessage = '请使用Chrome并允许麦克风';
          _errorDetail = 'Web Speech API需要Chrome浏览器和麦克风权限';
        } else {
          _statusMessage = '语音识别不可用';
          _errorDetail = '设备不支持语音识别';
        }
      }
      
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      debugPrint('Voice init error: $e');
      
      // 提供更详细的错误信息
      final errorStr = e.toString();
      if (errorStr.contains('NotAllowedError') || errorStr.contains('permission')) {
        _statusMessage = '麦克风权限被拒绝';
        _errorDetail = '请在浏览器设置中允许麦克风访问';
      } else if (errorStr.contains('NotFoundError')) {
        _statusMessage = '未找到麦克风';
        _errorDetail = '请确保设备有麦克风';
      } else if (errorStr.contains('NotSupportedError')) {
        _statusMessage = '浏览器不支持';
        _errorDetail = '请使用Chrome或Edge浏览器';
      } else {
        _statusMessage = '初始化失败';
        _errorDetail = errorStr.length > 50 ? errorStr.substring(0, 50) : errorStr;
      }
      
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }
  
  void _onStatus(String status) {
    debugPrint('Voice status: $status');
    
    if (status == 'listening') {
      _isListening = true;
      _statusMessage = '正在聆听...';
    } else if (status == 'notListening' || status == 'done') {
      _isListening = false;
      _statusMessage = '聆听结束';
      
      // 如果启用了持续监听，自动重启
      if (_isEnabled) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isEnabled && !_isListening) {
            startListening();
          }
        });
      }
    }
    
    notifyListeners();
  }
  
  /// 开始监听
  Future<void> startListening() async {
    if (!_isAvailable) {
      await initialize();
    }
    
    if (!_isAvailable) return;
    
    try {
      await _speechToText.listen(
        onResult: _onResult,
        localeId: 'zh_CN',
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.confirmation,
        ),
      );
      _isListening = true;
      _statusMessage = '正在聆听...';
      notifyListeners();
    } catch (e) {
      debugPrint('Start listening error: $e');
      _statusMessage = '启动监听失败';
      notifyListeners();
    }
  }
  
  /// 停止监听
  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    _statusMessage = '已停止聆听';
    notifyListeners();
  }
  
  /// 启用/禁用语音控制
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (enabled) {
      startListening();
    } else {
      stopListening();
    }
    notifyListeners();
  }
  
  void _onResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    debugPrint('Recognized: $_lastWords');
    
    // 解析命令
    final command = _parseCommand(_lastWords);
    if (command != VoiceCommand.unknown && result.finalResult) {
      debugPrint('Command recognized: $command');
      onCommandRecognized?.call(command);
    }
    
    notifyListeners();
  }
  
  /// 解析语音命令
  VoiceCommand _parseCommand(String text) {
    final lowerText = text.toLowerCase();
    
    // 下一步命令
    if (_containsAny(lowerText, ['下一步', '下一个', '继续下一步', '好了', '完成了', '搞定'])) {
      return VoiceCommand.nextStep;
    }
    
    // 完成命令
    if (_containsAny(lowerText, ['完成', '结束', '做好了', '弄好了'])) {
      return VoiceCommand.complete;
    }
    
    // 暂停命令
    if (_containsAny(lowerText, ['暂停', '停一下', '等一下', '等等'])) {
      return VoiceCommand.pause;
    }
    
    // 继续命令
    if (_containsAny(lowerText, ['继续', '开始', '恢复', '接着'])) {
      return VoiceCommand.resume;
    }
    
    return VoiceCommand.unknown;
  }
  
  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
  
  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
