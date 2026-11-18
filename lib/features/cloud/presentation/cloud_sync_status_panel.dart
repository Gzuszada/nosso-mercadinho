import 'package:flutter/material.dart';

import '../data/cloud_models.dart';

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
  });

  final CloudSyncStatus? status;
  final bool busy;
  final VoidCallback onCheck;
  final VoidCallback onSendAll;
  final VoidCallback onUseAll;
  final VoidCallback onSynchronize;
  final VoidCallback onDeleteHousehold;

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
                    status!.needsSynchronization
                        ? Icons.sync_problem_outlined
                        : Icons.cloud_done_outlined,
                    color: status!.needsSynchronization
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    status!.needsSynchronization
                        ? 'Este dispositivo não está igual ao Firebase'
                        : 'Este dispositivo está igual ao Firebase',
                  ),
                  subtitle: Text('Revisão da casa: ${status!.remoteRevision}'),
                ),
                const Divider(height: 1),
                for (final area in status!.areas.values)
                  ListTile(
                    dense: true,
                    leading: Icon(_stateIcon(area.state)),
                    title: Text(area.area.label),
                    subtitle: Text(
                      '${area.state.label}\n'
                      'Aqui: ${area.localCounts.summary}\n'
                      'Casa: ${area.remoteCounts.summary}',
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
          if (status!.needsSynchronization) ...[
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

  static IconData _stateIcon(CloudSyncAreaState state) => switch (state) {
    CloudSyncAreaState.inSync => Icons.check_circle_outline,
    CloudSyncAreaState.localOnly => Icons.phone_android_outlined,
    CloudSyncAreaState.remoteOnly => Icons.cloud_outlined,
    CloudSyncAreaState.divergent => Icons.compare_arrows_outlined,
    CloudSyncAreaState.invalid => Icons.error_outline,
  };
}
