
import 'package:flutter/cupertino.dart';

class ScaleHoveredWidget extends StatefulWidget {
  const ScaleHoveredWidget({
    super.key,
    required this.customWidget
  });

  final Widget customWidget;

  @override
  State<ScaleHoveredWidget> createState() {
    return _ScaleHoveredWidget();
  }
}

class _ScaleHoveredWidget extends State<ScaleHoveredWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (e) {
        setState(() {
          _isHovered = false;
        });
      },
      child: AnimatedScale(
        scale: _isHovered ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.customWidget,
      ),
    );
  }
}