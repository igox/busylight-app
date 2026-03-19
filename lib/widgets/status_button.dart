import 'package:flutter/material.dart';
import '../models/busylight_status.dart';

class StatusButton extends StatelessWidget {
  final BusylightStatus status;
  final bool isActive;
  final VoidCallback onTap;

  const StatusButton({
    super.key,
    required this.status,
    required this.isActive,
    required this.onTap,
  });

  Color get _color {
    switch (status) {
      case BusylightStatus.available: return Colors.green;
      case BusylightStatus.away:      return Colors.orange;
      case BusylightStatus.busy:      return Colors.red;
      case BusylightStatus.on:        return Colors.white;
      case BusylightStatus.off:       return Colors.grey.shade700;
      case BusylightStatus.colored:   return Colors.purple;
    }
  }

  IconData get _icon {
    switch (status) {
      case BusylightStatus.available: return Icons.check_circle_outline;
      case BusylightStatus.away:      return Icons.schedule;
      case BusylightStatus.busy:      return Icons.do_not_disturb_on_outlined;
      case BusylightStatus.on:        return Icons.lightbulb_outline;
      case BusylightStatus.off:       return Icons.power_settings_new;
      case BusylightStatus.colored:   return Icons.palette_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isActive ? _color : Colors.grey.shade600,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, color: isActive ? _color : Colors.grey.shade400, size: 28),
            const SizedBox(height: 6),
            Text(
              status.label,
              style: TextStyle(
                color: isActive ? _color : Colors.grey.shade400,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
