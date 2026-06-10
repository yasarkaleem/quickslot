class Venue {
  final int id;
  final String name;
  final String sport;
  final String location;

  const Venue({
    required this.id,
    required this.name,
    required this.sport,
    required this.location,
  });

  factory Venue.fromJson(Map<String, dynamic> j) => Venue(
        id: j['id'] as int,
        name: j['name'] as String,
        sport: j['sport'] as String,
        location: j['location'] as String,
      );
}
