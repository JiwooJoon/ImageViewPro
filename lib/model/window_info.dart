import 'package:desktop_multi_window/desktop_multi_window.dart';

class WindowInfo {
  final int id;
  final String name;
  final WindowController controller;

  WindowInfo({
    required this.id,
    required this.name,
    required this.controller
  });
}