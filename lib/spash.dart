import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';

import 'timer.dart'; // Assuming this is where your TimerApp widget is defined

class splash extends StatelessWidget {
  const splash({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Image.asset('assets/Untitled_design-removebg-preview.jpg'),
      nextScreen: const TimerApp(), // Navigate to your TimerApp widget
      backgroundColor: Colors.white,
      pageTransitionType: PageTransitionType.leftToRight, // Use fade transition
      duration: 5000, // Duration for which splash screen will be visible
    );
  }
}
