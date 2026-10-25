import 'package:flutter/material.dart';

// The first six colors follow the reference palette. Additional courses receive
// their own stable hue, rather than cycling back to an already assigned color.
const courseColorNames = ['浅蓝', '淡紫', '薄荷', '奶黄', '浅桃', '柔粉'];
const _tints = [
  0xffdbeaff,
  0xffe8ddff,
  0xffdff3e7,
  0xfffff0c2,
  0xffffe4d5,
  0xfffbe2ef,
];
const _accents = [
  0xff5c83df,
  0xff9a77cc,
  0xff42876d,
  0xff99721b,
  0xffae6b43,
  0xffaf5d8e,
];

Color courseTint(int index) => index < _tints.length
    ? Color(_tints[index])
    : HSVColor.fromAHSV(
        1,
        ((index - 6) * 137.508 + 185) % 360,
        .18,
        1,
      ).toColor();
Color courseAccent(int index) => index < _accents.length
    ? Color(_accents[index])
    : HSVColor.fromAHSV(
        1,
        ((index - 6) * 137.508 + 185) % 360,
        .62,
        .65,
      ).toColor();
