
class Character {
  final int id;
  final String name;
  final String ki;
  final String maxKi;
  final String race;
  final String gender;
  final String description;
  final String image;
  final String affiliation;

  const Character({
    required this.id,
    required this.name,
    required this.ki,
    required this.maxKi,
    required this.race,
    required this.gender,
    required this.description,
    required this.image,
    required this.affiliation,
  });

  // factory: A special constructor that can return an instance of the class.
  //Character.fromJson: A named constructor.
  factory Character.fromJson(Map<String, dynamic> json) {
    String readString(String key, {String fallback = ''}) {
      final value = json[key];

      if (value == null) {
        return fallback;
      }

      return value.toString();
    }

    return Character(
      id: (json['id'] as num).toInt(),
      name: readString('name', fallback: 'Unknown'),
      ki: readString('ki', fallback: 'Unknown'),
      maxKi: readString('maxKi', fallback: 'Unknown'),
      race: readString('race', fallback: 'Unknown'),
      gender: readString('gender', fallback: 'Unknown'),
      description: readString('description'),
      image: readString('image'),
      affiliation: readString('affiliation', fallback: 'Unknown'),
    );
  }
}
