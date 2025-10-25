
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OpacityWidget extends ConsumerStatefulWidget {
  OpacityWidget({
    super.key,
    required this.child,
    required this.enable
  });

  final Widget child;
  bool enable = false;

  @override
  ConsumerState<OpacityWidget> createState() {
    return _OpacityWidget();
  }
}

class _OpacityWidget extends ConsumerState<OpacityWidget> {

  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    // 등장 시 부드럽게 나타나도록
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() => _hovered = true);
    });
  }


  @override
  Widget build(BuildContext context) {


    return widget.enable ? MouseRegion(
      onEnter: (e) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (e) {
        setState(() {
          _hovered = false;
        });
      },
      child: AnimatedOpacity(
        opacity: _hovered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    ) : widget.child;
  }
}