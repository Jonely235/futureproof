/// Platform-specific exports for AIProvider
/// Exports IO implementation for mobile/desktop, web stub for web
export 'ai_provider_io.dart' if (dart.library.html) 'ai_provider_web.dart';
