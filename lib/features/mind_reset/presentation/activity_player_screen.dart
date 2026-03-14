import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mind_reset_model.dart';
import '../../tracking/domain/brain_rot_service.dart';

// Eye state for workout animation
enum _EyeState {
  lookUp,
  lookRight,
  lookTopLeft,
  rotate,
  closeTight,
  openWide,
}

class MindResetPlayerScreen extends ConsumerStatefulWidget {
  final MindResetActivity activity;
  const MindResetPlayerScreen({super.key, required this.activity});

  @override
  ConsumerState<MindResetPlayerScreen> createState() =>
      _MindResetPlayerScreenState();
}

class _MindResetPlayerScreenState extends ConsumerState<MindResetPlayerScreen>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  late int _totalSeconds;
  Timer? _timer;
  bool _isPlaying = false;
  bool _isCompleted = false;
  int _selectedDurationMinutes = 5;

  // Breathing & Animations
  late AnimationController _breathController;
  late AnimationController _rippleController;
  String _breathPhase = 'Inhale';
  int _breathPhaseSeconds = 4;
  Timer? _breathPhaseTimer;

  // Rain particles
  late AnimationController _rainController;
  final List<_RainDrop> _rainDrops = [];
  final Random _random = Random();
  AudioPlayer? _audioPlayer;

  // Typewriter Brain Dump
  final String _typeText = "Clear your mind and let thoughts flow...";
  int _typeIndex = 0;
  Timer? _typeTimer;

  @override
  void initState() {
    super.initState();
    _setDuration(5);
    _setupAnimations();
    _generateRainDrops();

    // Setup audio for rain
    if (widget.activity.id == '3') {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.setAsset('assets/audio/rain3.mp3').catchError((e) {
        debugPrint('Audio loading error: $e');
      });
      _audioPlayer!.setLoopMode(LoopMode.one);
    }
  }

  void _generateRainDrops() {
    for (int i = 0; i < 40; i++) {
      _rainDrops.add(_RainDrop(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.3 + _random.nextDouble() * 0.7,
        length: 0.03 + _random.nextDouble() * 0.06,
        opacity: 0.3 + _random.nextDouble() * 0.5,
      ));
    }
  }

  void _setupAnimations() {
    _breathController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));

    _rippleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addListener(() => setState(() {}));

    _rainController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            for (var drop in _rainDrops) {
              drop.y += drop.speed * 0.015;
              if (drop.y > 1.1) drop.y = -0.1;
            }
            setState(() {});
          });
  }

  void _setDuration(int minutes) {
    if (_isPlaying) return;
    setState(() {
      _selectedDurationMinutes = minutes;
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _startBreathingCycle() {
    _breathPhase = 'Inhale';
    _breathPhaseSeconds = 4;
    _breathController.forward(from: 0);
    _rippleController.repeat();
    HapticFeedback.lightImpact();

    _breathPhaseTimer?.cancel();
    _breathPhaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      setState(() => _breathPhaseSeconds--);
      if (_breathPhaseSeconds <= 0) _nextBreathPhase();
    });
  }

  void _nextBreathPhase() {
    HapticFeedback.lightImpact();
    switch (_breathPhase) {
      case 'Inhale':
        setState(() {
          _breathPhase = 'Hold';
          _breathPhaseSeconds = 4;
        });
        break;
      case 'Hold':
        if (_breathController.value >= 1.0) {
          setState(() {
            _breathPhase = 'Exhale';
            _breathPhaseSeconds = 4;
          });
          _breathController.reverse();
        } else {
          setState(() {
            _breathPhase = 'Inhale';
            _breathPhaseSeconds = 4;
          });
          _breathController.forward();
        }
        break;
      case 'Exhale':
        setState(() {
          _breathPhase = 'Hold';
          _breathPhaseSeconds = 2;
        });
        break;
    }
  }

  void _startTypewriter() {
    _typeIndex = 0;
    _typeTimer?.cancel();
    _typeTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }
      if (_typeIndex < _typeText.length) {
        setState(() => _typeIndex++);
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isPlaying) _startTypewriter();
        });
      }
    });
  }

  void _toggleTimer() {
    if (_isPlaying) {
      _timer?.cancel();
      _breathPhaseTimer?.cancel();
      _typeTimer?.cancel();
      _breathController.stop();
      _rippleController.stop();
      _rainController.stop();
      _audioPlayer?.pause();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          _completeActivity();
        }
      });

      final id = widget.activity.id;
      if (id == '1') _startBreathingCycle();
      if (id == '3') {
        _rainController.repeat();
        _audioPlayer?.play();
      }
      if (id == '5') _startTypewriter();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  Future<void> _completeActivity() async {
    _timer?.cancel();
    _breathPhaseTimer?.cancel();
    _typeTimer?.cancel();
    _breathController.stop();
    _rippleController.stop();
    _rainController.stop();
    _audioPlayer?.stop();

    setState(() {
      _isPlaying = false;
      _isCompleted = true;
    });
    HapticFeedback.heavyImpact();

    final bonusFactor = _selectedDurationMinutes ~/ 5;
    await ref.read(brainRotServiceProvider).completeMindReset(
          widget.activity.title,
          points: widget.activity.pointsReward * bonusFactor,
          durationSeconds: _totalSeconds,
        );
  }

  String get _timerText {
    final m = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathPhaseTimer?.cancel();
    _typeTimer?.cancel();
    _breathController.dispose();
    _rippleController.dispose();
    _rainController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Widget _buildAnimation() {
    switch (widget.activity.id) {
      case '1':
      case '6':
        return _buildLottie(widget.activity.assetPath);
      case '2':
        return _buildNeckStretch();
      case '3':
        return _buildRain();
      case '4':
        return _buildEyeWorkout();
      case '5':
        return _buildTypewriter();
      default:
        return _buildDefaultTimer();
    }
  }

  Widget _buildLottie(String path) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 300,
        height: 300,
        child: Lottie.asset(
          path,
          animate: _isPlaying,
          repeat: true,
          fit: BoxFit.contain,
        ),
      ),
      const SizedBox(height: 16),
      Text(_timerText,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 32,
              fontWeight: FontWeight.w200)),
    ]);
  }

  Widget _buildNeckStretch() {
    final totalSteps = widget.activity.steps.length;
    final elapsed = _totalSeconds - _remainingSeconds;
    final currentStep = totalSteps == 0
        ? 0
        : (elapsed / _totalSeconds * totalSteps)
            .floor()
            .clamp(0, totalSteps - 1);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Step Counter (Top)
      Text('Step ${currentStep + 1} of $totalSteps',
          style: const TextStyle(
              color: Colors.white70, fontSize: 14, letterSpacing: 1)),

      const SizedBox(height: 32),

      // Lottie Animation (Middle)
      SizedBox(
        width: 250,
        height: 250,
        child: Lottie.asset(
          widget.activity.assetPath,
          animate: _isPlaying,
          repeat: true,
          fit: BoxFit.contain,
        ),
      ),

      const SizedBox(height: 32),

      // Instruction Box (Matching Screenshot)
      if (_isPlaying && widget.activity.steps.isNotEmpty)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1)),
          child: Text(widget.activity.steps[currentStep],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.4)),
        ),

      const SizedBox(height: 24),

      // Timer Text (Bottom)
      Text(_timerText,
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 24,
              fontWeight: FontWeight.w200)),
    ]);
  }

  Widget _buildRain() {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: CustomPaint(
        painter: _RainPainter(drops: _rainDrops),
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.cloudRain, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(_timerText,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w200)),
          const SizedBox(height: 12),
          Text(_isPlaying ? 'Focus on the sound...' : 'Press play to start',
              style: const TextStyle(color: Colors.white60, fontSize: 16)),
        ])),
      ),
    );
  }

  Widget _buildEyeWorkout() {
    final totalSteps = widget.activity.steps.length;
    final elapsed = _totalSeconds - _remainingSeconds;
    final currentStep = totalSteps == 0
        ? 0
        : (elapsed / _totalSeconds * totalSteps)
            .floor()
            .clamp(0, totalSteps - 1);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Step ${currentStep + 1} of $totalSteps',
          style: const TextStyle(
              color: Colors.white70, fontSize: 14, letterSpacing: 1)),
      const SizedBox(height: 32),
      _AnimatedEyeWorkout(currentStep: currentStep, isPlaying: _isPlaying),
      const SizedBox(height: 32),
      _ActivityStepBox(text: widget.activity.steps[currentStep]),
      const SizedBox(height: 24),
      Text(_timerText,
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 24,
              fontWeight: FontWeight.w200)),
    ]);
  }

  Widget _buildTypewriter() {
    final displayed =
        _typeText.substring(0, _typeIndex.clamp(0, _typeText.length));
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(painter: _NotebookPainter(), size: const Size(300, 300)),
        Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_isPlaying ? displayed : '...',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1),
                textAlign: TextAlign.center),
            if (_isPlaying)
              Container(
                  width: 2,
                  height: 24,
                  color: Colors.white70,
                  margin: const EdgeInsets.only(top: 8)),
            const SizedBox(height: 24),
            Text(_timerText,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 20,
                    fontWeight: FontWeight.w200)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDefaultTimer() {
    return Stack(alignment: Alignment.center, children: [
      SizedBox(
        width: 250,
        height: 250,
        child: CircularProgressIndicator(
          value:
              _totalSeconds == 0 ? 0 : 1 - (_remainingSeconds / _totalSeconds),
          strokeWidth: 8,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      Text(_timerText,
          style: const TextStyle(
              fontSize: 60, fontWeight: FontWeight.w200, color: Colors.white)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: widget.activity.cardGradient ?? AppTheme.healingGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Text(widget.activity.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (!_isCompleted) ...[
                _buildAnimation(),
                const SizedBox(height: 48),

                // Instructions (Matching the requested enhanced format)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text("INSTRUCTIONS",
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2)),
                          ),
                          const SizedBox(height: 20),
                          ...widget.activity.steps.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle),
                                    child: Center(
                                        child: Text('${entry.key + 1}',
                                            style: const TextStyle(
                                                color: AppTheme.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold))),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                      child: Text(entry.value,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              height: 1.5))),
                                ],
                              ),
                            );
                          }),
                        ]),
                  ),
                ),
                const SizedBox(height: 40),

                // Duration selector
                if (!_isPlaying)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [5, 10, 20]
                        .map((min) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: _DurationChip(
                                  minutes: min,
                                  isSelected: _selectedDurationMinutes == min,
                                  onTap: () => _setDuration(min)),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 40),

                // Controls
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15))
                        ]),
                    child: Icon(
                        _isPlaying ? LucideIcons.pause : LucideIcons.play,
                        color: AppTheme.pink,
                        size: 34),
                  ),
                ),
                const SizedBox(height: 64),
              ] else ...[
                const SizedBox(height: 64),
                const Icon(LucideIcons.checkCircle,
                    size: 120, color: Colors.white),
                const SizedBox(height: 32),
                const Text("Activity Completed!",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),
                Text(
                    "-${widget.activity.pointsReward * (_selectedDurationMinutes ~/ 5)} Rot",
                    style: const TextStyle(color: Colors.white, fontSize: 22)),
                const SizedBox(height: 64),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.pink,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 64, vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100))),
                  child: const Text("Done",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 64),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

