class Booking {
  final int id;
  final int venueId;
  final String? venueName;
  final String? sport;
  final String slotDatetime;
  final int userId;
  final String? createdAt;

  const Booking({
    required this.id,
    required this.venueId,
    this.venueName,
    this.sport,
    required this.slotDatetime,
    required this.userId,
    this.createdAt,
  });

  String get label => slotDatetime.substring(11, 16);

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as int,
        venueId: j['venue_id'] as int,
        venueName: j['venue_name'] as String?,
        sport: j['sport'] as String?,
        slotDatetime: j['slot_datetime'] as String,
        userId: j['user_id'] as int,
        createdAt: j['created_at'] as String?,
      );
}
