import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/cloud_models.dart';
import '../data/sync_diagnostics.dart';

/// Displays how the selected household differs between this device and Firebase.
class CloudSyncStatusPanel extends StatelessWidget {
  const CloudSyncStatusPanel({
    super.key,
    required this.status,
    required this.busy,
    required this.onCheck,
    required this.onSendAll,
    required this.onUseAll,
    required this.onSynchronize,
    required this.onDeleteHousehold,
    required this.onExportBackup,
    required this.onCheckInternet,
  });

  final CloudSyncStatus? status;
  final bool busy;
  final VoidCallback onCheck;
  final VoidCallback onSendAll;
  final VoidCallback onUseAll;
  final VoidCallback onSynchronize;
  final VoidCallback onDeleteHousehold;
  final VoidCallback onExportBackup;
  final VoidCallback onCheckInternet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Estado da sincronização',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (status == null)
          const Card(
            child: ListTile(
              leading: Icon(Icons.sync_problem_outlined),
              title: Text('Verifique a sincronização'),
              subtitle: Text(
                'Compare os dados deste dispositivo com os dados da casa no Firebase.',
              ),
            ),
          )
        else ...[
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    status!.diagnostics.hasFailure
                        ? Icons.sync_problem_outlined
                        : status!.needsSynchronization
                        ? Icons.sync_problem_outlined
                        : Icons.cloud_done_outlined,
                    color:
                        status!.diagnostics.hasFailure ||
                            status!.needsSynchronization
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    status!.diagnostics.hasFailure
                        ? 'A última sincronização não foi concluída'
                        : status!.needsSynchronization
                        ? 'Este dispositivo não está igual ao Firebase'
                        : 'Dados sincronizados',
                  ),
                  subtitle: Text(
                    [
                      if (status!.diagnostics.lastSuccessfulAt != null)
                        'Última sincronização: ${_formatDateTime(status!.diagnostics.lastSuccessfulAt!)}',
                      'Este dispositivo: ${status!.diagnostics.currentDeviceLabel}',
                      if (status!.remoteOrigin != null) ...[
                        'Última origem: ${_deviceLabel(status!.remoteOrigin!)}',
                        if (status!.remoteOriginAt != null)
                          'Publicada em: ${_formatDateTime(status!.remoteOriginAt!)}',
                        if (status!.remoteOriginAuthor != null &&
                            status!.remoteOriginAuthor!.isNotEmpty)
                          'Publicado por: ${status!.remoteOriginAuthor}',
                      ],
                      if (status!.diagnostics.lastAttemptAt != null)
                        'Última tentativa: ${_formatDateTime(status!.diagnostics.lastAttemptAt!)}',
                      if (status!.diagnostics.outcome ==
                          CloudSyncAttemptOutcome.success)
                        'Resultado: ${status!.diagnostics.synchronizedAreaCount} áreas sincronizadas',
                    ].join('\n'),
                  ),
                  isThreeLine: true,
                ),
                if (status!.diagnostics.hasFailure) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(
                      status!.diagnostics.failureKind?.label ?? 'Falha',
                    ),
                    subtitle: Text(
                      [
                        if (status!.diagnostics.failedArea != null)
                          'Área: ${_areaLabel(status!.diagnostics.failedArea!)}',
                        if (status!.diagnostics.message != null)
                          status!.diagnostics.message!,
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: busy ? null : onSynchronize,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                        if (status!.diagnostics.failureKind ==
                            CloudSyncFailureKind.network)
                          OutlinedButton.icon(
                            onPressed: busy ? null : onCheckInternet,
                            icon: const Icon(Icons.wifi),
                            label: const Text('Verificar internet'),
                          ),
                        if (status!.diagnostics.failureKind ==
                                CloudSyncFailureKind.permission ||
                            status!.diagnostics.failureKind ==
                                CloudSyncFailureKind.account)
                          OutlinedButton.icon(
                            onPressed: busy ? null : onCheck,
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Verificar acesso à casa'),
                          ),
                        OutlinedButton.icon(
                          onPressed: busy ? null : onExportBackup,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Exportar backup'),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 1),
                for (final area in status!.areas.values)
                  ListTile(
                    dense: true,
                    leading: Icon(_stateIcon(area.state)),
                    title: Text(area.area.label),
                    subtitle: Text(
                      [
                        area.state.label,
                        'Aqui: ${area.localCounts.summary}',
                        'Casa: ${area.remoteCounts.summary}',
                        if (area.localCounts.removedTotal !=
                            area.remoteCounts.removedTotal)
                          'Removidos: aqui ${area.localCounts.removedTotal}, '
                              'casa ${area.remoteCounts.removedTotal}',
                        if (area.localCounts.pendingTotal !=
                            area.remoteCounts.pendingTotal)
                          'Aguardando o owner: aqui '
                              '${area.localCounts.pendingTotal}, '
                              'casa ${area.remoteCounts.pendingTotal}',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onCheck,
            icon: const Icon(Icons.refresh),
            label: const Text('Verificar agora'),
          ),
          if (status!.needsSynchronization ||
              status!.areas.values.any(
                (area) => area.state == CloudSyncAreaState.localOnly,
              )) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: busy ? null : onSendAll,
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Enviar todos os dados deste dispositivo'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : onUseAll,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Usar todos os dados da casa'),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy ? null : onSynchronize,
            icon: const Icon(Icons.sync),
            label: const Text('Sincronizar agora'),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Detalhes técnicos'),
            children: [
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tag_outlined),
                title: Text('Revisão da casa: ${status!.remoteRevision}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: busy ? null : onDeleteHousehold,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Excluir casa do Firebase'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final date = DateFormat('dd/MM/yyyy').format(local);
    final time = DateFormat('HH:mm').format(local);
    return '$date, às $time';
  }

  static String _deviceLabel(String deviceId) => switch (deviceId) {
    'android-pilot' => 'Android',
    'web-pilot' => 'Web',
    _ => deviceId,
  };

  static String _areaLabel(String area) => switch (area) {
    'catalog' => 'catálogo',
    'imports' => 'importações',
    'shopping' => 'listas, compras e histórico',
    'all' => 'todas as áreas',
    _ => area,
  };

  static IconData _stateIcon(CloudSyncAreaState state) => switch (state) {
    CloudSyncAreaState.inSync => Icons.check_circle_outline,
    CloudSyncAreaState.localOnly => Icons.phone_android_outlined,
    CloudSyncAreaState.remoteOnly => Icons.cloud_outlined,
    CloudSyncAreaState.divergent => Icons.compare_arrows_outlined,
    CloudSyncAreaState.invalid => Icons.error_outline,
  };
}
