import 'dart:async';
import 'package:flutter/foundation.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop_unsafe';

/// Web Speech API 绑定
@JS('webkitSpeechRecognition')
extension type SpeechRecognition._(JSObject _) implements JSObject {
  external factory SpeechRecognition();
  
  external set continuous(bool value);
  external set interimResults(bool value);
  external set lang(String value);
  external set maxAlternatives(int value);
  
  external void start();
  external void stop();
  external void abort();
  
  external set onstart(JSFunction? callback);
  external set onend(JSFunction? callback);
  external set onresult(JSFunction? callback);
  external set onerror(JSFunction? callback);
  external set onspeechstart(JSFunction? callback);
  external set onspeechend(JSFunction? callback);
}

@JS()
extension type SpeechRecognitionEvent._(JSObject _) implements JSObject {
  external SpeechRecognitionResultList get results;
  external int get resultIndex;
}

@JS()
extension type SpeechRecognitionResultList._(JSObject _) implements JSObject {
  external int get length;
  external SpeechRecognitionResult item(int index);
}

@JS()
extension type SpeechRecognitionResult._(JSObject _) implements JSObject {
  external bool get isFinal;
  external SpeechRecognitionAlternativeList get alternatives;
  external int get length;
  external SpeechRecognitionAlternative item(int index);
}

@JS()
extension type SpeechRecognitionAlternativeList._(JSObject _) implements JSObject {
  external int get length;
  external SpeechRecognitionAlternative item(int index);
}

@JS()
extension type SpeechRecognitionAlternative._(JSObject _) implements JSObject {
  external String get transcript;
  external double get confidence;
}

@JS()
extension type SpeechRecognitionErrorEvent._(JSObject _) implements JSObject {
  external String get error;
  external String get message;
}

// Web Speech API 方言配置
class SpeechLocale {
  final String id;
  final String name;
  final String code;

  const SpeechLocale({
    required this.id,
    required this.name,
    required this.code,
  });
}

/// 支持的方言列表
const List<SpeechLocale> supportedLocales = [
  SpeechLocale(id: 'zh-CN', name: '普通话', code: 'zh-CN'),
  SpeechLocale(id: 'zh-HK', name: '粤语(香港)', code: 'zh-HK'),
  SpeechLocale(id: 'zh-TW', name: '国语(台湾)', code: 'zh-TW'),
  SpeechLocale(id: 'yue-Hant-HK', name: '粤语', code: 'yue-Hant-HK'),
  SpeechLocale(id: 'zh-Hans', name: '四川话', code: 'zh-Hans'), // 使用zh-Hans作为基础，配合方言词汇
  SpeechLocale(id: 'en-US', name: 'English', code: 'en-US'),
];

/// 语音命令类型
enum VoiceCommand {
  nextStep,     // 下一步
  complete,     // 完成
  pause,        // 暂停
  resume,       // 继续
  unknown,      // 未知命令
}

/// Web Speech 服务 - 真正调用浏览器 Web Speech API
class WebSpeechService extends ChangeNotifier {
  SpeechRecognition? _recognition;
  
