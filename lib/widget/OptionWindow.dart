import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_view_pro/func/aboutWindow.dart';

class OptionWindow extends StatefulWidget {
  const OptionWindow({super.key});

  @override
  State<OptionWindow> createState() => _OptionWindowState();
}

class _OptionWindowState extends State<OptionWindow> {
  final TextEditingController _apiKeyController = TextEditingController();
  String? _selectedValue = "Google Translate API";

  @override
  Widget build(BuildContext ctx) {

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
                        Row(
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
                                border: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(Radius.zero)
                                ),
                              ),

                            ),
                          ),
                        ),
                        Text(
                          "사용하는 번역용 ai의 key를 적용합니다.\n"
                              "api키는 암호화되어 저장됩니다",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade800
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25,),
                    // ai 지정
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                              items: [
                                'Google Translate API',
                                'Microsoft Translator',
                                'DeepL',
                                'Amazon Translate',
                                'LibreTranslate'
                              ].map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e)
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedValue = value;
                                });
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