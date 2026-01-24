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
