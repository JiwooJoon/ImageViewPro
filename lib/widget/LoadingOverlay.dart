import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 250,
        width: 250,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          boxShadow:  const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 10,
              offset: Offset(0, 5)
            ),
          ],

          // border: Border.all(color: Colors.black, width: 2)
          borderRadius: const BorderRadius.all(
            Radius.circular(15.0)
          )
        ),

        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 15,),
              Text(
                "이미지 로딩중",
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      ),
    );
  }
}