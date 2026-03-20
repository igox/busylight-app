import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/busylight_color.dart';
import '../models/busylight_status.dart';
import '../services/busylight_service.dart';

// ── Device config ────────────────────────────────────────────────────────────

const _kHostKey        = 'busylight_host';
const _kDefaultHost    = 'http://igox-busylight.local';
const _kPollIntervalKey     = 'busylight_poll_interval';
const _kDefaultPollInterval = 5; // seconds

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

final deviceHostProvider = StateProvider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return prefs?.getString(_kHostKey) ?? _kDefaultHost;
});

final pollIntervalProvider = StateProvider<int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return prefs?.getInt(_kPollIntervalKey) ?? _kDefaultPollInterval;
});

// ── Service ──────────────────────────────────────────────────────────────────

final busylightServiceProvider = Provider<BusylightService>((ref) {
  final host = ref.watch(deviceHostProvider);
  return BusylightService(baseUrl: host);
});

// ── Startup snapshot ─────────────────────────────────────────────────────────
// Loads status + color (which includes brightness) in 2 parallel calls.
// No separate GET /api/brightness needed — the color response already has it.

class BusylightSnapshot {
  final BusylightStatus status;
  final BusylightColor color;

  const BusylightSnapshot({
    required this.status,
    required this.color,
  });

  double get brightness => color.brightness;
}

final busylightSnapshotProvider = FutureProvider<BusylightSnapshot>((ref) async {
  final service = ref.watch(busylightServiceProvider);
  final results = await Future.wait([
    service.getStatus(),
    service.getColor(),
  ]);
  return BusylightSnapshot(
    status: results[0] as BusylightStatus,
    color:  results[1] as BusylightColor,
  );
});

// ── State notifiers ──────────────────────────────────────────────────────────

class BusylightStateNotifier extends StateNotifier<AsyncValue<BusylightStatus>> {
  BusylightStateNotifier(this._service, BusylightStatus? initial)
      : super(initial != null
            ? AsyncValue.data(initial)
            : const AsyncValue.loading()) {
    if (initial == null) refresh();
  }

  final BusylightService _service;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_service.getStatus);
  }

  Future<void> setStatus(BusylightStatus status) async {
    // Keep current value visible during the API call — no loading state
    final result = await AsyncValue.guard(() => _service.setStatus(status));
    state = result;
  }

  /// Update state locally without making an API call (e.g. for `colored`)
  void setLocalStatus(BusylightStatus status) {
    state = AsyncValue.data(status);
  }
}

final busylightStatusProvider =
    StateNotifierProvider<BusylightStateNotifier, AsyncValue<BusylightStatus>>(
  (ref) {
    final snapshot = ref.watch(busylightSnapshotProvider).valueOrNull;
    return BusylightStateNotifier(
      ref.watch(busylightServiceProvider),
      snapshot?.status,
    );
  },
);

// ── Brightness ───────────────────────────────────────────────────────────────

class BrightnessNotifier extends StateNotifier<double> {
  BrightnessNotifier(this._service, double initial) : super(initial);
  final BusylightService _service;

  Future<void> set(double value) async {
    state = value;
    await _service.setBrightness(value);
  }

  void silentSet(double value) => state = value;
}

final brightnessProvider = StateNotifierProvider<BrightnessNotifier, double>(
  (ref) {
    final snapshot = ref.watch(busylightSnapshotProvider).valueOrNull;
    return BrightnessNotifier(
      ref.watch(busylightServiceProvider),
      snapshot?.brightness ?? 0.3,
    );
  },
);

// ── Color ─────────────────────────────────────────────────────────────────────

class ColorNotifier extends StateNotifier<BusylightColor> {
  ColorNotifier(this._service, BusylightColor initial) : super(initial);
  final BusylightService _service;

  Future<void> set(BusylightColor color) async {
    state = color;
    await _service.setColor(color);
  }

  void silentSet(BusylightColor color) => state = color;
}

final colorProvider = StateNotifierProvider<ColorNotifier, BusylightColor>(
  (ref) {
    final snapshot = ref.watch(busylightSnapshotProvider).valueOrNull;
    return ColorNotifier(
      ref.watch(busylightServiceProvider),
      snapshot?.color ?? BusylightColor.white,
    );
  },
);

// ── Background polling ────────────────────────────────────────────────────────
// Periodically pulls status + color from the device and silently updates state.

class PollingNotifier extends StateNotifier<void> {
  PollingNotifier(this._ref) : super(null) {
    _start();
  }

  final Ref _ref;
  Timer? _timer;

  void _start() {
    final interval = _ref.read(pollIntervalProvider);
    _timer?.cancel();
    if (interval <= 0) return;
    _timer = Timer.periodic(Duration(seconds: interval), (_) => _poll());
  }

  void restart() => _start();

  Future<void> _poll() async {
    try {
      final service = _ref.read(busylightServiceProvider);
      final results = await Future.wait([
        service.getStatus(),
        service.getColor(),
      ]);
      final status = results[0] as BusylightStatus;
      final color  = results[1] as BusylightColor;
      _ref.read(busylightStatusProvider.notifier).setLocalStatus(status);
      _ref.read(colorProvider.notifier).silentSet(color);
      _ref.read(brightnessProvider.notifier).silentSet(color.brightness);
    } catch (_) {
      // Silently ignore poll errors — connection issues are shown on manual refresh
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pollingProvider = StateNotifierProvider<PollingNotifier, void>(
  (ref) => PollingNotifier(ref),
);