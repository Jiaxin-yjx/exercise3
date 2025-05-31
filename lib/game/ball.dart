import 'dart:math';
import 'package:flutter/material.dart';

class Ball {
  double x;
  double y;
  final Color color;
  final bool isGift; // New field to mark gift type

  Ball({
    required this.x,
    required this.y,
    required this.color,
    this.isGift = false,
  });

  static final Random _random = Random();

  static Ball random(double screenWidth) {
    // 10% chance to drop a gift
    bool dropGift = _random.nextDouble() < 0.1;

    return Ball(
      x: _random.nextDouble() * (screenWidth - 30),
      y: 0,
      color: dropGift ? Colors.transparent : Colors.primaries[_random.nextInt(Colors.primaries.length)],
      isGift: dropGift,
    );
  }
}
