import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomSnackBar extends SnackBar {
  const CustomSnackBar({super.key,  required super.content});


  Widget build(BuildContext context) {
    return SnackBar(
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating, // 떠 있는 스타일
      margin: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 20.0),

      content: content,
    );
  }
}