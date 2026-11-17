import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/app_database.dart';
import '../data/backup_service.dart';

const _backupType = XTypeGroup(
  label: 'Backup do Mercado',
  extensions: ['json'],
);

const _backupFileChannel = MethodChannel('br.com.nocorre.mercado/backup_files');

Future<bool> exportBackup(BuildContext context, AppDatabase database) async {
  final contents = await BackupService(database).createBackup();
  return saveBackupJson(contents, 'mercado-backup.json');
}

Future<bool> restoreBackupFromFile(
  BuildContext context,
  AppDatabase database,
) async {
  String contents;
  String? selectedFilePath;
  String? selectedFileUri;
  if (defaultTargetPlatform == TargetPlatform.android) {
    final selectedBackup = await _backupFileChannel
        .invokeMapMethod<String, String>('openJson');
    if (selectedBackup == null) {
      return false;
    }
    contents = selectedBackup['contents'] ?? '';
    selectedFileUri = selectedBackup['uri'];
  } else {
    final selectedFile = await openFile(
      acceptedTypeGroups: const [_backupType],
    );
    if (selectedFile == null) {
      return false;
    }
    contents = await selectedFile.readAsString();
    selectedFilePath = selectedFile.path;
  }
  if (!context.mounted) {
    return false;
  }
  return restoreBackupContents(
    context,
    database,
    contents,
    selectedFilePath: selectedFilePath,
    selectedFileUri: selectedFileUri,
  );
}

@visibleForTesting
Future<bool> restoreBackupContents(
  BuildContext context,
  AppDatabase database,
  String contents, {
  String? selectedFilePath,
  String? selectedFileUri,
}) async {
  final backupService = BackupService(database);
  backupService.validateBackup(contents);

  if (!context.mounted) {
    return false;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Substituir os dados atuais?'),
      content: const SingleChildScrollView(
        child: Text(
          'O JSON selecionado precisa ser um backup válido do Mercado. A restauração vai substituir o catálogo, as listas, as compras e o histórico atuais pelos dados desse arquivo. O que existe apenas neste aparelho será perdido.\n\n'
          'Antes de substituir os dados, você deverá salvar um backup de segurança em um local escolhido por você. Se cancelar ou não conseguir salvar essa cópia, a restauração não continuará. As preferências de tema não fazem parte do backup e serão mantidas.\n\n'
          'O catálogo inicial continua incluído no app e pode ser revisado e importado pelo menu “Dados e backup”, se necessário.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return false;
  }

  final safetyBackup = await backupService.createBackup();
  final safetyBackupSaved = await saveBackupJson(
    safetyBackup,
    'mercado-backup-seguranca.json',
    disallowSamePathAs: selectedFilePath,
    disallowSameUri: selectedFileUri,
  );
  if (!safetyBackupSaved) {
    return false;
  }

  await backupService.restoreBackup(contents);
  return true;
}

Future<bool> saveBackupJson(
  String contents,
  String name, {
  String? disallowSamePathAs,
  String? disallowSameUri,
}) async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return await _backupFileChannel.invokeMethod<bool>('saveJson', {
          'fileName': name,
          'contents': contents,
          'disallowSameUri': disallowSameUri,
        }) ??
        false;
  }

  final location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: const [_backupType],
  );
  if (location == null) {
    return false;
  }
  if (disallowSamePathAs != null && location.path == disallowSamePathAs) {
    throw const FormatException(
      'Escolha um arquivo diferente para o backup de segurança.',
    );
  }

  final file = XFile.fromData(
    Uint8List.fromList(utf8.encode(contents)),
    mimeType: 'application/json',
    name: name,
  );
  await file.saveTo(location.path);
  return true;
}
