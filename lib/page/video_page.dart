import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

// import 'custom_ui.dart';
class VideoScreen extends StatefulWidget {
  final String url;

  VideoScreen({@required this.url});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final FijkPlayer player = FijkPlayer();

  _VideoScreenState();

  @override
  void initState() {
    super.initState();
    player.setOption(FijkOption.hostCategory, "enable-snapshot", 1);
    player.setOption(FijkOption.playerCategory, "mediacodec-all-videos", 1);
    startPlay();
  }

  void startPlay() async {
    await player.setOption(FijkOption.hostCategory, "request-screen-on", 1);
    await player.setOption(FijkOption.hostCategory, "request-audio-focus", 1);
    await player.setDataSource(widget.url, autoPlay: true).catchError((e) {
      print("setDataSource error: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FijkAppBar.defaultSetting(title: "播放"),
      body: Container(
        child: Center(
          child: FijkView(
            color: Colors.black,
            player: player,
            panelBuilder: fijkPanel2Builder(snapShot: true),
            fsFit: FijkFit.fill,
            // panelBuilder: simplestUI,
            // panelBuilder: (FijkPlayer player, BuildContext context,
            //     Size viewSize, Rect texturePos) {
            //   return CustomFijkPanel(
            //       player: player,
            //       buildContext: context,
            //       viewSize: viewSize,
            //       texturePos: texturePos);
            // },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    player.release();
  }
}

class FijkAppBar extends StatelessWidget implements PreferredSizeWidget {
  FijkAppBar({Key key, @required this.title, this.actions}) : super(key: key);

  final String title;
  final List<Widget> actions;

  FijkAppBar.defaultSetting({Key key, @required this.title}) : actions = null;
  // todo settings page
  //: actions=<Widget>[SettingMenu()];

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      child: AppBar(
        title: Text(this.title),
        actions: this.actions,
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      preferredSize: preferredSize,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(45.0);
}
