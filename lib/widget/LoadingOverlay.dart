import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.msg
  });

  final String msg;

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

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 15,),
              Text(
                msg,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      ),
    );
  }
}