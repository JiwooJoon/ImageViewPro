import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_view_pro/func/googleLogin.dart';
import 'package:image_view_pro/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/stateModel.dart';

class OptionWindow extends ConsumerStatefulWidget {
  const OptionWindow({super.key});

  @override
  ConsumerState<OptionWindow> createState() => _OptionWindowState();
}

class _OptionWindowState extends ConsumerState<OptionWindow> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiKey2Controller = TextEditingController();
  final opts = [
    'Google Translate API',
    'Microsoft Translator',
    'DeepL',
    'LibreTranslate'
  ];

  String? _selectedValue;
  String? _cred;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiKey2Controller.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final state = ref.read(stateProvider);
    _loadKeys(state);
    _loadSelectedValue();

  }

  Future<void> _loadSelectedValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedValue = prefs.getString('selected_api') ?? opts.first;
    });
  }

  Future<void> _saveSelectedValue(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_api', value);
  }



  Future<void> _loadKeys(StateModel state) async {
    final apiKey = await state.storage.read(key: 'apiKey');
    final apiKey2 = await state.storage.read(key: 'apiKey');
    _cred = await state.storage.read(key: "cred");

    if (!mounted) return;

    setState(() {
      _apiKeyController.text = apiKey ?? "";
      _apiKey2Controller.text = apiKey2 ?? "";
    });
  }

  @override
  Widget build(BuildContext ctx) {

    final state = ref.watch(stateProvider);

    return Scaffold(
      body: Container(
        color: Colors.grey,
        child: Stack(
          children: [
            // 타이틀
            const Positioned(
              top: 25,
              left: 25,
              child: SizedBox(
                child: Text(
                  "설정",
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Colors.black
                  ),
                ),
              ),
            ),


            Positioned(
                height: MediaQuery.of(ctx).size.height * 0.7,
                width: 600,
                top: 80,
                left: 25,
                child: ListView(
                  scrollDirection: Axis.vertical,
                  children: [
                    // API key 입력
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              "Api 키 입력 ",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black
                              ),
                            ),
                          ],
                        ),
                        Material(
                          child: SizedBox(
                            width: 500,
                            // color: Colors.grey,
                            child: TextField(
                              controller: _apiKeyController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade400,
                                focusColor: Colors.grey.shade300,
                                border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.zero)
                                ),
                              ),

                            ),
                          ),
                        ),
                        Text(
                          "Google Cloud Vision의 API Key가 필요합니다.\n",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade800
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10,),
                    // ai 지정
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "번역용 ai 지정 ",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(),
                            color: Colors.grey.shade400,
                          ),
                          child: DropdownButton(
                              value: _selectedValue,
                              items: opts.map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e)
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedValue = value!;
                                });
                                _saveSelectedValue(value!);

                              }
                          ),
                        ),
                        Text(
                          "번역 기능사용시 사용할 api를 선택합니다.\n",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade800
                          ),
                        ),
                        if (_selectedValue != "Google Translate API" && _selectedValue != "LibreTranslate")
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    "번역 Api 키 입력 ",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black
                                    ),
                                  ),
                                ],
                              ),
                              Material(
                                child: SizedBox(
                                  width: 500,
                                  // color: Colors.grey,
                                  child: TextField(
                                    controller: _apiKey2Controller,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey.shade400,
                                      focusColor: Colors.grey.shade300,
                                      border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(Radius.zero)
                                      ),
                                    ),

                                  ),
                                ),
                              ),
                              Text(
                                "사용하는 번역용 ai의 key를 적용합니다.\n"
                                    "api키는 암호화되어 저장됩니다",
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade800
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10,),

                    // 로그인 설정
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "구글 로그인 설정",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.black
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            if (_cred == null) {
                              final result = await loginAndSave(state.options, state.storage);

                              if (result == "Success") {
                                if (mounted) {


                                }
                              } else {
                                if (mounted) {
                                  Flushbar(
                                    message: "로그인 저장 실패",
                                    duration: const Duration(seconds: 2),
                                    flushbarPosition: FlushbarPosition.TOP,
                                    margin: const EdgeInsets.all(20),
                                    borderRadius: BorderRadius.circular(10),
                                    backgroundColor: Colors.grey.shade500,
                                  ).show(ctx);
                                }
                              }
                            } else {
                              await state.storage.delete(key: "cred");
                              if (mounted) {
                                Flushbar(
                                  message: "로그인 토큰을 제거했습니다. 다음부터는 로그인이 필요합니다.",
                                  duration: const Duration(seconds: 2),
                                  flushbarPosition: FlushbarPosition.TOP,
                                  margin: const EdgeInsets.all(20),
                                  borderRadius: BorderRadius.circular(10),
                                  backgroundColor: Colors.grey.shade500,
                                ).show(ctx);
                              }
                            }

                            setState(() {

                            });
                          },
                          child: Text(
                           _cred == null ? "로그인" : "로그아웃"
                          )
                        )
                      ],
                    )

                  ],

                )
            ),

            // 버튼
            Positioned(
                bottom: 25,
                right: 25,
                child: ElevatedButton(
                  onPressed: () {
                    state.storage.write(key: "apiKey", value: _apiKeyController.text);
                    state.storage.write(key: "apiKey2", value: _apiKey2Controller.text);

                    Navigator.of(context).pop();
                  },
                  child: const Text("완료"),
                ),
            )
          ],
        ),
      ),
    );
  }
}
