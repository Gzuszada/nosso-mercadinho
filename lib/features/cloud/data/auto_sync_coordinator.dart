import 'dart:async';

import 'package:http/http.dart' as http;

import 'cloud_models.dart';
import 'cloud_sync_service.dart';

/// Why an automatic synchronization attempt was requested.
enum AutoSyncTrigger { foreground, webFocus, webVisible, localChange }

/// User-facing outcome of an automatic synchronization attempt.
enum AutoSyncOutcome {
  synchronized,
  upToDate,
  skippedNoNetwork,
  skippedNoSession,
  skippedNoHousehold,
  skippedConflict,
  skippedInvalidRemote,
  skippedAlreadyRunning,
  skippedCooldown,
  failed,
}

/// Coordinates conservative automatic synchronization.
///
/// The coordinator deliberately does not resolve conflicts. It only allows a
/// write when the selected area can be classified unambiguously as local-only
/// or remote-only. Equal areas are left untouched.
class AutoSyncCoordinator {
  AutoSyncCoordinator({
    required this.hasNetwork,
    required this.hasValidSession,
    required this.selectedHouseholdId,
    required this.inspectStatus,
    required this.synchronize,
    this.cooldown = const Duration(seconds: 3),
  });

  final Future<bool> Function() hasNetwork;
  final Future<bool> Function() hasValidSession;
  final Future<String?> Function() selectedHouseholdId;
  final Future<CloudSyncStatus> Function(String householdId) inspectStatus;
  final Future<CloudSyncResult> Function(String householdId) synchronize;
  final Duration cooldown;

  bool _running = false;
  DateTime? _lastSuccessfulSyncAt;

  bool get isRunning => _running;

  Future<AutoSyncOutcome> run(AutoSyncTrigger trigger) async {
    if (_running) return AutoSyncOutcome.skippedAlreadyRunning;
    if (trigger == AutoSyncTrigger.localChange && _inCooldown()) {
      return AutoSyncOutcome.skippedCooldown;
    }

    _running = true;
    try {
      if (!await _probeNetwork()) return AutoSyncOutcome.skippedNoNetwork;
      if (!await _probeSession()) return AutoSyncOutcome.skippedNoSession;
      final householdId = await selectedHouseholdId();
      if (householdId == null || householdId.isEmpty) {
        return AutoSyncOutcome.skippedNoHousehold;
      }

      final status = await inspectStatus(householdId);
      if (status.areas.values.any(
        (area) => area.state == CloudSyncAreaState.divergent,
      )) {
        return AutoSyncOutcome.skippedConflict;
      }
      if (status.areas.values.any(
        (area) => area.state == CloudSyncAreaState.invalid,
      )) {
        return AutoSyncOutcome.skippedInvalidRemote;
      }
      if (!status.needsSynchronization) {
        return AutoSyncOutcome.upToDate;
      }

      await synchronize(householdId);
      _lastSuccessfulSyncAt = DateTime.now();
      return AutoSyncOutcome.synchronized;
    } on CloudSyncConflictException {
      return AutoSyncOutcome.skippedConflict;
    } on Object {
      return AutoSyncOutcome.failed;
    } finally {
      _running = false;
    }
  }

  bool _inCooldown() {
    final last = _lastSuccessfulSyncAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < cooldown;
  }

  Future<bool> _probeNetwork() async {
    try {
      return await hasNetwork();
    } on Object {
      return false;
    }
  }

  Future<bool> _probeSession() async {
    try {
      return await hasValidSession();
    } on Object {
      return false;
    }
  }

  /// Uses a lightweight public endpoint to avoid starting a Firebase read
  /// while the device is known to be offline.
  static Future<bool> probeNetworkWithHttp() async {
    final response = await http
        .get(
          Uri.https('connectivitycheck.gstatic.com', '/generate_204'),
          headers: const {'Cache-Control': 'no-cache'},
        )
        .timeout(const Duration(seconds: 5));
    return response.statusCode >= 200 && response.statusCode < 400;
  }
}
