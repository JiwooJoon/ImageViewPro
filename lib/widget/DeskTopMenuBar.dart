import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/main.dart';

class DeskTopMenuBar extends ConsumerWidget implements PreferredSizeWidget {
  const DeskTopMenuBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stateProvider);

    return AppBar(
      backgroundColor: Colors.grey,
      elevation: 0,
      actions: [
        PopupMenuButton(
            itemBuilder: (context) => const [

            ]
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 0.5);
}
