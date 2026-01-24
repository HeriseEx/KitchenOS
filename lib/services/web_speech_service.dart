/// Web Speech Service Entry Point
/// Exports platform-specific implementation

export 'web_speech_types.dart';
export 'web_speech_stub_impl.dart'
    if (dart.library.js_interop) 'web_speech_web_impl.dart';
