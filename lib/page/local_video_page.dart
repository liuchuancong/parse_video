import 'dart:io';
import 'dart:ui';
import 'package:android_path_provider/android_path_provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:parse_video/components/taskListItem.dart';
import 'package:parse_video/database/downloadVideoDatabase.dart';
import 'package:parse_video/page/video_page.dart';
import 'package:parse_video/plugin/download.dart';

class LocalVideoPage extends StatefulWidget {
  @override
  _LocalVideoPageState createState() => _LocalVideoPageState();
}

class _LocalVideoPageState extends State<LocalVideoPage> {
  @override
  Widget build(BuildContext context) {
    return NeumorphicTheme(
        themeMode: ThemeMode.light,
        theme: NeumorphicThemeData(
          baseColor: Color(0xFFFFFFFF),
          lightSource: LightSource.topLeft,
          depth: 10,
        ),
        darkTheme: neumorphicDefaultDarkTheme.copyWith(
            defaultTextColor: Colors.white70),
        child: _Page());
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
      decoration: BoxDecoration(color: Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(
                  Icons.navigate_before,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )),
          Align(
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

  _openRoute({@required Widget page}) {
    //打开B路由
    Navigator.push(context, PageRouteBuilder(pageBuilder: (BuildContext context,
        Animation animation, Animation secondaryAnimation) {
      return new FadeTransition(
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
    String _musicPath = await AndroidPathProvider.moviesPath;
    String _localPath = _musicPath +
        Platform.pathSeparator +
        'Downloads' +
        Platform.pathSeparator +
        video.movieName;
    print(_localPath);
    _openRoute(page: new VideoScreen(url: _localPath));
  }

  _getLocalVideos() async {
    final List<DwonloadDBInfoMation> _playList =
        await DataBaseDownLoadListProvider.db.queryAll();
    allLocalFiles = _playList;
    var tempList = _playList.map((video) {
      return SimpleListTile(
        title: video.movieName,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
                icon: new Icon(Icons.delete_outline),
                onPressed: () {
                  _showDeleteDialog(video);
                }),
            IconButton(
                icon: new Icon(Icons.play_circle_outline),
                onPressed: () {
                  _playLocalFile(video);
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
      animType: AnimType.SCALE,
      dialogType: DialogType.NO_HEADER,
      body: Container(
        child: Column(
          children: <Widget>[
            SimpleListTile(
              title: '确定删除该视频吗?',
              onTap: null,
            ),
            Container(
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              SizedBox(
                width: 60,
                child: FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('取消')),
              ),
              SizedBox(
                width: 60,
                child: FlatButton(
                    onPressed: () {
                      _deleteLocalFile(video);
                      Navigator.of(context).pop();
                    },
                    child: Text('确定')),
              ),
            ]))
          ],
        ),
      ),
    )..show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NeumorphicBackground(
          backendColor: Colors.red,
          child: Column(
            children: <Widget>[
              _buildTopBar(context),
              Expanded(
                  child: Container(
                decoration: new BoxDecoration(
                  color: Colors.black,
                ),
                child: Container(
                  decoration: new BoxDecoration(
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
