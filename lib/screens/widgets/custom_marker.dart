import 'package:flutter/material.dart';

// A little clipper to draw the triangular pointer
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height) // bottom center
      ..lineTo(0, 0) // top left
      ..lineTo(size.width, 0) // top right
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
