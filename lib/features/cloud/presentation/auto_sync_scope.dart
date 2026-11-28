import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../data/auto_sync_coordinator.dart';
import 'flutter_test_environment.dart';
import 'web_focus_listener.dart';

/// Hosts the conservative automatic synchronization triggers for the app.
class AutoSyncScope extends ConsumerStatefulWidget {
  const AutoSyncScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoSyncScope> createState() => _AutoSyncScopeState();
}

class _AutoSyncScopeState extends ConsumerState<AutoSyncScope>
    with WidgetsBindingObserver {
  static bool get _isFlutterTest => isFlutterTestProcess;

  StreamSubscription<String>? _localChangesSubscription;
  Timer? _localChangeDebounce;
  void Function()? _removeWebFocusListener;
  String? _lastLocalFingerprint;
  bool _conflictPending = false;
  bool _invalidRemote = false;

  @override
  void initState() {
    super.initState();
    if (_isFlutterTest) return;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _run(AutoSyncTrigger.foreground);
    });
    if (kIsWeb) {
      _removeWebFocusListener = addWebFocusListener(() {
        _run(AutoSyncTrigger.webFocus);
      });
    }
    _localChangesSubscription = ref
        .read(databaseProvider)
        .watchSyncRelevantFingerprint()
        .listen(_onLocalFingerprint);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _localChangeDebounce?.cancel();
    _localChangesSubscription?.cancel();
    _removeWebFocusListener?.call();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _run(AutoSyncTrigger.foreground);
    }
  }

  void _onLocalFingerprint(String fingerprint) {
    final previous = _lastLocalFingerprint;
    _lastLocalFingerprint = fingerprint;
    // The first value is the current database state, not a new local edit.
    if (previous == null) return;
    _localChangeDebounce?.cancel();
    _localChangeDebounce = Timer(
      const Duration(seconds: 1),
      () => _run(AutoSyncTrigger.localChange),
    );
  }

  Future<void> _run(AutoSyncTrigger trigger) async {
    final outcome = await ref.read(autoSyncCoordinatorProvider).run(trigger);
    if (!mounted) return;
    final conflict = outcome == AutoSyncOutcome.skippedConflict;
    final invalid = outcome == AutoSyncOutcome.skippedInvalidRemote;
    if (conflict != _conflictPending || invalid != _invalidRemote) {
      setState(() {
        _conflictPending = conflict;
        _invalidRemote = invalid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = <Widget>[];
    if (_conflictPending) {
      messages.add(
        Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: const ListTile(
            leading: Icon(Icons.sync_problem_outlined),
            title: Text('Há uma divergência pendente'),
            subtitle: Text(
              'A sincronização automática foi pausada. Abra Conta e sincronização '
              'e escolha explicitamente qual versão deve prevalecer.',
            ),
          ),
        ),
      );
    }
    if (_invalidRemote) {
      messages.add(
        Material(
          color: Theme.of(context).colorScheme.errorContainer,
          child: const ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Não foi possível verificar os dados da casa'),
            subtitle: Text(
              'A sincronização automática foi pausada para não escrever dados '
              'incorretos. Verifique o acesso à casa.',
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...messages,
        Expanded(child: widget.child),
      ],
    );
  }
}
