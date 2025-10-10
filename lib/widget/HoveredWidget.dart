
import 'package:flutter/cupertino.dart';

class HoveredWidget extends StatefulWidget {
  const HoveredWidget({
    super.key,
    required this.customWidget
  });

  final Widget customWidget;

  @override
  State<HoveredWidget> createState() {
    return _HoveredWidget();
  }
}

class _HoveredWidget extends State<HoveredWidget> {
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
      child: AnimatedOpacity(
        opacity: _isHovered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: widget.customWidget,
      ),
    );
  }
}