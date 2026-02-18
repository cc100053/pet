import 'package:flutter/material.dart';

class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ColoredBox(
        color: Color(0xFF80CEF6),
        child: Center(
          child: Image(
            image: AssetImage('assets/app/LaunchLogo.png'),
            width: 220,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