  bool _isAvailable = false;
  bool _isListening = false;
  bool _isEnabled = false;
  String _lastWords = '';
  String _statusMessage = '未初始化';
  String _errorDetail = '';
  String _selectedLocaleId = 'zh-CN';
  DateTime _lastCommandTime = DateTime.fromMillisecondsSinceEpoch(0);
  
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
    // 如果正在监听，重启以应用新语言
    if (_isListening) {
      stopListening();
      Future.delayed(const Duration(milliseconds: 300), () {
        startListening();
      });
    }
    notifyListeners();
  }
  
  /// 获取当前方言名称
  String get currentLocaleName {
    return supportedLocales
        .firstWhere((l) => l.id == _selectedLocaleId, 
                    orElse: () => supportedLocales.first)
        .name;
  }

  /// 检查 Web Speech API 是否可用
  bool _checkWebSpeechSupport() {
    if (!kIsWeb) return false;
    
    try {
      // 检查 webkitSpeechRecognition 是否存在
      final hasSupport = globalContext.has('webkitSpeechRecognition');
      debugPrint('WebSpeech: webkitSpeechRecognition available = $hasSupport');
      return hasSupport;
    } catch (e) {
      debugPrint('WebSpeech: Check support error: $e');
      return false;
    }
  }

  /// 初始化语音识别
  Future<bool> initialize() async {
    try {
      if (!kIsWeb) {
        _statusMessage = '仅支持 Web 平台';
        _isAvailable = false;
        notifyListeners();
        return false;
      }
      
      // 检查浏览器支持
      if (!_checkWebSpeechSupport()) {
        _statusMessage = '浏览器不支持语音识别';
        _errorDetail = '请使用 Chrome 或 Edge 浏览器';
        _isAvailable = false;
        notifyListeners();
        return false;
      }
      
      _statusMessage = '语音识别就绪';
      _errorDetail = '点击麦克风开始';
      _isAvailable = true;
      
      debugPrint('WebSpeechService: Initialized successfully');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('WebSpeechService init error: $e');
      _statusMessage = '初始化失败';
      _errorDetail = e.toString();
      _isAvailable = false;
      notifyListeners();
      return false;
    }
  }
  
  /// 创建 SpeechRecognition 实例
  void _createRecognition() {
    try {
      _recognition = SpeechRecognition();
      _recognition!.continuous = true;
      _recognition!.interimResults = true;
      _recognition!.lang = _selectedLocaleId;
      _recognition!.maxAlternatives = 1;
      
      // 设置回调
      _recognition!.onstart = ((JSAny? event) {
        debugPrint('WebSpeech: onstart');
        _isListening = true;
        _statusMessage = '正在聆听...';
        _errorDetail = '说 "下一步" 或 "完成"';
        notifyListeners();
      }).toJS;
      
      _recognition!.onend = ((JSAny? event) {
        debugPrint('WebSpeech: onend');
        _isListening = false;
        
        // 如果启用了持续监听，自动重启
        if (_isEnabled) {
          _statusMessage = '重新启动监听...';
          notifyListeners();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_isEnabled && !_isListening) {
              _startRecognition();
            }
          });
        } else {
          _statusMessage = '已停止聆听';
          _errorDetail = '';
          notifyListeners();
        }
      }).toJS;
      
      _recognition!.onresult = ((JSAny? event) {
        _handleResult(event as SpeechRecognitionEvent);
      }).toJS;
      
      _recognition!.onerror = ((JSAny? event) {
        _handleError(event as SpeechRecognitionErrorEvent);
      }).toJS;
      
      _recognition!.onspeechstart = ((JSAny? event) {
        debugPrint('WebSpeech: Speech detected');
        _statusMessage = '检测到语音...';
        notifyListeners();
      }).toJS;
      
      _recognition!.onspeechend = ((JSAny? event) {
        debugPrint('WebSpeech: Speech ended');
      }).toJS;
      
    } catch (e) {
      debugPrint('WebSpeech: Create recognition error: $e');
      _statusMessage = '创建识别器失败';
      _errorDetail = e.toString();
      notifyListeners();
    }
  }
  
  /// 处理识别结果
  void _handleResult(SpeechRecognitionEvent event) {
    try {
      final results = event.results;
      final resultIndex = event.resultIndex;
      
      if (resultIndex < results.length) {
        final result = results.item(resultIndex);
        if (result.length > 0) {
          final alternative = result.item(0);
          final transcript = alternative.transcript;
          final isFinal = result.isFinal;
          
          _lastWords = transcript;
          debugPrint('WebSpeech: Recognized "$transcript" (final: $isFinal)');
          
          if (isFinal || _selectedLocaleId == 'zh-Hans') { // 四川话模式下也尝试使用interim结果
            // 解析命令
            final command = _parseCommand(transcript);
            if (command != VoiceCommand.unknown) {
              
              // 防止短时间内重复触发命令
              final now = DateTime.now();
              if (now.difference(_lastCommandTime) > const Duration(seconds: 2)) {
                 debugPrint('WebSpeech: Command recognized: $command');
                _statusMessage = '命令: ${_commandToString(command)}';
                _lastCommandTime = now;
                onCommandRecognized?.call(command);
                
                // 如果是中间结果触发了命令，可以考虑暂时停止识别以免重复
                if (!isFinal) {
                   _recognition?.abort(); // 或 stop
                   // 稍后自动重启由 onend 处理
                }
              }
            }
          } else {
            _statusMessage = '听到: $transcript';
          }
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('WebSpeech: Handle result error: $e');
    }
  }
  
  String _commandToString(VoiceCommand command) {
    switch (command) {
      case VoiceCommand.nextStep: return '下一步';
      case VoiceCommand.complete: return '完成';
      case VoiceCommand.pause: return '暂停';
      case VoiceCommand.resume: return '继续';
      case VoiceCommand.unknown: return '未知';
    }
  }
  
  /// 处理错误
  void _handleError(SpeechRecognitionErrorEvent event) {
    final error = event.error;
    debugPrint('WebSpeech: Error: $error');
    
    switch (error) {
      case 'not-allowed':
        _statusMessage = '麦克风权限被拒绝';
        // 检查是否是非安全上下文导致的
        _errorDetail = '请使用 localhost:8889 访问，而非 IP 地址';
        _isEnabled = false;
        break;
      case 'no-speech':
        _statusMessage = '未检测到语音';
        _errorDetail = '请对着麦克风说话';
        break;
      case 'network':
        _statusMessage = '网络错误';
        _errorDetail = '请检查网络连接';
        break;
      case 'audio-capture':
        _statusMessage = '无法捕获音频';
        _errorDetail = '请检查麦克风是否正常';
        break;
      case 'aborted':
        _statusMessage = '识别被中断';
        _errorDetail = '';
        break;
      default:
        _statusMessage = '识别错误';
        _errorDetail = error;
    }
    
    _isListening = false;
    notifyListeners();
  }
  
  /// 开始识别
  void _startRecognition() {
    try {
      _createRecognition();
      _recognition?.start();
      debugPrint('WebSpeech: Recognition started with lang: $_selectedLocaleId');
    } catch (e) {
      debugPrint('WebSpeech: Start error: $e');
      _statusMessage = '启动失败';
      _errorDetail = e.toString();
      _isListening = false;
      notifyListeners();
    }
  }
  
  /// 开始监听
  Future<void> startListening() async {
    if (!_isAvailable) {
      await initialize();
    }
    
    if (!_isAvailable) {
      debugPrint('WebSpeech: Not available, cannot start');
      return;
    }
    
    _statusMessage = '请求麦克风权限...';
    notifyListeners();
    
    _startRecognition();
  }
  
  /// 停止监听
  Future<void> stopListening() async {
    try {
      _recognition?.stop();
    } catch (e) {
      debugPrint('WebSpeech: Stop error: $e');
    }
    _isListening = false;
    _statusMessage = '已停止聆听';
    _errorDetail = '';
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
  
  /// 解析语音命令
  VoiceCommand _parseCommand(String text) {
    final lowerText = text.toLowerCase();
    
    // 下一步命令 (增加四川话: 搞得, 下一脚, 走起)
    if (_containsAny(lowerText, ['下一步', '下一个', '继续下一步', '好了', '完成了', '搞定', '搞得', '下一脚', '走起', 'next'])) {
      return VoiceCommand.nextStep;
    }
    
    // 完成命令 (增加四川话: 做完咯, 弄完咯, 杀割)
    if (_containsAny(lowerText, ['完成', '结束', '做好了', '弄好了', '做完咯', '弄完咯', '杀割', 'done', 'finish'])) {
      return VoiceCommand.complete;
    }
    
    // 暂停命令 (增加四川话: 等一哈, 刹一脚, 停一下)
    if (_containsAny(lowerText, ['暂停', '停一下', '等一下', '等等', '等一哈', '刹一脚', 'pause', 'stop'])) {
      return VoiceCommand.pause;
    }
    
    // 继续命令 (增加四川话: 搞起, 接着弄)
    if (_containsAny(lowerText, ['继续', '开始', '恢复', '接着', '搞起', '接着弄', 'resume', 'continue'])) {
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
    try {
      _recognition?.abort();
    } catch (e) {
      debugPrint('WebSpeech: Dispose error: $e');
    }
    super.dispose();
  }
}
