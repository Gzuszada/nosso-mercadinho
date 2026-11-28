import 'dart:io';

/// The Flutter test runner exports `FLUTTER_TEST=true` in its process
/// environment. Unlike `bool.fromEnvironment`, this is available to the
/// native widget-test VM without requiring an extra `--dart-define`.
bool get isFlutterTestProcess =>
    Platform.environment['FLUTTER_TEST']?.toLowerCase() == 'true';
