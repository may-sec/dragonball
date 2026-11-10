import 'package:flutter/material.dart';

void main() {
  runApp(const DragonBallApp());
}

class DragonBallApp extends StatelessWidget {
  const DragonBallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dragon Ball Universe",
      home: Scaffold(
        appBar: AppBar(
          title: Text("Dragonball Screen"),
        ),
        body: Center(child: Text("Dragonball Data"),),
      ),
    );
  }
}
