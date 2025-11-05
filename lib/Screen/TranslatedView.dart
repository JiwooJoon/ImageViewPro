import 'package:flutter/cupertino.dart';

class TranslatedView extends StatelessWidget {
  const TranslatedView({
    super.key,
    required this.recognized
  });

  final String recognized;

  @override
  Widget build(BuildContext ctx) {

    return SizedBox(
      child: Text(recognized),
    );
  }
}

// 단순 글만 보여주기에 상태없는 위젯으로 씀