import 'package:flutter/material.dart';
import '../models/busylight_status.dart';

class StatusButton extends StatelessWidget {
  final BusylightStatus status;
  final bool isActive;
  final bool isPending;
  final VoidCallback onTap;

  const StatusButton({
    super.key,
    required this.status,
    required this.isActive,
    required this.onTap,
    this.isPending = false,
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
    final activeColor = isActive || isPending ? _color : Colors.grey.shade600;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: (isActive || isPending) ? _color.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: (isActive || isPending) ? _color.withOpacity(0.5) : Colors.grey.shade800,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isPending
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_color),
                    ),
                  )
                : Icon(_icon, color: activeColor, size: 26),
            const SizedBox(height: 7),
            Text(
              status.label,
              style: TextStyle(
                color: activeColor,
                fontWeight: (isActive || isPending) ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}