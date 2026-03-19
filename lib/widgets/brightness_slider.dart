import 'package:flutter/material.dart';

class BrightnessSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const BrightnessSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.brightness_low, color: Colors.grey, size: 20),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.amber,
              thumbColor: Colors.amber,
              inactiveTrackColor: Colors.grey.shade800,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ),
        const Icon(Icons.brightness_high, color: Colors.amber, size: 20),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).round()}%',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      ],
    );
  }
}
