import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_state.dart';
import '../../core/env.dart';
import '../online/session.dart';
import 'challenge_screen.dart';

/// Pending incoming 1v1 invites (for nav badges).
final challengePendingCountProvider = StateProvider<int>((ref) => 0);

/// Polls the challenge inbox app-wide so online players see invites on any
/// screen (lobby, bet tables, matchmaking), not only on the home screen.
class ChallengeInboxHost extends ConsumerStatefulWidget {
  const ChallengeInboxHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ChallengeInboxHost> createState() => _ChallengeInboxHostState();
}

class _ChallengeInboxHostState extends ConsumerState<ChallengeInboxHost> {
  Timer? _poll;
  bool _dialogOpen = false;
  static final _handled = <int>{};

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    if (!mounted || !Env.hasBackend) return;
    if (!ref.read(settingsProvider).challengesEnabled) {
      ref.read(challengePendingCountProvider.notifier).state = 0;
      return;
    }
    if (ref.read(settingsProvider).authToken.isEmpty) return;
    if (ref.read(apiProvider) == null) return;
    try {
      final inbox = await ref.read(sessionProvider.notifier).challengeInbox();
      if (!mounted) return;
      final incoming = (inbox['incoming'] as List).cast<Map<String, dynamic>>();
      ref.read(challengePendingCountProvider.notifier).state = incoming.length;
      if (_dialogOpen || incoming.isEmpty) return;
      // Do not pop over an active online match.
      final active = ref.read(activeMatchProvider).valueOrNull;
      if (active != null) return;
      final ch = incoming.first;
      final id = ch['id'] as int;
      if (_handled.contains(id)) return;
      _handled.add(id);
      _dialogOpen = true;
      await showIncomingChallenge(context, ref, ch);
      _dialogOpen = false;
    } on Object {
      // offline / not signed in
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
