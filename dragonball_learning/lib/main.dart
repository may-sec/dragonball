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
      home: HomeScreen()
    );
  }
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String,String>> characters = const [
    {'name': 'Goku', 'race': 'Saiyan'},
    {'name': 'Vegeta', 'race': 'Saiyan'},
    {'name': 'Goten', 'race': 'Saiyan'},
    {'name': 'Piccolo', 'race': 'Namekian'},
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
                  child: Text(character['name']!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4,),
                  Text(character['race']!)
              ],

            ),

          );
      }),
    );
  }

}