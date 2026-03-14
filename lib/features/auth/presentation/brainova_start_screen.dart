import 'package:flutter/material.dart';

class BrainovaStartScreen extends StatelessWidget {
  const BrainovaStartScreen({super.key});

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

          // BLACK FADE OVERLAY
          Container(
            color: Colors.black.withOpacity(0.45),
          ),

          // CONTENT
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'This is where the actual Brainova app starts!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