// Helper Widgets & Painters

class _DurationChip extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip(
      {required this.minutes, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(100)),
        child: Text('$minutes min',
            style: TextStyle(
                color: isSelected ? AppTheme.pink : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    );
  }
}

class _ActivityStepBox extends StatelessWidget {
  final String text;
  const _ActivityStepBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          textAlign: TextAlign.center,
          style:
              const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
    );
  }
}

// Rain Animation classes
class _RainDrop {
  double x, y, speed, length, opacity;
  _RainDrop(
      {required this.x,
      required this.y,
      required this.speed,
      required this.length,
      required this.opacity});
}

class _RainPainter extends CustomPainter {
  final List<_RainDrop> drops;
  _RainPainter({required this.drops});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var drop in drops) {
      paint.color = Colors.white.withOpacity(drop.opacity);
      paint.strokeWidth = 1.0;
      canvas.drawLine(
        Offset(drop.x * size.width, drop.y * size.height),
        Offset(drop.x * size.width, (drop.y + drop.length) * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Eye workout animation
class _AnimatedEyeWorkout extends StatefulWidget {
  final int currentStep;
  final bool isPlaying;
  const _AnimatedEyeWorkout(
      {required this.currentStep, required this.isPlaying});

  @override
  State<_AnimatedEyeWorkout> createState() => _AnimatedEyeWorkoutState();
}

class _AnimatedEyeWorkoutState extends State<_AnimatedEyeWorkout>
    with TickerProviderStateMixin {
  late AnimationController _pupilController;
  late AnimationController _lidController;
  late AnimationController _rotateController;
  late Animation<Offset> _pupilAnimation;
  late Animation<double> _lidAnimation;
  _EyeState _eyeState = _EyeState.lookUp;

  @override
  void initState() {
    super.initState();
    _pupilController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _lidController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _rotateController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));

    _pupilAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_pupilController);
    _lidAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_lidController);

    if (widget.isPlaying) _startStepAnimation();
  }

  @override
  void didUpdateWidget(_AnimatedEyeWorkout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isPlaying) {
      _pupilController.stop();
      _lidController.stop();
      _rotateController.stop();
    } else if (oldWidget.currentStep != widget.currentStep ||
        !oldWidget.isPlaying) {
      _startStepAnimation();
    }
  }

  void _startStepAnimation() {
    _pupilController.reset();
    _lidController.reset();
    _rotateController.reset();

    switch (widget.currentStep) {
      case 0:
        setState(() => _eyeState = _EyeState.lookUp);
        _pupilAnimation = Tween<Offset>(
                begin: const Offset(0, -0.6), end: const Offset(0, 0.6))
            .animate(CurvedAnimation(
                parent: _pupilController, curve: Curves.easeInOut));
        _pupilController.repeat(reverse: true);
        break;
      case 1:
        setState(() => _eyeState = _EyeState.lookRight);
        _pupilAnimation = Tween<Offset>(
                begin: const Offset(0.6, 0), end: const Offset(-0.6, 0))
            .animate(CurvedAnimation(
                parent: _pupilController, curve: Curves.easeInOut));
        _pupilController.repeat(reverse: true);
        break;
      case 2:
        setState(() => _eyeState = _EyeState.lookTopLeft);
        _pupilAnimation = Tween<Offset>(
                begin: const Offset(-0.5, -0.4), end: const Offset(0.5, -0.4))
            .animate(CurvedAnimation(
                parent: _pupilController, curve: Curves.easeInOut));
        _pupilController.repeat(reverse: true);
        break;
      case 3:
        setState(() => _eyeState = _EyeState.rotate);
        _rotateController.repeat();
        break;
      case 4:
        setState(() => _eyeState = _EyeState.closeTight);
        _lidAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
            CurvedAnimation(parent: _lidController, curve: Curves.easeInOut));
        _lidController.repeat(reverse: true);
        break;
      case 5:
        setState(() => _eyeState = _EyeState.openWide);
        _lidAnimation = Tween<double>(begin: 1.4, end: 0.2).animate(
            CurvedAnimation(parent: _lidController, curve: Curves.easeInOut));
        _lidController.repeat(reverse: true);
        break;
    }
  }

  @override
  void dispose() {
    _pupilController.dispose();
    _lidController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_pupilController, _lidController, _rotateController]),
      builder: (context, _) {
        Offset pupilOffset;
        double lidOpen;

        if (_eyeState == _EyeState.rotate && widget.isPlaying) {
          final angle = _rotateController.value * 2 * pi;
          pupilOffset = Offset(cos(angle) * 0.5, sin(angle) * 0.4);
          lidOpen = 1.0;
        } else if (_eyeState == _EyeState.closeTight ||
            _eyeState == _EyeState.openWide) {
          pupilOffset = Offset.zero;
          lidOpen = _lidAnimation.value;
        } else {
          pupilOffset = _pupilAnimation.value;
          lidOpen = 1.0;
        }

        return CustomPaint(
          size: const Size(200, 100),
          painter: _DetailedEyePainter(
              pupilOffset: pupilOffset, lidOpenAmount: lidOpen),
        );
      },
    );
  }
}

