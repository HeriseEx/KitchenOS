import 'dart:async';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop_unsafe';

import 'web_speech_types.dart';

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

/// Web Speech 服务 - 真正调用浏览器 Web Speech API
class WebSpeechService extends ChangeNotifier {
  SpeechRecognition? _recognition;
  
  bool _isAvailable = false;
  bool _isListening = false;
  bool _isEnabled = false;
  bool _isRestarting = false; // 防止重复重启
  String _lastWords = '';
  String _statusMessage = '未初始化';
  String _errorDetail = '';
  String _selectedLocaleId = 'zh-CN';
  DateTime _lastCommandTime = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _silenceTimer; // 防抖计时器
  
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
  
  /// 检查是否在安全上下文中 (HTTPS 或 localhost)
  bool _isSecureContext() {
    if (!kIsWeb) return false;
    
    try {
      // 使用 window.isSecureContext 检查
      final isSecure = globalContext['isSecureContext'];
      if (isSecure != null) {
        final result = (isSecure as JSBoolean).toDart;
        debugPrint('WebSpeech: isSecureContext = $result');
        return result;
      }
      // 如果无法检测，假设是安全的（让后续的权限请求来处理）
      return true;
    } catch (e) {
      debugPrint('WebSpeech: Check secure context error: $e');
      return true; // 出错时假设安全，让后续流程处理
    }
  }
  
  /// 检测是否是移动设备 (Android/iOS)
  bool _isMobileDevice() {
    if (!kIsWeb) return false;
    
    try {
      final navigator = globalContext['navigator'] as JSObject?;
      if (navigator != null) {
        final userAgent = (navigator['userAgent'] as JSString?)?.toDart ?? '';
        final isMobile = userAgent.contains('Android') || 
                         userAgent.contains('iPhone') || 
                         userAgent.contains('iPad') ||
                         userAgent.contains('Mobile');
        debugPrint('WebSpeech: isMobileDevice = $isMobile (UA: ${userAgent.substring(0, userAgent.length.clamp(0, 50))}...)');
        return isMobile;
      }
    } catch (e) {
      debugPrint('WebSpeech: Error checking mobile device: $e');
    }
    return false;
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
      
      // 检查是否在安全上下文中 (HTTPS 或 localhost)
      if (!_isSecureContext()) {
        _statusMessage = '不安全的环境';
        _errorDetail = '请使用HTTPS访问以启用麦克风';
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
      
      // Explicit permission query before starting (for clearer errors)
      // This is a proactive check, actual request happens on start()
      try {
        final permissions = globalContext['navigator']['permissions'] as JSObject?;
        if (permissions != null) {
          final queryPromise = permissions.callMethod('query'.toJS, 
              {'name': 'microphone'}.jsify());
          
          final status = await (queryPromise as JSPromise).toDart;
          final state = (status as JSObject)['state'] as JSString;
          debugPrint('WebSpeech: Initial microphone permission state: ${state.toDart}');
          
          if (state.toDart == 'denied') {
             _statusMessage = '麦克风权限已拒绝';
             _errorDetail = '请在浏览器设置中允许麦克风权限';
             _isAvailable = false; // Mark as unavailable until user fixes it
             notifyListeners();
             return false;
          }
        }
      } catch (e) {
        debugPrint('WebSpeech: Permission query failed (ignoring): $e');
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
      
      // 移动端优化：Android Chrome 中 continuous=true 可能会导致识别立即停止
      // 如果检测到是移动设备，使用 continuous=false 并依赖自动重启
      final isMobile = _isMobileDevice();
      _recognition!.continuous = !isMobile; 
      
      _recognition!.interimResults = true;
      _recognition!.lang = _selectedLocaleId;
      _recognition!.maxAlternatives = 1;
      
      // 设置回调
      _recognition!.onstart = ((JSAny? event) {
        debugPrint('WebSpeech: onstart');
        _isListening = true;
        _isRestarting = false; // 成功启动，重置重启标志
        _lastWords = ''; // 清除上一次的文字
        _statusMessage = '正在聆听...';
        _errorDetail = '说 "下一步" 或 "完成"';
        notifyListeners();
      }).toJS;
      
      _recognition!.onend = ((JSAny? event) {
        debugPrint('WebSpeech: onend');
        _isListening = false;
        _silenceTimer?.cancel(); // 取消计时器
        
        // 如果启用了持续监听，自动重启
        if (_isEnabled) {
          if (!_isRestarting) {
            _isRestarting = true;
            _statusMessage = '保持监听中...'; // 状态提示更友好
            notifyListeners();
            
            // 移动设备重启延迟非常短，接近无缝
            final restartDelay = isMobile ? 100 : 500;
            debugPrint('WebSpeech: Scheduling restart in ${restartDelay}ms (mobile: $isMobile)');
            
            Future.delayed(Duration(milliseconds: restartDelay), () {
              if (_isEnabled && !_isListening) {
                try {
                  _startRecognition();
                } catch (e) {
                  debugPrint('WebSpeech: Restart failed: $e');
                  _isRestarting = false;
                  // 重试一次
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_isEnabled && !_isListening) {
                      _startRecognition();
                    }
                  });
                }
              } else {
                _isRestarting = false;
              }
            });
          }
        } else {
          // 只在没有错误详情时才覆盖状态为"已停止聆听"
          // 防止 onend 覆盖 onerror 设置的错误信息
          if (_errorDetail.isEmpty) {
            _statusMessage = '已停止聆听';
          }
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
          
          // 重置静默计时器
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(milliseconds: 1500), () {
            // 如果1.5秒内没有新的语音输入，强制尝试解析命令
            debugPrint('WebSpeech: Silence detected, forcing command check');
            _checkCommand(transcript, force: true);
          });
          
          if (isFinal || _selectedLocaleId == 'zh-Hans') { // 四川话模式下也尝试使用interim结果
             _checkCommand(transcript, force: isFinal);
          } else {
            // 尝试检查是否有命令，但不强制
            _checkCommand(transcript, force: false);
            _statusMessage = '听到: $transcript';
          }
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('WebSpeech: Handle result error: $e');
    }
  }
  
