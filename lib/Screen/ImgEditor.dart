import 'package:flutter/cupertino.dart';

class TranslatedView extends StatefulWidget {
  const TranslatedView({
    super.key,
    required this.recognized
  });

  // final List<String> recognized = [];
  final String recognized;

  @override
  State<TranslatedView> createState() => _TranslatedViewState();
}

class _TranslatedViewState extends State<TranslatedView> {
  @override
  Widget build(BuildContext ctx) {
    // String strings = recognized.join("\n");

    return SizedBox(
      child: Text(widget.recognized),
    );
  }
}