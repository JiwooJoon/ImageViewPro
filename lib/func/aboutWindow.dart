import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/window_info.dart';

// 새창 관련 함수모음

Future<dynamic> handleMethodCall(MethodCall call, int fromWindowId) async {
  if (call.method == 'message_from_secondary') {
    // 두번째 창으로부터 메시지를 받으면..
    final message = call.arguments.toString();

    debugPrint(message);

    return "Message received by main Window";
  }
  return null;
}

Future<void> createWindow({required String windowName, required List<WindowInfo> windows, required String? data}) async {
  try {
    final name = windowName;
    // window의 name은 main부분에서 시작할 때 창을 구별하게 한다.
    // data는 data에용
    final windowConfig = {
      'name' : name,
      'data' : data,
    };

    // 새 윈도우 창 생성
    final windowController = await DesktopMultiWindow.createWindow(
      jsonEncode(windowConfig),
    );

    windowController
      ..setFrame(const Offset(100, 100) & const Size(800, 600))
      ..setTitle(name)
      ..show();

    // 윈도우 관리 배열인데 안씀
    windows.add(
      WindowInfo(id: windowController.windowId, name: name, controller: windowController)
    );
  } catch (e) {
    debugPrint("Failed to make Window");
  }
}

Future<List<WindowInfo>> closeWindow(int windowId, List<WindowInfo> windows) async {
  try {
    // 해당 id를 가진 윈도우 컨트롤러에서 찾는다
    final info = windows.firstWhere((w) => w.id == windowId);

    await info.controller.close();

    windows.removeWhere((w) => w.id == windowId);
    // 그리고 해당 윈도우를 지우는데 지금은 안씀

  } catch (e) {
    debugPrint("Failed to remove Window");
  }

  return windows;
}

// 다른 윈도우로 메시지 보내기
// 해당 아이디의 윈도우로 메시지를 보냄
// 근데 지금은 윈도우안쓰니까 의미가 없긴함
Future<void> sendMessageToWindow(int windowId, List<WindowInfo> windows) async {
  try {
    final response = await DesktopMultiWindow.invokeMethod(windowId, 'message_from_main', 'Hello from main Window');

    debugPrint("response : $response");
  } catch (e) {
    debugPrint("Failed to send Mesasge");
  }
}