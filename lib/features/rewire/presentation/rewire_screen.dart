import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../data/rewire_repository.dart';
import '../data/rewire_task_model.dart';
import '../../tracking/domain/brain_rot_service.dart';

class RewireScreen extends ConsumerStatefulWidget {
  const RewireScreen({super.key});

  @override
  ConsumerState<RewireScreen> createState() => _RewireScreenState();
}

class _RewireScreenState extends ConsumerState<RewireScreen> {
  String? _selectedOption;
  bool _isCompleted = false;
  bool _isCorrect = false;

  final _promptController = TextEditingController();
  final List<String> _completedTaskIds = [];
  late Future<RewireTask> _taskFuture;

  @override
  void initState() {
    super.initState();
    _loadNextTask();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _loadNextTask() {
    setState(() {
      _taskFuture = ref
          .read(rewireRepositoryProvider)
          .getRandomTask(excludeIds: _completedTaskIds);
      _selectedOption = null;
      _isCompleted = false;
      _isCorrect = false;
      _promptController.clear();
    });
  }

  Future<void> _checkAnswer(RewireTask task) async {
    if (task.type == RewireType.trivia || task.type == RewireType.puzzle) {
      final isCorrect = _selectedOption == task.correctAnswer;
      setState(() {
        _isCorrect = isCorrect;
        _isCompleted = true;
      });
      if (isCorrect) {
        await ref.read(brainRotServiceProvider).completeRewire(
              task.title,
              points: task.pointsReward,
            );
        if (mounted) _completedTaskIds.add(task.id);
      }
    } else {
      // PROMPT Type
      if (_promptController.text.trim().isEmpty) return; // Require input

      setState(() {
        _isCorrect = true;
        _isCompleted = true;
      });
      ref.read(brainRotServiceProvider).completeRewire(
            task.title,
            points: task.pointsReward,
          );
      _completedTaskIds.add(task.id);
    }
  }

  void _nextTask() {
    _loadNextTask();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<RewireTask>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final task = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTaskCard(task),
                const SizedBox(height: 32),

                // Text Input for Prompts
                if (!_isCompleted && task.type == RewireType.prompt) ...[
                  TextField(
                    controller: _promptController,
                    maxLines: 4,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type your answer here...",
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_isCompleted) ...[
                  _buildResult(task),
                ] else ...[
                  if (task.type != RewireType.prompt && task.options != null)
                    ...task.options!.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _selectedOption = option);
                            _checkAnswer(task);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surface,
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(option),
                        ),
                      ),
                    ),
                  if (task.type == RewireType.prompt)
                    ElevatedButton(
                      onPressed: () => _checkAnswer(task),
                      child: const Text("Submit Answer"),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(RewireTask task) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.brainCircuit,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            task.content,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResult(RewireTask task) {
    return Column(
      children: [
        Icon(
          _isCorrect ? LucideIcons.checkCircle : LucideIcons.xCircle,
          size: 64,
          color: _isCorrect ? AppTheme.success : AppTheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          _isCorrect
              ? "Correct! -${task.pointsReward} Rot"
              : "Incorrect, try again!",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        if (!_isCorrect)
          ElevatedButton(
            onPressed: () {
              setState(() => _isCompleted = false);
            },
            child: const Text("Try Again"),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text("Exit"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _nextTask,
                child: const Text("Next Task"),
              ),
            ],
          ),
      ],
    );
  }
}
