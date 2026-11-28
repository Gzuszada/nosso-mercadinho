import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../data/pilot_household_administration_service.dart';

/// Pilot-only administration view for the people and invitations of a house.
class PilotHouseholdPeoplePanel extends ConsumerStatefulWidget {
  const PilotHouseholdPeoplePanel({
    required this.householdId,
    this.onOwnershipChanged,
    super.key,
  });

  final String householdId;
  final VoidCallback? onOwnershipChanged;

  @override
  ConsumerState<PilotHouseholdPeoplePanel> createState() =>
      _PilotHouseholdPeoplePanelState();
}

class _PilotHouseholdPeoplePanelState
    extends ConsumerState<PilotHouseholdPeoplePanel> {
  CloudHouseholdRoster? _roster;
  List<CloudHouseholdInvite> _invites = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant PilotHouseholdPeoplePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.householdId != widget.householdId) {
      _load();
    }
  }

  bool get _isOwner =>
      _roster?.ownerUid ==
      ref.read(pilotHouseholdAdministrationServiceProvider).currentUid;

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(pilotHouseholdAdministrationServiceProvider);
      final roster = await service.readRoster(widget.householdId);
      final invites = roster.ownerUid == service.currentUid
          ? await service.readInvites(widget.householdId)
          : const <CloudHouseholdInvite>[];
      if (!mounted) return;
      setState(() {
        _roster = roster;
        _invites = invites;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      return true;
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível concluir: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roster = _roster;
    final peopleCount = roster?.peopleCount ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pessoas da casa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              roster == null
                  ? 'Consultando as pessoas da casa…'
                  : peopleCount == 1
                  ? 'Esta casa possui 1 pessoa.'
                  : 'Esta casa possui $peopleCount pessoas.',
            ),
            if (_isOwner) ...[
              const SizedBox(height: 8),
              const Chip(
                avatar: Icon(Icons.verified_user_outlined, size: 18),
                label: Text('Você é o dono desta casa'),
              ),
            ],
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_error!),
                  TextButton.icon(
                    onPressed: _busy ? null : _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              )
            else if (roster != null) ...[
              for (final member in roster.members)
                _MemberTile(
                  member: member,
                  isOwner: _isOwner,
                  busy: _busy,
                  onTransfer: () => _transferOwnership(member),
                  onRemove: () => _removeMember(member),
                ),
              if (_isOwner) ...[
                const Divider(height: 32),
                Text(
                  'Convites pendentes',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                if (_invites.isEmpty)
                  const Text('Nenhum convite pendente.')
                else
                  for (final invite in _invites)
                    ListTile(
                      key: Key('invite-${invite.code}'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.mail_outline),
                      title: Text(invite.email),
                      subtitle: Text(
                        'Código ${invite.code}'
                        '${_dateSuffix(invite.createdAt)}'
                        '${_expirySuffix(invite)}',
                      ),
                      trailing: TextButton(
                        key: Key('revoke-invite-${invite.code}'),
                        onPressed: _busy ? null : () => _revokeInvite(invite),
                        child: const Text('Revogar'),
                      ),
                    ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(CloudHouseholdMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remover ${member.displayName}?'),
        content: Text(
          'A pessoa perderá o acesso à casa neste dispositivo e nos demais. '
          'Os dados já compartilhados não serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm-remove-member'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => ref
          .read(pilotHouseholdAdministrationServiceProvider)
          .removeMember(householdId: widget.householdId, memberUid: member.uid),
    );
  }

  Future<void> _transferOwnership(CloudHouseholdMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Transferir a casa para ${member.displayName}?'),
        content: const Text(
          'A pessoa escolhida se tornará o owner. Você continuará como membro '
          'e poderá continuar usando a casa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm-transfer-ownership'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Transferir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final transferred = await _run(
      () => ref
          .read(pilotHouseholdAdministrationServiceProvider)
          .transferOwnership(
            householdId: widget.householdId,
            targetUid: member.uid,
          ),
    );
    if (transferred) widget.onOwnershipChanged?.call();
  }

  Future<void> _revokeInvite(CloudHouseholdInvite invite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revogar este convite?'),
        content: Text(
          'O convite para ${invite.email} deixará de permitir entrada na casa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Revogar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => ref
          .read(pilotHouseholdAdministrationServiceProvider)
          .revokeInvite(householdId: widget.householdId, code: invite.code),
    );
  }

  static String _dateSuffix(DateTime? date) {
    if (date == null) return '';
    return ' • ${DateFormat('dd/MM/yyyy').format(date.toLocal())}';
  }

  static String _expirySuffix(CloudHouseholdInvite invite) {
    final expiry = invite.expiresAt;
    if (expiry == null) return ' • expiração não informada';
    final now = DateTime.now();
    if (invite.isExpiredAt(now)) return ' • expirado';
    final days = invite.remainingDaysAt(now);
    return days == 1 ? ' • expira em 1 dia' : ' • expira em $days dias';
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.busy,
    required this.onTransfer,
    required this.onRemove,
  });

  final CloudHouseholdMember member;
  final bool isOwner;
  final bool busy;
  final VoidCallback onTransfer;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      member.isOwner ? 'Dono' : 'Membro',
      if (member.joinedAt != null)
        'Entrou em ${DateFormat('dd/MM/yyyy').format(member.joinedAt!.toLocal())}',
      if (isOwner && member.email != null) member.email!,
    ];
    return ListTile(
      key: Key('member-${member.uid}'),
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Icon(
          member.isOwner ? Icons.home_outlined : Icons.person_outline,
        ),
      ),
      title: Text(member.displayName),
      subtitle: Text(details.join(' • ')),
      trailing: isOwner && !member.isOwner
          ? PopupMenuButton<String>(
              key: Key('member-actions-${member.uid}'),
              enabled: !busy,
              onSelected: (value) {
                if (value == 'transfer') onTransfer();
                if (value == 'remove') onRemove();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'transfer',
                  child: Text('Transferir propriedade'),
                ),
                PopupMenuItem(value: 'remove', child: Text('Remover da casa')),
              ],
            )
          : null,
    );
  }
}
