import 'package:flutter/material.dart';
import '../models/booking.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onCancel;

  const BookingCard({super.key, required this.booking, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                _sportIcon(booking.sport),
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.venueName ?? 'Venue #${booking.venueId}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_dateLabel(booking.slotDatetime)}  •  ${booking.label}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.cancel_outlined,
                  color: theme.colorScheme.error),
              tooltip: 'Cancel booking',
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    );
  }

  IconData _sportIcon(String? sport) => switch (sport) {
        'badminton' => Icons.sports_tennis,
        'football'  => Icons.sports_soccer,
        _           => Icons.sports,
      };

  // "2026-06-15T10:00:00" → "Jun 15, 2026"
  String _dateLabel(String slotDatetime) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final date = slotDatetime.split('T').first.split('-');
    if (date.length != 3) return slotDatetime;
    final m = int.tryParse(date[1]) ?? 0;
    return '${months[m]} ${int.tryParse(date[2])}, ${date[0]}';
  }
}
