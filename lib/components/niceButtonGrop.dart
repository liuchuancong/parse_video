import 'package:flutter/material.dart';
import 'package:parse_video/common/niceButton.dart';

class NiceButtonGroup extends StatelessWidget {
  final Function onTap;
  final String title;
  final IconData icon;
  const NiceButtonGroup(
      {Key key,
      @required this.onTap,
      @required this.title,
      @required this.icon})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          NiceButton(
            radius: 40,
            width: 200,
            elevation: 0.0,
            padding: const EdgeInsets.all(15),
            text: title,
            icon: icon,
            gradientColors: [Color(0xff000000), Color(0xff000000)],
            onPressed: onTap,
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
