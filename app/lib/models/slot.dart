class Slot {
  final String slotDatetime;
  final String status;

  const Slot({required this.slotDatetime, required this.status});

  bool get isBooked => status == 'booked';

  // Display-friendly hour label, e.g. "2026-06-15T10:00:00" → "10:00"
  String get label => slotDatetime.substring(11, 16);

  factory Slot.fromJson(Map<String, dynamic> j) => Slot(
        slotDatetime: j['slot_datetime'] as String,
        status: j['status'] as String,
      );
}
