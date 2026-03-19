import 'package:flutter/material.dart';

class BusylightColor {
  final int r;
  final int g;
  final int b;
  final double brightness;

  const BusylightColor({
    required this.r,
    required this.g,
    required this.b,
    this.brightness = 1.0,
  });

  factory BusylightColor.fromJson(Map<String, dynamic> json) {
    return BusylightColor(
      r: (json['r'] as num).toInt(),
      g: (json['g'] as num).toInt(),
      b: (json['b'] as num).toInt(),
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'r': r,
        'g': g,
        'b': b,
        'brightness': brightness,
      };

  Color toFlutterColor() => Color.fromARGB(255, r, g, b);

  factory BusylightColor.fromFlutterColor(Color color, {double brightness = 1.0}) {
    return BusylightColor(
      r: color.red,
      g: color.green,
      b: color.blue,
      brightness: brightness,
    );
  }

  BusylightColor copyWith({int? r, int? g, int? b, double? brightness}) {
    return BusylightColor(
      r: r ?? this.r,
      g: g ?? this.g,
      b: b ?? this.b,
      brightness: brightness ?? this.brightness,
    );
  }

  static const green  = BusylightColor(r: 0,   g: 255, b: 0);
  static const red    = BusylightColor(r: 255, g: 0,   b: 0);
  static const yellow = BusylightColor(r: 255, g: 200, b: 0);
  static const white  = BusylightColor(r: 255, g: 255, b: 255);
  static const off    = BusylightColor(r: 0,   g: 0,   b: 0,   brightness: 0);
}
