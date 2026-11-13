import 'package:http/http.dart' as http;

class DragonBallApi {
  static const _baseurl = 'https://dragonball-api.com/api';

  Future<http.Response> fetchCharacters() async {
    final uri = Uri.parse('$_baseurl/characters');

    final response = await http.get(uri);

    if(response.statusCode!=200){
      throw Exception('Failed to load Characters'
      'Status Code: ${response.statusCode}');
    }
    return response;
  }
}