import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const String pilotFirebaseProjectId = 'nosso-mercado-casa-pilot';

/// Compile-time switch used only by the isolated pilot Web build.
///
/// Android identifies the pilot through its Firebase flavor configuration.
const bool _pilotWebBuild = bool.fromEnvironment('MERCADO_PILOT_WEB');

/// True only when the Firebase app currently loaded belongs to the pilot.
///
/// Android selects its project through `google-services.json`. The pilot Web
/// build must additionally use the explicit `MERCADO_PILOT_WEB` flag, so a
/// normal Web build can never select the pilot protocol by accident.
bool get isPilotBuild =>
    Firebase.apps.any(
      (app) => app.options.projectId == pilotFirebaseProjectId,
    ) &&
    (!kIsWeb || _pilotWebBuild);

/// Human-readable label used by diagnostics and the Android application.
String get appEnvironmentLabel => isPilotBuild ? 'pilot' : 'production';
