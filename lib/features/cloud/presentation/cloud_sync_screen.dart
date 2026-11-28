import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_environment.dart';
import '../../../app_providers.dart';
import '../../backup/presentation/backup_actions.dart';
import '../data/cloud_models.dart';
import '../data/cloud_sync_service.dart';
import '../data/sync_v2_review.dart';
import '../domain/collaboration.dart';
import '../domain/collaboration_service.dart';
import 'cloud_sync_status_panel.dart';
import 'owner_review_panel.dart';
import 'pilot_household_people_panel.dart';

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
  bool _loadingHouseholds = false;
  String? _householdId;
  String? _inviteCode;
  List<CloudHousehold> _households = const [];
  CloudSyncStatus? _syncStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHouseholds());
  }

  @override
  void dispose() {
    _householdNameController.dispose();
    _inviteEmailController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authStateProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Conta e sincronização')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (account == null)
            const _SignedOutMessage()
          else
            ..._buildAccount(account.displayName, account.email),
        ],
      ),
    );
  }

  List<Widget> _buildAccount(String? displayName, String? email) {
    final actor = ref.watch(collaborationActorProvider).asData?.value;
    final localPendingReviews =
        ref.watch(pendingPlanReviewsProvider).asData?.value ??
        const <PendingPlanReview>[];
    final publishedPendingReviews =
        ref.watch(publishedPendingPlanReviewsProvider).asData?.value ??
        const <PlanReviewItem>[];
    final pendingReviews = _mergePendingReviews(
      localPendingReviews,
      publishedPendingReviews,
    );
    final householdId = _householdId;
    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(displayName ?? 'Usuário'),
          subtitle: Text(email ?? 'Conta conectada'),
          trailing: TextButton(
            onPressed: _busy ? null : _editDisplayName,
            child: const Text('Editar nome'),
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _busy ? null : _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sair'),
        ),
      ),
      const Divider(),
      if (_loadingHouseholds)
        const ListTile(
          leading: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Buscando suas casas…'),
        )
      else if (_households.isNotEmpty) ...[
        Text('Minhas casas', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final household in _households)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              household.id == _householdId
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: household.id == _householdId
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: Text(household.name),
            subtitle: Text(
              household.id == _householdId
                  ? 'Casa selecionada'
                  : 'Toque para selecionar esta casa',
            ),
            onTap: _busy ? null : () => _selectHousehold(household.id),
          ),
        const SizedBox(height: 12),
      ],
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
      if (!isPilotBuild || actor?.isOwner == true) ...[
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
      ],
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
      if (householdId != null) ...[
        const Divider(height: 32),
        if (isPilotBuild) ...[
          PilotHouseholdPeoplePanel(
            householdId: householdId,
            onOwnershipChanged: () {
              ref.invalidate(collaborationActorProvider);
            },
          ),
          const SizedBox(height: 12),
        ],
        OwnerReviewPanel(
          reviews: pendingReviews,
          isOwner: actor?.isOwner == true,
          busy: _busy,
          onApprove: (review) =>
              _moderateReview(review, SyncV2ReviewAction.approve),
          onRemove: (review) =>
              _moderateReview(review, SyncV2ReviewAction.remove),
        ),
        const SizedBox(height: 12),
        CloudSyncStatusPanel(
          status: _syncStatus,
          busy: _busy,
          onCheck: _checkSyncStatus,
          onSendAll: _sendAllLocalData,
          onUseAll: _useAllRemoteData,
          onSynchronize: _synchronize,
          onDeleteHousehold: _deleteHousehold,
          onExportBackup: _exportBackup,
          onCheckInternet: _checkInternet,
        ),
      ],
    ];
  }

  List<PlanReviewItem> _mergePendingReviews(
    List<PendingPlanReview> local,
    List<PlanReviewItem> published,
  ) {
    final bySyncId = <String, PlanReviewItem>{};
    for (final review in local) {
      final syncId = review.item.syncId;
      if (syncId == null || syncId.isEmpty) continue;
      bySyncId[syncId] = PlanReviewItem(
        itemSyncId: syncId,
        productName: review.product.name,
        planName: review.plan.name,
        authorName: review.item.authorName,
        authorUid: review.item.authorUid,
        createdAt: review.item.createdAt,
      );
    }
    for (final review in published) {
      bySyncId.putIfAbsent(review.itemSyncId, () => review);
    }
    final merged = bySyncId.values.toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return merged;
  }

  Future<void> _exportBackup() async {
    final saved = await exportBackup(context, ref.read(databaseProvider));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Backup exportado.'
              : 'O backup não foi exportado. Tente novamente.',
        ),
      ),
    );
  }

  Future<void> _checkInternet() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verificar internet'),
        content: const Text(
          'Confirme que o dispositivo está conectado ao Wi-Fi ou aos dados móveis. '
          'Depois toque em “Tentar novamente”. Os dados locais continuam seguros '
          'enquanto a conexão não estiver disponível.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkSyncStatus() => _run(() async {
    final id = _householdId;
    if (id == null) return;
    ref.invalidate(publishedPendingPlanReviewsProvider);
    final status = await ref.read(cloudSyncServiceProvider).inspectStatus(id);
    if (mounted) setState(() => _syncStatus = status);
  });

  Future<void> _sendAllLocalData() async {
    final id = _householdId;
    if (id == null) return;
    final approved = await _confirmWholeHouse(
      title: 'Enviar todos os dados deste dispositivo?',
      message: 'Os dados locais substituirão no Firebase o catálogo, importações, listas, compras e histórico desta casa. Todos os outros dispositivos conectados verão a alteração na próxima sincronização.',
    );
    if (!approved || !mounted) return;
    await _run(() async {
      await ref
          .read(cloudSyncServiceProvider)
          .publishAllLocalAreas(householdId: id);
      await _refreshSyncStatus(id);
    });
  }

  Future<void> _useAllRemoteData() async {
    final id = _householdId;
    if (id == null) return;
    final approved = await _confirmWholeHouse(
      title: 'Usar todos os dados da casa?',
      message: 'Os dados do Firebase substituirão localmente o catálogo, importações, listas, compras e histórico deste dispositivo.',
    );
    if (!approved || !mounted) return;
    await _run(() async {
      final resolutions = <CloudSyncConflictArea, CloudSyncResolution>{};
      for (final area in CloudSyncConflictArea.values) {
        final remoteArea = await ref
            .read(cloudSyncServiceProvider)
            .readRemoteArea(householdId: id, area: area);
        resolutions[area] = CloudSyncResolution(
          payload: remoteArea,
          source: CloudSyncResolutionSource.remote,
        );
      }
      await ref
          .read(cloudSyncServiceProvider)
          .synchronize(householdId: id, resolutions: resolutions);
      await _refreshSyncStatus(id);
    });
  }

  Future<bool> _confirmWholeHouse({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _refreshSyncStatus(String householdId) async {
    final status = await ref
        .read(cloudSyncServiceProvider)
        .inspectStatus(householdId);
    if (mounted) setState(() => _syncStatus = status);
  }

  Future<void> _deleteHousehold() async {
    final id = _householdId;
    if (id == null) return;
    final typed = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var confirmation = '';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Excluir esta casa do Firebase?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Todos os dados compartilhados da casa serão removidos para todos os dispositivos. Exporte um backup antes se houver dúvida.',
                ),
                const SizedBox(height: 12),
                const Text('Digite exatamente: EXCLUIR CASA'),
                TextField(
                  autofocus: true,
                  onChanged: (value) =>
                      setDialogState(() => confirmation = value.trim()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: confirmation == 'EXCLUIR CASA'
                    ? () => Navigator.pop(dialogContext, confirmation)
                    : null,
                child: const Text('Excluir casa'),
              ),
            ],
          ),
        );
      },
    );
    if (typed != 'EXCLUIR CASA' || !mounted) return;
    await _run(() async {
      await ref.read(cloudAuthServiceProvider).deleteHousehold(householdId: id);
      await ref
          .read(settingsRepositoryProvider)
          .saveCloudSyncSettings(
            householdId: null,
            remoteRevision: 0,
            lastSyncedHash: null,
          );
      ref.invalidate(selectedCloudHouseholdProvider);
      ref.invalidate(collaborationActorProvider);
      setState(() {
        _householdId = null;
        _syncStatus = null;
      });
      await _loadHouseholds();
    });
  }

  Future<void> _loadHouseholds() async {
    if (!mounted) {
      return;
    }
    setState(() => _loadingHouseholds = true);
    try {
      final settings = await ref
          .read(settingsRepositoryProvider)
          .getCloudSyncSettings();
      final households = await ref
          .read(cloudAuthServiceProvider)
          .discoverHouseholds();
      if (!mounted) {
        return;
      }

      var selectedId = settings?.householdId;
      if (households.length == 1) {
        selectedId = households.single.id;
      } else if (selectedId != null &&
          !households.any((household) => household.id == selectedId)) {
        selectedId = null;
      }

      setState(() {
        _households = households;
        _householdId = selectedId;
      });

      if (selectedId != null && selectedId != settings?.householdId) {
        await ref
            .read(settingsRepositoryProvider)
            .selectCloudHousehold(selectedId);
        ref.invalidate(collaborationActorProvider);
      }
      if (selectedId != null) {
        await _refreshSyncStatus(selectedId);
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível buscar suas casas: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingHouseholds = false);
      }
    }
  }

  Future<void> _selectHousehold(String? householdId) async {
    if (householdId == null || householdId == _householdId) {
      return;
    }
    setState(() {
      _householdId = householdId;
      _syncStatus = null;
    });
    await ref
        .read(settingsRepositoryProvider)
        .selectCloudHousehold(householdId);
    ref.invalidate(selectedCloudHouseholdProvider);
    ref.invalidate(collaborationActorProvider);
    await _refreshSyncStatus(householdId);
  }

  Future<void> _moderateReview(
    PlanReviewItem review,
    SyncV2ReviewAction action,
  ) async {
    final householdId = _householdId;
    if (householdId == null) return;
    final actor = await ref.read(collaborationActorProvider.future);
    if (!mounted) return;
    if (actor?.isOwner != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Somente o dono da casa pode revisar este item.'),
        ),
      );
      return;
    }
    final syncId = review.itemSyncId;
    if (syncId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este item legado ainda não tem uma identidade estável.',
          ),
        ),
      );
      return;
    }
    if (action == SyncV2ReviewAction.remove) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remover item da lista?'),
          content: Text(
            '${review.productName}, adicionado por '
            '${review.authorName ?? review.authorUid ?? 'membro'}, '
            'será removido para todos os dispositivos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remover'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    var completed = false;
    await _run(() async {
      await ref
          .read(cloudSyncServiceProvider)
          .moderatePlannedItem(
            householdId: householdId,
            itemSyncId: syncId,
            action: action,
          );
      ref.invalidate(pendingPlanReviewsProvider);
      ref.invalidate(publishedPendingPlanReviewsProvider);
      await _refreshSyncStatus(householdId);
      completed = true;
    });
    if (completed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == SyncV2ReviewAction.approve
                ? 'Item confirmado.'
                : 'Item removido da lista.',
          ),
        ),
      );
    }
  }

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
    ref.invalidate(collaborationActorProvider);
    if (!mounted) {
      return;
    }
    setState(() => _householdId = null);
    Navigator.of(context).popUntil((route) => route.isFirst);
  });

  Future<void> _editDisplayName() async {
    final service = ref.read(cloudAuthServiceProvider);
    final current = service.currentUser?.displayName ?? '';
    final controller = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar nome de usuário'),
        content: TextField(
          key: const Key('display-name-input'),
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Nome de usuário',
            helperText: 'Use de 2 a 40 caracteres.',
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('save-display-name'),
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) {
      return;
    }
    await _run(() async {
      await service.updateDisplayName(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome de usuário atualizado.')),
        );
      }
    });
  }

  Future<void> _createHousehold() => _run(() async {
    final id = await ref
        .read(cloudAuthServiceProvider)
        .createHousehold(name: _householdNameController.text);
    await ref.read(settingsRepositoryProvider).selectCloudHousehold(id);
    ref.invalidate(selectedCloudHouseholdProvider);
    if (!mounted) {
      return;
    }
    setState(() {
      _householdId = id;
      _households = [
        ..._households.where((household) => household.id != id),
        CloudHousehold(id: id, name: _householdNameController.text.trim()),
      ];
    });
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
    await ref.read(settingsRepositoryProvider).selectCloudHousehold(id);
    ref.invalidate(selectedCloudHouseholdProvider);
    if (!mounted) {
      return;
    }
    setState(() => _householdId = id);
    await _loadHouseholds();
  });

  Future<void> _synchronize() => _run(() async {
    final id = _householdId;
    if (id == null) {
      throw StateError('Nenhuma casa selecionada.');
    }
    ref.invalidate(publishedPendingPlanReviewsProvider);
    final result = await _synchronizeResolvingConflicts(id, {});
    await _refreshSyncStatus(id);
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
      if (isPilotBuild) {
        final isOwner = await ref
            .read(cloudAuthServiceProvider)
            .isHouseholdOwner(householdId);
        if (!isOwner) {
          throw StateError(
            'Este conflito precisa ser decidido pelo dono da casa.',
          );
        }
      }
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