class _DetailedEyePainter extends CustomPainter {
  final Offset pupilOffset;
  final double lidOpenAmount;

  _DetailedEyePainter({required this.pupilOffset, required this.lidOpenAmount});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width * 0.45;
    final ry = size.height * 0.45 * lidOpenAmount.clamp(0.05, 1.4);

    final eyePath = Path()
      ..moveTo(cx - rx, cy)
      ..quadraticBezierTo(cx, cy - ry, cx + rx, cy)
      ..quadraticBezierTo(cx, cy + ry, cx - rx, cy);

    canvas.drawPath(eyePath, Paint()..color = Colors.white.withOpacity(0.95));

    canvas.save();
    canvas.clipPath(eyePath);

    // Iris
    final irisX = cx + pupilOffset.dx * rx * 0.6;
    final irisY = cy + pupilOffset.dy * ry * 0.6;
    canvas.drawCircle(
        Offset(irisX, irisY), 24, Paint()..color = AppTheme.primary);

    // Pupil
    canvas.drawCircle(Offset(irisX, irisY), 12, Paint()..color = Colors.black);

    // Shine
    canvas.drawCircle(
        Offset(irisX - 6, irisY - 6), 4, Paint()..color = Colors.white70);

    canvas.restore();

    // Eye outline
    canvas.drawPath(
        eyePath,
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Notebook Painter for Brain Dump
class _NotebookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(20)),
        paint);

    // Lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1.5;

    for (double y = 40; y < size.height; y += 30) {
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), linePaint);
    }

    // Vertical line
    canvas.drawLine(
        const Offset(40, 0),
        const Offset(40, 300),
        Paint()
          ..color = Colors.red.withOpacity(0.2)
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
