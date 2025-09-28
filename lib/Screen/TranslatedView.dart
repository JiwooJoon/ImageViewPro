import 'package:flutter/cupertino.dart';

class TranslatedView extends StatelessWidget {
  const TranslatedView({
    super.key,
    required this.recognized
  });

  // final List<String> recognized = [];
  final String recognized;

  @override
  Widget build(BuildContext ctx) {
    // String strings = recognized.join("\n");

    return SizedBox(
      child: Text(recognized),
    );
  }
}