# 1.Create the project

flutter create dragon_ball_universe
cd dragon_ball_universe
code .



# 2. Static Homepage
GridView.builder(
  itemCount: characters.length,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(),
  itemBuilder: (context, index) {
    // Build one character card
  },
)

SliverGridDelegateWithFixedCrossAxisCount
- Sliver: Flutter's scrollable layout system uses slivers to construct scrolling content.
- GridDelegate: A delegate that describes how grid children should be positioned and sized.
- WithFixedCrossAxisCount: The number of items across the cross axis is fixed.

Without Expanded, your image container might need an explicit height or some other sizing constraint.

  final List<Map<String, String>> characters = const [
    {'name': 'Goku', 'race': 'Saiyan'},
  ]

character['name']!,



# 3. Create the Character model

class Character {
  final int id;
  final String name;
  final String race;
  final String gender;

  const Character({
    required this.id,
    required this.name,
    required this.race,
    required this.gender,
  });
}


final List<Character> characters = const [
  Character(id: 1, name: 'Goku', race: 'Saiyan', gender: 'Male');
]




# 4. Make your first API request

Future<void> fetchCharacters() async {
  final url = Uri.parse(
    'https://dragonball-api.com/api/characters',
  );

  final response = await http.get(url);

  print('Status Code: ${response.statusCode}');
  print('Response Body: ${response.body}');
}


# 5. Create a separate API service

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

Future<void> fetchCharacters() async{
  final api = DragonBallApi();

  try {
    final response  = api.fetchCharacters();
    print('Status Code:${response.statusCode}');
    print('Body:${response.body}');
  }
  catch(error) {
    print('Something went wrong: ${error}');
  }
}


