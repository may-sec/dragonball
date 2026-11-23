import 'package:dragonball_learning/models/character.dart';
import 'package:flutter/material.dart';

class CharacterDetailsScreen extends StatelessWidget{

  final Character character;
  const CharacterDetailsScreen({super.key ,required this.character});

  Widget _detailrow(String title, String value){
    return Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 110, 
            child: Text(
              title, 
              style:TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value))
        ],
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(character.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Image.network(character.image, height: 300, fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return SizedBox(
                  height: 300,
                  child: Icon(Icons.broken_image_outlined, size: 64),
                  );
                },
              ),
            ),

            const SizedBox(height: 30,),

            Text(character.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),

            const SizedBox(height: 30,),

            _detailrow("id", character.id.toString()),
            _detailrow("ki", character.ki),
            _detailrow("maxKi", character.maxKi),
            _detailrow("race", character.race),
            _detailrow("gender", character.gender),
            _detailrow("affiliation", character.affiliation),

            const SizedBox(height: 30,),

            Text("Description", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),

            const SizedBox(height: 6,),
            
            Text(character.description, style: TextStyle(fontSize: 14, height: 1.5),),


          ],
        ),
      ),
    );
  }
}

