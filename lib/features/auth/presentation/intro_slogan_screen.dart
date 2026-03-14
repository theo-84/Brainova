import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class IntroSloganScreen extends StatefulWidget {
  const IntroSloganScreen({super.key});

  @override
  State<IntroSloganScreen> createState() => _IntroSloganScreenState();
}

class _IntroSloganScreenState extends State<IntroSloganScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sloganFade;
  late Animation<double> _sloganScale;

  late AnimationController _buttonsController;
  late Animation<double> _buttonsFade;
  late Animation<Offset> _buttonsSlide;

  bool _signupPressed = false;
  bool _loginPressed = false;

  @override
  void initState() {
    super.initState();

    HapticFeedback.lightImpact();

    // SLOGAN CONTROLLER
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _sloganFade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _sloganScale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    // BUTTONS CONTROLLER
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _buttonsFade = CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOut,
    );

    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _buttonsController,
        curve: Curves.easeOut,
      ),
    );

    // 🔥 DELAY BEFORE BUTTONS APPEAR
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _buttonsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background3.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // DARK OVERLAY
          Container(color: Colors.black.withOpacity(0.6)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // SLOGAN
                  FadeTransition(
                    opacity: _sloganFade,
                    child: ScaleTransition(
                      scale: _sloganScale,
                      child: const Text(
                        'Turn brain rot\ninto brain growth',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'MontserratAlt',
                          fontSize: 36,
                          height: 1.25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // BUTTONS (appear after 3 sec delay + animation)
                  FadeTransition(
                    opacity: _buttonsFade,
                    child: SlideTransition(
                      position: _buttonsSlide,
                      child: Column(
                        children: [
                          // SIGN UP
                          GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _signupPressed = true),
                            onTapUp: (_) {
                              setState(() => _signupPressed = false);
                              context.push('/signup');
                            },
                            onTapCancel: () =>
                                setState(() => _signupPressed = false),
                            child: AnimatedScale(
                              scale: _signupPressed ? 0.95 : 1,
                              duration: const Duration(milliseconds: 120),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFA62B),
                                      Color(0xFFFFD97A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // LOGIN
                          GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _loginPressed = true),
                            onTapUp: (_) {
                              setState(() => _loginPressed = false);
                              context.push('/login');
                            },
                            onTapCancel: () =>
                                setState(() => _loginPressed = false),
                            child: AnimatedScale(
                              scale: _loginPressed ? 0.95 : 1,
                              duration: const Duration(milliseconds: 120),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white70, width: 1.5),
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
