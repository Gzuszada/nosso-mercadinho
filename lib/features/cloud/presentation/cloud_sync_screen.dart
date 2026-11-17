import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../data/cloud_models.dart';
import '../data/cloud_sync_service.dart';

class _SignedOutMessage extends StatelessWidget {
  const _SignedOutMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Sua sessão foi encerrada. Entre novamente para acessar o mercado.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class CloudSyncScreen extends ConsumerStatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  ConsumerState<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends ConsumerState<CloudSyncScreen> {
  final _householdNameController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _busy = false;
  String? _householdId;
  String? _inviteCode;

  @override
  void dispose() {
    _householdNameController.dispose();
    _inviteEmailController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(cloudAuthServiceProvider).currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Conta e sincronização')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user == null)
            const _SignedOutMessage()
          else
            ..._buildAccount(user.email),
        ],
      ),
    );
  }

  List<Widget> _buildAccount(String? email) => [
    ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(email ?? 'Conta conectada'),
      trailing: TextButton(
        onPressed: _busy ? null : _signOut,
        child: const Text('Sair'),
      ),
    ),
    const Divider(),
    TextField(
      controller: _householdNameController,
      decoration: const InputDecoration(labelText: 'Nome da casa'),
    ),
    const SizedBox(height: 12),
    FilledButton.icon(
      onPressed: _busy ? null : _createHousehold,
      icon: const Icon(Icons.home_outlined),
      label: const Text('Criar uma casa'),
    ),
    const SizedBox(height: 20),
    TextField(
      controller: _inviteEmailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'E-mail da pessoa convidada',
      ),
    ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: _busy ? null : _createInvite,
      icon: const Icon(Icons.person_add_alt),
      label: const Text('Gerar convite'),
    ),
    if (_inviteCode != null)
      Card(
        child: ListTile(
          title: Text('Código: $_inviteCode'),
          subtitle: const Text(
            'Compartilhe este código com o e-mail informado.',
          ),
        ),
      ),
    const SizedBox(height: 20),
    TextField(
      controller: _inviteCodeController,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(labelText: 'Código de convite'),
    ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: _busy ? null : _joinHousehold,
      icon: const Icon(Icons.login),
      label: const Text('Entrar na casa'),
    ),
    if (_householdId != null) ...[
      const Divider(height: 32),
      FilledButton.icon(
        onPressed: _busy ? null : _synchronize,
        icon: const Icon(Icons.sync),
        label: const Text('Sincronizar agora'),
      ),
    ],
  ];

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível concluir: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _signOut() => _run(() async {
    await ref.read(cloudAuthServiceProvider).signOut();
    if (!mounted) {
      return;
    }
    setState(() => _householdId = null);
    Navigator.of(context).popUntil((route) => route.isFirst);
  });

  Future<void> _createHousehold() => _run(() async {
    final id = await ref
        .read(cloudAuthServiceProvider)
        .createHousehold(name: _householdNameController.text);
    setState(() => _householdId = id);
  });

  Future<void> _createInvite() => _run(() async {
    final id = _householdId;
    if (id == null) {
      throw StateError('Crie ou entre em uma casa antes de gerar convite.');
    }
    final code = await ref
        .read(cloudAuthServiceProvider)
        .createInvite(
          householdId: id,
          invitedEmail: _inviteEmailController.text,
        );
    setState(() => _inviteCode = code);
  });

  Future<void> _joinHousehold() => _run(() async {
    final id = await ref
        .read(cloudAuthServiceProvider)
        .joinHousehold(code: _inviteCodeController.text);
    setState(() => _householdId = id);
  });

  Future<void> _synchronize() => _run(() async {
    final id = _householdId;
    if (id == null) {
      throw StateError('Nenhuma casa selecionada.');
    }
    final result = await _synchronizeResolvingConflicts(id, {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sincronização concluída (rev. ${result.revision}).'),
        ),
      );
    }
  });

  Future<CloudSyncResult> _synchronizeResolvingConflicts(
    String householdId,
    Map<CloudSyncConflictArea, CloudSyncResolution> resolutions,
  ) async {
    try {
      return await ref
          .read(cloudSyncServiceProvider)
          .synchronize(householdId: householdId, resolutions: resolutions);
    } on CloudSyncConflictException catch (error) {
      final resolution = await _askConflictResolution(error.conflict);
      if (resolution == null || !mounted) {
        rethrow;
      }
      return _synchronizeResolvingConflicts(householdId, {
        ...resolutions,
        error.conflict.area: resolution,
      });
    }
  }

  Future<CloudSyncResolution?> _askConflictResolution(
    CloudSyncConflict conflict,
  ) async {
    final useRemote = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Conflito em ${conflict.area.label}'),
        content: const Text(
          'Os dados locais e os da casa mudaram desde a última sincronização. Escolha qual versão deve prevalecer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Manter locais'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Usar remota'),
          ),
        ],
      ),
    );
    if (useRemote == null) {
      return null;
    }
    return CloudSyncResolution(
      payload: useRemote ? conflict.remotePayload : conflict.localPayload,
      source: useRemote
          ? CloudSyncResolutionSource.remote
          : CloudSyncResolutionSource.local,
    );
  }
}
