import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FlutterToastManage {
  showToast(String msg,
      {int seconds = 1,
      Color color = Colors.white,
      ToastGravity gravity = ToastGravity.CENTER}) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      timeInSecForIosWeb: seconds,
      backgroundColor: Colors.black,
      textColor: color,
      fontSize: 14.0,
    );
  }
}
