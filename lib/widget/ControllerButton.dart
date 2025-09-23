import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ControllerButton extends StatelessWidget {
  ControllerButton({super.key, required this.btnCallback, required this.icon});

  VoidCallback btnCallback;
  Icon icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: btnCallback,
      icon: icon,
    );
  }
}