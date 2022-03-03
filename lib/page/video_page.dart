import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';

// import 'custom_ui.dart';
class VideoScreen extends StatefulWidget {
  final String url;
  const VideoScreen({Key? key, required this.url}) : super(key: key);
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
    await player.setDataSource(widget.url, autoPlay: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("播放"),backgroundColor: const Color.fromARGB(255, 0, 8, 12),),
      body: Center(
        child: FijkView(
          color: Colors.black,
          player: player,
          panelBuilder: fijkPanel2Builder(snapShot: true),
          fsFit: FijkFit.fill,
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
  const FijkAppBar({Key? key, required this.title, required this.actions})
      : super(key: key);

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      child: AppBar(
        title: Text(title),
        actions: actions,
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      preferredSize: preferredSize,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(45.0);
}