  /// 检查并执行命令
  void _checkCommand(String transcript, {bool force = false}) {
    // 解析命令
    final command = _parseCommand(transcript);
    
    // 如果匹配到命令
    if (command != VoiceCommand.unknown) {
      final now = DateTime.now();
      
      // 防止重复触发: 距离上次命令超过2秒，或者是强制触发(静默检测)
      if (now.difference(_lastCommandTime) > const Duration(seconds: 2) || force) {
        
        // 如果是强制触发(静默)，但距离上次命令太近，仍然跳过
        if (now.difference(_lastCommandTime) < const Duration(milliseconds: 1000)) {
          return;
        }
        
        debugPrint('WebSpeech: Command recognized: $command (force: $force)');
        _statusMessage = '命令: ${_commandToString(command)}';
        _lastCommandTime = now;
        onCommandRecognized?.call(command);
        
        // 触发命令后，取消静默计时器
        _silenceTimer?.cancel();
        
        // 重启识别以清除上下文
        _recognition?.abort();
      }
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
  
  /// 根据当前环境获取权限错误提示
  String _getPermissionErrorDetail() {
    try {
      // 检查是否在安全上下文中 (HTTPS 或 localhost)
      final location = globalContext['location'] as JSObject?;
      if (location != null) {
        final hostname = (location['hostname'] as JSString?)?.toDart ?? '';
        final protocol = (location['protocol'] as JSString?)?.toDart ?? '';
        
        // GitHub Pages 或其他 HTTPS 站点
        if (protocol == 'https:') {
          return '请在浏览器中允许麦克风权限，然后刷新页面重试';
        }
        
        // 本地开发 - localhost
        if (hostname == 'localhost' || hostname == '127.0.0.1') {
          return '请在浏览器中允许麦克风权限';
        }
        
        // 使用 IP 地址访问 HTTP 站点 (非安全上下文)
        return '请使用 localhost 或 HTTPS 访问，IP 地址不支持麦克风权限';
      }
    } catch (e) {
      debugPrint('WebSpeech: Error checking location: $e');
    }
    return '请在浏览器中允许麦克风权限';
  }

  /// 处理错误
  void _handleError(SpeechRecognitionErrorEvent event) {
    final error = event.error;
    debugPrint('WebSpeech: Error: $error');
    
    bool shouldAutoRestart = false;
    
    switch (error) {
      case 'not-allowed':
        _statusMessage = '麦克风权限被拒绝';
        // 根据当前环境提供适当的错误提示
        _errorDetail = _getPermissionErrorDetail();
        _isEnabled = false;
        break;
      case 'no-speech':
        _statusMessage = '未检测到语音';
        _errorDetail = '请对着麦克风说话';
        // 在移动设备上，no-speech 是常见的（静默超时），应该自动重启
        shouldAutoRestart = (_isMobileDevice() || _isEnabled); // 只要启用了就尝试重启
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
        // aborted 通常是我们主动中断的，如果还在启用状态则重启
        shouldAutoRestart = _isEnabled;
        break;
      case 'service-not-allowed':
        _statusMessage = '语音服务不可用';
        _errorDetail = _isMobileDevice() 
            ? '请确保 Google 应用已安装并有麦克风权限' 
            : '浏览器语音服务不可用';
        _isEnabled = false;
        break;
      default:
        _statusMessage = '识别错误 ($error)';
        _errorDetail = error;
    }
    
    _isListening = false;
    notifyListeners();
    
    // 自动重启（对于可恢复的错误）
    if (shouldAutoRestart && !_isRestarting) {
      debugPrint('WebSpeech: Auto-restarting after error: $error');
      _isRestarting = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_isEnabled && !_isListening) {
          try {
            _startRecognition();
          } catch (e) {
            debugPrint('WebSpeech: Auto-restart failed: $e');
            _isRestarting = false;
          }
        } else {
          _isRestarting = false;
        }
      });
    }
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
    _silenceTimer?.cancel();
    try {
      _recognition?.abort();
    } catch (e) {
      debugPrint('WebSpeech: Dispose error: $e');
    }
    super.dispose();
  }
}
