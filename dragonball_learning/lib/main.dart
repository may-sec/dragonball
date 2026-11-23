import 'package:dragonball_learning/screens/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DragonBallApp());
}

class DragonBallApp extends StatelessWidget {
  const DragonBallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Dragon Ball Universe",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple
        ),
        useMaterial3: true
      ),
      home: HomeScreen()
    );
  }
}

