import 'package:flutter/material.dart';

class BottomSheetManage {
  Future showDownLoadBottomSheet(
      BuildContext context, List<Widget> optionList) {
    return showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
        ),
        builder: (BuildContext bc) {
          return SafeArea(
            child: Column(
                mainAxisSize: MainAxisSize.min, children: optionList),
          );
        });
  }

  Future showNormalBottomSheet(BuildContext context, List<Widget> optionList) {
    return showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
        ),
        builder: (BuildContext bc) {
          return SafeArea(
            child: Column(
                mainAxisSize: MainAxisSize.min, children: optionList),
          );
        });
  }
}
