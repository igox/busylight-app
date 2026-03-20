import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/busylight_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _hostController;
  late int _pollInterval;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: ref.read(deviceHostProvider));
    _pollInterval   = ref.read(pollIntervalProvider);
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) return;

    ref.read(deviceHostProvider.notifier).state   = host;
    ref.read(pollIntervalProvider.notifier).state = _pollInterval;

    // Restart polling with new interval
    ref.read(pollingProvider.notifier).restart();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('busylight_host', host);
    await prefs.setInt('busylight_poll_interval', _pollInterval);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
      Navigator.pop(context);
    }
  }

  String _intervalLabel(int seconds) {
    if (seconds == 0) return 'Off';
    if (seconds < 60) return '${seconds}s';
    return '${seconds ~/ 60}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Device address ──────────────────────────────────────────────
            Text('Device address',
                style: TextStyle(color: Colors.grey.shade300, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _hostController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'http://igox-busylight.local',
                hintStyle: TextStyle(color: Colors.grey.shade700),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use hostname (igox-busylight.local) or IP address (http://192.168.x.x)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 32),

            // ── Polling interval ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status polling',
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  _intervalLabel(_pollInterval),
                  style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.amber,
                thumbColor: Colors.amber,
                inactiveTrackColor: Colors.grey.shade800,
                overlayColor: Colors.amber.withOpacity(0.2),
              ),
              child: Slider(
                value: _pollInterval.toDouble(),
                min: 0,
                max: 60,
                divisions: 12,
                onChanged: (v) => setState(() => _pollInterval = v.round()),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Off', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                Text('5s', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                Text('10s', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                Text('30s', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                Text('1m', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _pollInterval == 0
                  ? 'Polling is disabled. Status will only refresh manually.'
                  : 'Status is pulled from the device every $_pollInterval seconds.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Spacer(),

            // ── Save ────────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}