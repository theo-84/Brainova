import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/reality_check_service.dart';
import '../domain/reality_check_result.dart';
import '../../auth/data/auth_providers.dart';

class RealityCheckScreen extends ConsumerStatefulWidget {
  const RealityCheckScreen({super.key});

  @override
  ConsumerState<RealityCheckScreen> createState() => _RealityCheckScreenState();
}

class _RealityCheckScreenState extends ConsumerState<RealityCheckScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please Login")));
    }

    final uid = user.uid;
    final realityCheckAsync = ref.watch(realityCheckProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text("Reality Check")),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(realityCheckProvider(uid));
          return ref.read(realityCheckProvider(uid).future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AI Reality Analysis Card (New ScoreCard)
              realityCheckAsync.when(
                data: (result) => Column(
                  children: [
                    _ScoreCard(result).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    _CategoryBreakdownCard(result.categoryPercentages)
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.1),
                    if (result.shouldSuggestReset) ...[
                      const SizedBox(height: 24),
                      _SuggestedActionCard()
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .scale(begin: const Offset(0.9, 0.9)),
                    ],
                  ],
                ),
                loading: () => const _LoadingPlaceholder(height: 300),
                error: (e, _) => Text("Error: $e"),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final RealityCheckResult result;
  const _ScoreCard(this.result);

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor(result.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "${result.brainRotScore}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Danger':
        return const Color(0xFFFF5252);
      case 'Caution':
        return const Color(0xFFFFD740);
      default:
        return const Color(0xFF00E676);
    }
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  final Map<String, double> percentages;
  const _CategoryBreakdownCard(this.percentages);

  @override
  Widget build(BuildContext context) {
    if (percentages.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: percentages.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${entry.key} (${entry.value}%)",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.value / 100,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_getColor(entry.key)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getColor(String key) {
    switch (key) {
      case 'learning':
        return const Color(0xFF00E676);
      case 'entertainment':
        return const Color(0xFF2196F3);
      case 'junk':
        return const Color(0xFFFF5252);
      case 'social':
        return const Color(0xFF7C4DFF);
      default:
        return Colors.grey;
    }
  }
}

class _SuggestedActionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            "Suggested Action",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _ActionButton(
            label: "Start Mind Reset",
            onTap: () => context.push('/mind-reset'),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: "Try Rewire Mode",
            onTap: () => context.push('/rewire'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white30),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final double height;
  const _LoadingPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
