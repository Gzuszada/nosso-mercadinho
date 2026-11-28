import 'dart:convert';

import 'package:flutter/foundation.dart';

enum CloudSyncFailureKind {
  network,
  permission,
  invalidData,
  conflict,
  account,
  unknown,
}

extension CloudSyncFailureKindLabel on CloudSyncFailureKind {
  String get label => switch (this) {
    CloudSyncFailureKind.network => 'Falha de rede',
    CloudSyncFailureKind.permission => 'Sem permissão',
    CloudSyncFailureKind.invalidData => 'Dados inválidos',
    CloudSyncFailureKind.conflict => 'Divergência pendente',
    CloudSyncFailureKind.account => 'Acesso à conta',
    CloudSyncFailureKind.unknown => 'Falha desconhecida',
  };
}

enum CloudSyncAttemptOutcome { success, failure }

class CloudSyncDiagnostics {
  const CloudSyncDiagnostics({
    this.lastAttemptAt,
    this.lastSuccessfulAt,
    this.lastOrigin,
    this.lastOriginAt,
    this.lastOriginAuthor,
    this.outcome,
    this.failureKind,
    this.failedArea,
    this.message,
    this.areaResults = const {},
  });

  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessfulAt;
  final String? lastOrigin;
  final DateTime? lastOriginAt;
  final String? lastOriginAuthor;
  final CloudSyncAttemptOutcome? outcome;
  final CloudSyncFailureKind? failureKind;
  final String? failedArea;
  final String? message;
  final Map<String, String> areaResults;

  bool get hasFailure => outcome == CloudSyncAttemptOutcome.failure;

  int get synchronizedAreaCount =>
      areaResults.values.where((state) => state == 'inSync').length;

  String get currentDeviceLabel {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iPhone',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS => 'Mac',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  String get publicationDeviceId => switch (currentDeviceLabel) {
    'Web' => 'web-pilot',
    'Android' => 'android-pilot',
    _ => '${currentDeviceLabel.toLowerCase()}-pilot',
  };

  Map<String, dynamic> toJson() => {
    'version': 1,
    if (lastAttemptAt != null)
      'lastAttemptAt': lastAttemptAt!.toUtc().toIso8601String(),
    if (lastSuccessfulAt != null)
      'lastSuccessfulAt': lastSuccessfulAt!.toUtc().toIso8601String(),
    if (lastOrigin != null) 'lastOrigin': lastOrigin,
    if (lastOriginAt != null)
      'lastOriginAt': lastOriginAt!.toUtc().toIso8601String(),
    if (lastOriginAuthor != null) 'lastOriginAuthor': lastOriginAuthor,
    if (outcome != null) 'outcome': outcome!.name,
    if (failureKind != null) 'failureKind': failureKind!.name,
    if (failedArea != null) 'failedArea': failedArea,
    if (message != null) 'message': message,
    'areaResults': {
      for (final entry in areaResults.entries) entry.key: entry.value,
    },
  };

  String encode() => jsonEncode(toJson());

  factory CloudSyncDiagnostics.decode(String? value) {
    if (value == null || value.isEmpty) return const CloudSyncDiagnostics();
    try {
      final json = jsonDecode(value);
      if (json is! Map) return const CloudSyncDiagnostics();
      final rawResults = json['areaResults'];
      final results = <String, String>{};
      if (rawResults is Map) {
        for (final entry in rawResults.entries) {
          if (entry.key is String && entry.value is String) {
            results[entry.key as String] = entry.value as String;
          }
        }
      }
      return CloudSyncDiagnostics(
        lastAttemptAt: _date(json['lastAttemptAt']),
        lastSuccessfulAt: _date(json['lastSuccessfulAt']),
        lastOrigin: _string(json['lastOrigin']),
        lastOriginAt: _date(json['lastOriginAt']),
        lastOriginAuthor: _string(json['lastOriginAuthor']),
        outcome: switch (json['outcome']) {
          'success' => CloudSyncAttemptOutcome.success,
          'failure' => CloudSyncAttemptOutcome.failure,
          _ => null,
        },
        failureKind: switch (json['failureKind']) {
          'network' => CloudSyncFailureKind.network,
          'permission' => CloudSyncFailureKind.permission,
          'invalidData' => CloudSyncFailureKind.invalidData,
          'conflict' => CloudSyncFailureKind.conflict,
          'account' => CloudSyncFailureKind.account,
          _ => null,
        },
        failedArea: _string(json['failedArea']),
        message: _string(json['message']),
        areaResults: results,
      );
    } on Object {
      return const CloudSyncDiagnostics();
    }
  }

  static DateTime? _date(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  static String? _string(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value;
  }
}

CloudSyncFailureKind classifyCloudSyncFailure(Object error) {
  if (error is FormatException) return CloudSyncFailureKind.invalidData;
  final text = error.toString().toLowerCase();
  if (text.contains('conflito de sincronização')) {
    return CloudSyncFailureKind.conflict;
  }
  if (text.contains('permission-denied') ||
      text.contains('permission_denied') ||
      text.contains('permission denied') ||
      text.contains('unauthorized')) {
    return CloudSyncFailureKind.permission;
  }
  if (text.contains('network-request-failed') ||
      text.contains('networkrequestfailed') ||
      text.contains('network error') ||
      text.contains('failed to fetch') ||
      text.contains('connection') ||
      text.contains('socket') ||
      text.contains('timeout') ||
      text.contains('timed out')) {
    return CloudSyncFailureKind.network;
  }
  if (text.contains('unauthenticated') ||
      text.contains('entre na sua conta') ||
      text.contains('sessão') ||
      text.contains('session')) {
    return CloudSyncFailureKind.account;
  }
  if (text.contains('invalid') || text.contains('format')) {
    return CloudSyncFailureKind.invalidData;
  }
  return CloudSyncFailureKind.unknown;
}
