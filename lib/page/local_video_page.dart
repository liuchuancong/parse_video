import 'dart:io';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:parse_video/components/drawer_common_page.dart';
import 'package:parse_video/components/simple_list_tile.dart';
import 'package:parse_video/database/download_video_database.dart';
import 'package:parse_video/page/video_page.dart';
import 'package:parse_video/plugin/download.dart';
import 'package:share_plus/share_plus.dart';

class LocalVideoPage extends StatefulWidget {
  const LocalVideoPage({Key? key}) : super(key: key);

  @override
  State<LocalVideoPage> createState() => _LocalVideoPageState();
}

class _LocalVideoPageState extends State<LocalVideoPage> {
  @override
  Widget build(BuildContext context) {
    return DrawerCommonPage(
      page: _Page(),
    );
  }
}

class _Page extends StatefulWidget {
  @override
  __PageState createState() => __PageState();
}

class __PageState extends State<_Page> {
  List<Widget> playList = [];
  List<DwonloadDBInfoMation> allLocalFiles = [];
  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.navigate_before,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )),
          const Align(
            alignment: Alignment.center,
            child: Text(
              '本地视频',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getLocalVideos();
  }

  _openRoute({required Widget page}) {
    //打开B路由
    Navigator.push(context, PageRouteBuilder(pageBuilder: (BuildContext context,
        Animation<double> animation, Animation secondaryAnimation) {
      return FadeTransition(
        opacity: animation,
        child: page,
      );
    }));
  }

  _deleteLocalFile(DwonloadDBInfoMation video) async {
    await DataBaseDownLoadListProvider.db.deleteMovieWithId(video.id);
    await DownLoadInstance().delete(video.taskId);
    _getLocalVideos();
  }

  void _playLocalFile(DwonloadDBInfoMation video) async {
    String moviesPath = await AndroidPathProvider.moviesPath;
    String localPath = '$moviesPath${Platform.pathSeparator}Downloads${Platform.pathSeparator}${video.movieName}';
    _openRoute(page: VideoScreen(url: localPath));
  }
  _shareVideo(DwonloadDBInfoMation video) async{
     String moviesPath = await AndroidPathProvider.moviesPath;
    String localPath = '$moviesPath${Platform.pathSeparator}Downloads${Platform.pathSeparator}${video.movieName}';
    Share.shareXFiles ([XFile(localPath)]);
  }
  _getLocalVideos() async {
    final List<DwonloadDBInfoMation> playDownLoadList =
        await DataBaseDownLoadListProvider.db.queryAll();
    allLocalFiles = playDownLoadList;
    var tempList = playDownLoadList.map((video) {
      return SimpleListTile(
        title: video.movieName,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  _showDeleteDialog(video);
                }),
            IconButton(
                icon: const Icon(Icons.play_circle_outline),
                onPressed: () {
                  _playLocalFile(video);
                }),
            IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  _shareVideo(video);
                }),
          ],
        ),
      );
    }).toList();

    setState(() {
      playList = tempList;
    });
  }

  Future _showDeleteDialog(DwonloadDBInfoMation video) async {
    AwesomeDialog(
      context: context,
      animType: AnimType.scale,
      dialogType: DialogType.noHeader,
      body: Column(
        children: <Widget>[
          const SimpleListTile(
            title: '确定删除该视频吗?',
            onTap: null,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            SizedBox(
              width: 60,
              child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消')),
            ),
            SizedBox(
              width: 60,
              child: TextButton(
                  onPressed: () {
                    _deleteLocalFile(video);
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定')),
            ),
          ])
        ],
      ),
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NeumorphicBackground(
          child: Column(
            children: <Widget>[
              _buildTopBar(context),
              Expanded(
                  child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    //设置四周圆角 角度
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0)),
                  ),
                  child: ListView(
                    children:
                        ListTile.divideTiles(tiles: playList, context: context)
                            .toList(),
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
