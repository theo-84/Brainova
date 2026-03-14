import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/challenge_repository.dart';
import '../../domain/challenge_model.dart';

class ChallengeState {
  final bool loading;
  final int participants;
  final ChallengeUserStatus status;
  final Duration remaining;

  const ChallengeState({
    required this.loading,
    required this.participants,
    required this.status,
    required this.remaining,
  });

  bool get joined => status.joined;
  bool get isCompleted => status.isCompleted;

  ChallengeState copyWith({
    bool? loading,
    int? participants,
    ChallengeUserStatus? status,
    Duration? remaining,
  }) {
    return ChallengeState(
      loading: loading ?? this.loading,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      remaining: remaining ?? this.remaining,
    );
  }

  static const initial = ChallengeState(
    loading: true,
    participants: 0,
    status: ChallengeUserStatus(joined: false, endTime: null),
    remaining: Duration.zero,
  );
}

final activeChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  return ref.read(challengeRepositoryProvider).watchActiveChallenges();
});

final challengeControllerProvider = NotifierProvider.autoDispose
    .family<ChallengeController, ChallengeState, String>(
  ChallengeController.new,
);

class ChallengeController
    extends AutoDisposeFamilyNotifier<ChallengeState, String> {
  Timer? _ticker;
  StreamSubscription<int>? _participantsSub;

  @override
  ChallengeState build(String challengeId) {
    _ticker?.cancel();
    _participantsSub?.cancel();

    final repo = ref.read(challengeRepositoryProvider);
    _participantsSub = repo.watchParticipantsCount(challengeId).listen((count) {
      if (state.participants != count) {
        state = state.copyWith(participants: count);
      }
    });

    _loadMyStatus();

    ref.onDispose(() {
      _ticker?.cancel();
      _participantsSub?.cancel();
    });

    return ChallengeState.initial;
  }

  Future<void> _loadMyStatus() async {
    final repo = ref.read(challengeRepositoryProvider);
    try {
      final status = await repo.getMyStatus(arg);

      state = state.copyWith(
        loading: false,
        status: status,
        remaining: _calcRemaining(status.endTime),
      );

      if (status.joined) _startTicker();
    } catch (e) {
      print("DEBUG: Controller error in _loadMyStatus: $e");
      state = state.copyWith(loading: false);
    }
  }

  Duration _calcRemaining(DateTime? endTime) {
    if (endTime == null) return Duration.zero;
    final diff = endTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  void _startTicker() {
    print("DEBUG: Starting ticker");
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final end = state.status.endTime;
      if (end == null) return;

      final rem = _calcRemaining(end);
      state = state.copyWith(remaining: rem);

      if (rem == Duration.zero) {
        print("DEBUG: Ticker finished");
        _ticker?.cancel();
      }
    });
  }

  Future<void> join(Duration duration) async {
    print("DEBUG: Controller join() called with duration: $duration");
    if (state.loading || state.status.joined) return;

    state = state.copyWith(loading: true);

    try {
      final repo = ref.read(challengeRepositoryProvider);
      await repo.joinChallenge(
        challengeId: arg,
        duration: duration,
      );
      await _loadMyStatus();
    } catch (e) {
      print("DEBUG: Controller error in join: $e");
      state = state.copyWith(loading: false);
    }
  }

  Future<void> leave() async {
    print("DEBUG: Controller leave() called");
    if (state.loading || !state.status.joined) return;

    state = state.copyWith(loading: true);

    try {
      final repo = ref.read(challengeRepositoryProvider);
      await repo.leaveChallenge(arg);
      _ticker?.cancel();
      await _loadMyStatus();
    } catch (e) {
      print("DEBUG: Controller error in leave: $e");
      state = state.copyWith(loading: false);
    }
  }
}
