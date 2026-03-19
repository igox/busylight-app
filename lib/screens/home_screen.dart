import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/busylight_color.dart';
import '../models/busylight_status.dart';
import '../providers/busylight_provider.dart';
import '../widgets/brightness_slider.dart';
import '../widgets/status_button.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(busylightSnapshotProvider);
    final statusAsync = ref.watch(busylightStatusProvider);
    final brightness = ref.watch(brightnessProvider);
    final color = ref.watch(colorProvider);

    // Show loading/error based on the initial snapshot fetch
    if (!snapshot.hasValue && !snapshot.hasError) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    if (snapshot.hasError && !statusAsync.hasValue) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('BusyLight', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: _ErrorView(
          message: snapshot.error.toString(),
          onRetry: () => ref.invalidate(busylightSnapshotProvider),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('BusyLight', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(busylightStatusProvider.notifier).refresh(),
        ),
        data: (status) => _Body(status: status, brightness: brightness, color: color),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final BusylightStatus status;
  final double brightness;
  final BusylightColor color;

  const _Body({
    required this.status,
    required this.brightness,
    required this.color,
  });

  Color _statusColor() {
    switch (status) {
      case BusylightStatus.available: return Colors.green;
      case BusylightStatus.away:      return Colors.orange;
      case BusylightStatus.busy:      return Colors.red;
      case BusylightStatus.on:        return Colors.white;
      case BusylightStatus.off:       return Colors.grey.shade900;
      case BusylightStatus.colored:   return color.toFlutterColor();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayColor = _statusColor();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Live color preview dot
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status == BusylightStatus.off
                  ? Colors.grey.shade900
                  : displayColor.withOpacity(brightness),
              boxShadow: status != BusylightStatus.off
                  ? [
                      BoxShadow(
                        color: displayColor.withOpacity(0.5 * brightness),
                        blurRadius: 40,
                        spreadRadius: 8,
                      )
                    ]
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            status.label.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              letterSpacing: 2,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 36),

        // Quick status presets
        const _SectionLabel('Quick status'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: [
            BusylightStatus.available,
            BusylightStatus.away,
            BusylightStatus.busy,
            BusylightStatus.on,
            BusylightStatus.off,
          ].map((s) => StatusButton(
                status: s,
                isActive: status == s,
                onTap: () => ref.read(busylightStatusProvider.notifier).setStatus(s),
              )).toList(),
        ),
        const SizedBox(height: 32),

        // Brightness
        const _SectionLabel('Brightness'),
        const SizedBox(height: 8),
        BrightnessSlider(
          value: brightness,
          onChanged: (v) => ref.read(brightnessProvider.notifier).set(v),
        ),
        const SizedBox(height: 32),

        // Custom color
        const _SectionLabel('Custom color'),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _openColorPicker(context, ref, color),
            icon: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color.toFlutterColor(),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade600),
              ),
            ),
            label: const Text('Pick a color'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade700),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Refresh
        Center(
          child: TextButton.icon(
            onPressed: () => ref.invalidate(busylightSnapshotProvider),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh status'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
        ),
      ],
    );
  }

  void _openColorPicker(BuildContext context, WidgetRef ref, BusylightColor current) {
    Color pickerColor = current.toFlutterColor();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Pick a color', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (c) => pickerColor = c,
            pickerAreaHeightPercent: 0.8,
            displayThumbColor: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(colorProvider.notifier).set(
                BusylightColor.fromFlutterColor(pickerColor,
                    brightness: ref.read(brightnessProvider)),
              );
              ref.read(busylightStatusProvider.notifier).setLocalStatus(BusylightStatus.colored);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Apply', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  String get _friendlyMessage {
    const hint = '\nAlso double-check the device address in ⚙ Settings.';
    final m = message.toLowerCase();
    if (m.contains('socket') || m.contains('network') || m.contains('connection refused')) {
      return 'Make sure your BusyLight is powered on and connected to the same Wi-Fi network.$hint';
    }
    if (m.contains('timeout')) {
      return 'Connection timed out. Your BusyLight may be out of range or busy.$hint';
    }
    if (m.contains('404') || m.contains('not found')) {
      return 'BusyLight was reached but returned an unexpected response.$hint';
    }
    if (m.contains('host') || m.contains('lookup')) {
      return 'Could not find your BusyLight on the network.$hint';
    }
    return 'Could not connect to your BusyLight.$hint';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Cannot reach BusyLight',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _friendlyMessage,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('Retry', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}