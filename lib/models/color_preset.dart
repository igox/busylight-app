import 'dart:convert';
import 'busylight_color.dart';

class ColorPreset {
  final String id;
  final String name;
  final BusylightColor color;

  const ColorPreset({
    required this.id,
    required this.name,
    required this.color,
  });

  factory ColorPreset.fromJson(Map<String, dynamic> json) {
    return ColorPreset(
      id:    json['id'] as String,
      name:  json['name'] as String,
      color: BusylightColor.fromJson(json['color'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':    id,
    'name':  name,
    'color': {
      'r': color.r,
      'g': color.g,
      'b': color.b,
      'brightness': color.brightness,
    },
  };

  static List<ColorPreset> listFromJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => ColorPreset.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<ColorPreset> presets) {
    return jsonEncode(presets.map((p) => p.toJson()).toList());
  }
}