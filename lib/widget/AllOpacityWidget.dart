
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

// 전체 가림 버튼을 누를시 자식 위젯을 가려주는 투명화 위젯