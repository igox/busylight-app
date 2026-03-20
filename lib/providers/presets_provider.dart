import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/color_preset.dart';
import '../models/busylight_color.dart';

const _kPresetsKey = 'busylight_color_presets';
const _uuid = Uuid();

class PresetsNotifier extends StateNotifier<List<ColorPreset>> {
  PresetsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPresetsKey);
    if (raw != null) {
      try {
        state = ColorPreset.listFromJson(raw);
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPresetsKey, ColorPreset.listToJson(state));
  }

  Future<void> add(String name, BusylightColor color) async {
    final preset = ColorPreset(
      id:    _uuid.v4(),
      name:  name.trim(),
      color: color,
    );
    state = [...state, preset];
    await _save();
  }

  Future<void> update(String id, String name, BusylightColor color) async {
    state = state.map((p) => p.id == id
        ? ColorPreset(id: id, name: name.trim(), color: color)
        : p).toList();
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _save();
  }
}

final presetsProvider = StateNotifierProvider<PresetsNotifier, List<ColorPreset>>(
  (_) => PresetsNotifier(),
);