import 'package:dragonball_learning/models/character.dart';
import 'package:dragonball_learning/services/dragon_ball_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



void main() {
  runApp(const DragonBallApp());
  fetchCharacters();
}

Future<void> fetchCharacters() async{
  final api = DragonBallApi();

  try {
    final response  = await api.fetchCharacters();
    print('Status Code:${response.statusCode}');
    print('Body:${response.body}');
  }
  catch(error) {
    print('Something went wrong: ${error}');
  }
}

class DragonBallApp extends StatelessWidget {
  const DragonBallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Dragon Ball Universe",
      home: HomeScreen()
    );
  }
}


class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<Character> characters = [
    Character(id:1, name: "Goku", race:"Saiyan", gender:"Male"),
    Character(id:2, name: "Vegeta", race:"Saiyan", gender:"Male"),
    Character(id:3, name: "Goten", race:"Saiyan", gender:"Male"),
    Character(id:4, name: "Piccolo", race:"Namekian", gender:"Male"),
  ];

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Dragonball Screen"),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(12),
        itemCount: characters.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8
          ), 
        itemBuilder: (context, index){
          final character = characters[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.orange.shade300,
                    child: Icon(Icons.person, size: 80,),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(character.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4,),
                  Text(character.race)
              ],

            ),

          );
      }),
    );
  }

}