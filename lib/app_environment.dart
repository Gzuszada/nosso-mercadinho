import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const String pilotFirebaseProjectId = 'nosso-mercado-casa-pilot';

/// True only when the Firebase app currently loaded belongs to the pilot.
///
/// The Android flavor selects its project through `google-services.json`, so
/// the backend choice cannot be accidentally combined with another project by
/// a stale Dart compile-time flag.
bool get isPilotBuild =>
    !kIsWeb &&
    Firebase.apps.any((app) => app.options.projectId == pilotFirebaseProjectId);

/// Human-readable label used by diagnostics and the Android application.
String get appEnvironmentLabel => isPilotBuild ? 'pilot' : 'production';
