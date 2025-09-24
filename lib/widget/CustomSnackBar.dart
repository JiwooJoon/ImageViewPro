import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomSnackBar extends StatelessWidget {
  const CustomSnackBar({super.key, required this.msg});

  final String msg;

  @override
  Widget build(BuildContext context) {
    return SnackBar(
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating, // 떠 있는 스타일
      margin: const EdgeInsets.fromLTRB(16, 0, 0, 100),

      content: Text(msg),
    );
  }
}