import 'package:flutter/services.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:parse_video/components/nice_button.dart';

class TextSearchField extends StatefulWidget {
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  final Function? clear;
  const TextSearchField(
      {Key? key,
      @required this.hint,
      this.onChanged,
      this.onSubmit,
      this.clear})
      : super(key: key);

  @override
  _TextSearchFieldState createState() => _TextSearchFieldState();
}

class _TextSearchFieldState extends State<TextSearchField> {
  late TextEditingController _controller;
  final double _height = 100.0;
  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  ///使用异步调用获取返回值
  getClipboardDatas() async {
    ClipboardData?  clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null) {
      setState(() {
        _controller.text = clipboardData.text!;
        widget.onChanged!(clipboardData.text ?? '');
        _controller.selection = TextSelection.fromPosition(TextPosition(
            affinity: TextAffinity.downstream,
            offset: _controller.text.length));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
   
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width - 100,
              padding: const EdgeInsets.symmetric(vertical: 20),
              height: _height,
              child: Neumorphic(
                margin: const EdgeInsets.only(
                    left: 18, right: 18, top: 2, bottom: 4),
                style: NeumorphicStyle(
                  color: Colors.white,
                  depth: NeumorphicTheme.embossDepth(context),
                  boxShape: const NeumorphicBoxShape.stadium(),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 2, horizontal: 18),
                child: Center(
                  child: TextField(
                    onChanged: widget.onChanged,
                    controller: _controller,
                    decoration:
                        InputDecoration.collapsed(hintText: widget.hint),
                  ),
                ),
              ),
            ),
            NiceButton(
              width: 60,
              elevation: 8.0,
              radius: 5.0,
              text: "搜索",
              fontSize: 12,
              padding: const EdgeInsets.symmetric(vertical: 2),
              background: const Color(0xff000000),
              onPressed: () {
                widget.onSubmit!(_controller.text);
              },
            ),
          ],
        ),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: <Widget>[
            NiceButton(
             width: MediaQuery.of(context).size.width / 3,
              radius: 52.0,
              text: "粘贴",
              fontSize: 12,
              background: const Color(0xff000000),
              onPressed: () {
                getClipboardDatas();
              },
            ),
            NiceButton(
             width: MediaQuery.of(context).size.width / 3,
              elevation: 8.0,
              radius: 52.0,
              text: "清空",
              fontSize: 12,
              background: const Color(0xff000000),
              onPressed: () {
                widget.clear!();
                setState(() {
                  _controller.clear();
                });
              },
            ),
          ],
        )
      ],
    );
  }
}
