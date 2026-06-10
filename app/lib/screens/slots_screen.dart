import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/slot.dart';
import '../models/venue.dart';
import '../models/view_state.dart';
import '../providers/bookings_provider.dart';
import '../providers/slots_provider.dart';
import '../services/api_client.dart';
import '../widgets/slot_tile.dart';

class SlotsScreen extends StatefulWidget {
  final Venue venue;
  const SlotsScreen({super.key, required this.venue});

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  DateTime _date = DateTime.now();

  // Non-null while a booking POST is in flight. Holds the slot_datetime string
  // so the matching tile can show a spinner; all other tiles check != null to
  // disable themselves.
  String? _bookingSlot;

  late final Timer _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlots());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        // Skip the tick while a booking is in flight — the finally block in
        // _onSlotTap already calls _loadSlots() when it finishes, so we
        // won't miss any update.
        if (_bookingSlot == null) _loadSlots();
      },
    );
  }

  @override
  void dispose() {
    _pollTimer.cancel();
    super.dispose();
  }

  // Manual ISO-date formatting avoids pulling in the `intl` package.
  String get _dateStr {
    final d = _date;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String get _dateLabel {
    final d = _date;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  void _loadSlots() {
    context.read<SlotsProvider>().load(widget.venue.id, _dateStr);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked == null || picked == _date) return;
    setState(() => _date = picked);
    _loadSlots();
  }

  Future<void> _onSlotTap(Slot slot) async {
    // Guard: ignore taps while another booking is in flight
    if (_bookingSlot != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm booking'),
        content: Text('Book ${slot.label} at ${widget.venue.name} on $_dateLabel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Book'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _bookingSlot = slot.slotDatetime);

    try {
      await context.read<BookingsProvider>().book(widget.venue.id, slot.slotDatetime);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on SlotTakenException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorry, that slot was just booked by someone else.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on NetworkException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No network connection.')),
      );
    } finally {
      // Always clear the in-flight marker and refresh the grid.
      // On 201: our slot flips to booked. On 409: their slot flips to booked.
      if (mounted) {
        setState(() => _bookingSlot = null);
        _loadSlots();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final slotsProvider = context.watch<SlotsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.venue.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateBar(label: _dateLabel, onTap: _pickDate),
          Expanded(
            child: switch (slotsProvider.state) {
              ViewState.idle || ViewState.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
              ViewState.error => _ErrorView(
                  message: slotsProvider.errorMessage ?? 'Failed to load slots',
                  onRetry: _loadSlots,
                ),
              ViewState.success => _SlotGrid(
                  slots: slotsProvider.slots,
                  bookingSlot: _bookingSlot,
                  onSlotTap: _onSlotTap,
                ),
            },
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DateBar extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateBar({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SlotGrid extends StatelessWidget {
  final List<Slot> slots;
  final String? bookingSlot;
  final void Function(Slot) onSlotTap;

  const _SlotGrid({
    required this.slots,
    required this.bookingSlot,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Center(child: Text('No slots available for this date.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: slots.length,
      itemBuilder: (context, i) {
        final slot = slots[i];
        return SlotTile(
          slot: slot,
          isLoading: bookingSlot == slot.slotDatetime,
          isDisabled: bookingSlot != null,
          onTap: () => onSlotTap(slot),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
