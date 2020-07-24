import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoginLoading extends StatelessWidget {
  const LoginLoading({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black12.withOpacity(0.2),
        child: new Center(
          child: new Container(
            width: MediaQuery.of(context).size.width - 150,
            height: MediaQuery.of(context).size.width / 5,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: Colors.black.withOpacity(0.9)),
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 30,
                ),
                SpinKitRing(
                  color: Colors.white,
                  lineWidth: 3,
                  size: 30,
                ),
                SizedBox(
                  width: 30,
                ),
                Text(
                  '正在努力查找视频中...',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w100),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
