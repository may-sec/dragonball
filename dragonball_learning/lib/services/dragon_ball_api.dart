import 'dart:convert';
import 'package:dragonball_learning/models/character.dart';
import 'package:http/http.dart' as http;

class DragonBallApi {
  static const _baseurl = 'https://dragonball-api.com/api';

  Future<List<Character>> fetchCharacters() async {
    final uri = Uri.parse('$_baseurl/characters');
    final response = await http.get(uri);

    if(response.statusCode!=200){
      throw Exception('Failed to load Characters'
      'Status Code: ${response.statusCode}');
    }

    final decodedData = jsonDecode(response.body);
    final items = decodedData['items'] as List;

    final characters = items.map((item){
      return Character.fromJson(item);
    }).toList();

    return characters;
  }
}