
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/main.dart';

class AllOpacityWidget extends ConsumerStatefulWidget {
  const AllOpacityWidget({
    super.key,
    required this.child
  });

  final Widget child;

  @override
  ConsumerState<AllOpacityWidget> createState() {
    return _AllOpacityWidget();
  }
}

class _AllOpacityWidget extends ConsumerState<AllOpacityWidget> {


  @override
  Widget build(BuildContext context) {


    return AnimatedOpacity(
        opacity: ref.read(avoidWidgetProvider) == false ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
    );
  }
}