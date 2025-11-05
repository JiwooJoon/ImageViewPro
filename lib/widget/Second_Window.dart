
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_view_pro/Screen/TranslatedView.dart';
import 'package:image_view_pro/widget/SimpleImageEditor.dart';
import 'dart:math' as math;

class SecondaryWindowApp extends StatelessWidget {
  final int windowId;
  final String windowName;
  final String result;

  const SecondaryWindowApp({
    super.key,
    required this.windowId,
    required this.windowName,
    required this.result
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: windowName,
      home: _SecondaryWindow(
        windowId: windowId,
        windowName: windowName,
        result: result,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _SecondaryWindow extends StatefulWidget {
  final int windowId;
  final String windowName;
  final String result;

  const _SecondaryWindow({
    required this.windowId,
    required this.windowName,
    required this.result
  });

  @override
  State<_SecondaryWindow> createState() => _SecondaryWindowState();
}

class _SecondaryWindowState extends State<_SecondaryWindow> with TickerProviderStateMixin {

  // late AnimationController animationController;
  // late Animation<Color?> _twoColors;
  //
  // late Color endColor;

  @override
  void initState() {
    super.initState();

    // animationController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(milliseconds: 2000)
    // )..repeat(reverse: true);
    //
    // final startColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
    // endColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
    //
    // _twoColors = ColorTween(begin: startColor, end: endColor)
    //     .animate(animationController);


    // 메인 윈도우로부터 메시지를 받는다
    DesktopMultiWindow.setMethodHandler(_handleMethodCall);

  }

  @override
  void dispose() {
    // animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color startColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
    Color endColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);


    if (widget.windowName == "translate_window") {
      return MaterialApp(
        title: "번역",
        home: Scaffold(
          appBar: AppBar(
            title: Text(widget.windowName),
            backgroundColor: Colors.grey[400],
          ),
          body: TranslatedView(recognized: widget.result),
        ),
      );
    } else if (widget.windowName == "editor") { // 지금은 안씀
      return MaterialApp(
        title: "이미지 에디터",
        home: SimpleImageEditor(
          imagePath: widget.result,
        ),
      );
    }
    else {
      return Scaffold(
        backgroundColor: Colors.grey.shade500,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/ohWhatASxxx.png',
                width: 300,
                height: 300,
              ),

              TweenAnimationBuilder<Color?>(
                tween: ColorTween(begin: startColor, end: endColor),
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOutSine,
                onEnd: () {
                  setState(() {
                    startColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
                    endColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
                  });
                },
                builder: (BuildContext context, Color? color, Widget? child) {
                  return Text(
                    "LaL 멀티 이미지 뷰어",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.w900,
                      color: color,
                      shadows: const [
                        Shadow(offset: Offset(1 , 1), blurRadius: 1, color: Colors.black)
                      ]
                    ),
                  );
                }
              ),
              const Text(
                "LaL 멀티 이미지 뷰어는 이미지를 멀티 뷰로 보며 여러 편리한 기능을 제공하는 맥가이버입니다.\n"
                    "사용해 주셔서 감사합니다",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(offset: Offset(1 , 1), blurRadius: 1, color: Colors.black)
                    ]
                ),
                  textAlign: TextAlign.center,
              ),
              const Text(
                  "맹근놈 : ㅈㅈㅇ"
              ),
              const Text(
                "2025 졸업과제인데 졸업을 못해 2025/11/05"
              )
            ],
          )
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