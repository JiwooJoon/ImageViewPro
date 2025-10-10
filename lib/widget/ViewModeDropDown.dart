
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/main.dart';

class ViewModeDropDown extends ConsumerStatefulWidget {
  const ViewModeDropDown({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ViewModeDropDown();
}

class _ViewModeDropDown extends ConsumerState<ViewModeDropDown> {

  // final List<BoxFit> _fitOpts = [
  //   BoxFit.contain,
  //   BoxFit.scaleDown,
  //   BoxFit.fitWidth,
  //   BoxFit.fitHeight,
  //   BoxFit.none,
  // ];

  final Map<String, BoxFit> _fitOpts = {
    "창에 맞게" : BoxFit.contain,
    "이미지 원본" : BoxFit.none,
    "너비에 맞게" : BoxFit.fitWidth,
    "높이에 맞게" : BoxFit.fitHeight,
  };

  String _selectedFit = "창에 맞게";

  @override
  Widget build(BuildContext context) {
    return Material(
      child: DropdownButton(
        value: _selectedFit,
        onChanged: (value) {
          setState(() {
            _selectedFit = value as String;
            ref.read(viewModeProvider.notifier).state = _fitOpts[value]!;
            ref.read(stateProvider.notifier).updateZoom(1.0);
          });
        },
        items: _fitOpts.keys.map((e) => DropdownMenuItem(
          value: e,
          child:  Text(e)
        )).toList()
      ),
    );
  }
}