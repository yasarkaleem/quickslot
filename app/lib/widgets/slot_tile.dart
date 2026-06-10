import 'package:flutter/material.dart';
import '../models/slot.dart';

class SlotTile extends StatelessWidget {
  final Slot slot;
  final bool isLoading;  // true only for the tile whose booking is in flight
  final bool isDisabled; // true for all tiles while any booking is in flight
  final VoidCallback? onTap;

  const SlotTile({
    super.key,
    required this.slot,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color bg;
    final Color fg;

    if (slot.isBooked) {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurface.withValues(alpha: 0.38);
    } else if (isDisabled) {
      bg = cs.surfaceContainerHighest;
      fg = cs.onSurface.withValues(alpha: 0.38);
    } else {
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        // onTap null makes InkWell non-interactive — no ripple, no tap
        onTap: (slot.isBooked || isDisabled) ? null : onTap,
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      slot.label,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (slot.isBooked)
                      Text(
                        'Booked',
                        style: TextStyle(color: fg, fontSize: 11),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
