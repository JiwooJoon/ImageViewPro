
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_view_pro/widget/OptionWindow.dart';

class SecondaryWindowApp extends StatelessWidget {
  final int windowId;
  final String windowName;

  const SecondaryWindowApp({
    super.key,
    required this.windowId,
    required this.windowName
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: windowName,
      home: _SecondaryWindow(
        windowId: windowId,
        windowName: windowName,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _SecondaryWindow extends StatefulWidget {
  final int windowId;
  final String windowName;

  const _SecondaryWindow({
    required this.windowId,
    required this.windowName,
  });

  @override
  State<_SecondaryWindow> createState() => _SecondaryWindowState();
}

class _SecondaryWindowState extends State<_SecondaryWindow> {
  @override
  void initState() {
    super.initState();

    // 메인 윈도우로부터 메시지를 받는다
    DesktopMultiWindow.setMethodHandler(_handleMethodCall);
  }

  @override
  Widget build(BuildContext context) {

    if (widget.windowName == "option") {
      return const MaterialApp(
        title: "설정",
        home: OptionWindow(),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.windowName),
          backgroundColor: Colors.grey[100],
        ),
        body: Center(
          child: TextButton(onPressed: _sendMessageToMain, child: const Text('Send a message to the main Window')),
        ),
      );
    }

  }

  Future<dynamic> _handleMethodCall(MethodCall call, int fromWindowId) async {
    if (call.method == 'message_from_main') {
      final message = call.arguments.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      return 'Message received by secondary window ${widget.windowId}';
    }
    return null;
  }

  Future<void> _sendMessageToMain() async {
    try {
      // 메인 윈도우의 아이디 번호는 항상 0
      await DesktopMultiWindow.invokeMethod(0, 'message_from_secondary', 'Hello form ${widget.windowName}');

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Failed to send Message: $e')));
      }
    }
  }
}