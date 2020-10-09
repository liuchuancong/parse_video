import 'dart:ui';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:parse_video/components/loading.dart';
import 'package:parse_video/components/taskListItem.dart';
import 'package:parse_video/database/downloadVideoDatabase.dart';
import 'package:parse_video/database/readyToDownDatabase.dart';
import 'package:parse_video/plugin/download.dart';
import 'package:parse_video/plugin/flutterToastManage.dart';
import 'package:parse_video/plugin/httpManage.dart';

class ReadyToDownPage extends StatefulWidget {
  @override
  _ReadyToDownPageState createState() => _ReadyToDownPageState();
}

class _ReadyToDownPageState extends State<ReadyToDownPage> {
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
  List<ReadyDownLoad> allLocalFiles = [];
  bool showLoading = false;
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
              '待下载列表',
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
    _getLocalMusics();
  }

  _deleteLocalFile(ReadyDownLoad video) async {
    await DataBaseReadyDownLoadProvider.db.deleteMovieWithId(video.id);
    _getLocalMusics();
  }

  _getLocalMusics() async {
    final List<ReadyDownLoad> _playList =
        await DataBaseReadyDownLoadProvider.db.queryAll();
    allLocalFiles = _playList;
    var tempList = _playList.map((video) {
      return SimpleListTile(
          title: video.url,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                  icon: new Icon(Icons.file_download),
                  onPressed: () {
                    _startDownLoad(video);
                  }),
              IconButton(
                  icon: new Icon(Icons.delete_outline),
                  onPressed: () {
                    _showDeleteDialog(video);
                  }),
            ],
          ));
    }).toList();

    setState(() {
      playList = tempList;
    });
  }

  ///验证URL
  bool isUrl(String value) {
    final urlRegex =
        new RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    List<String> urls =
        urlRegex.allMatches(value).map((m) => m.group(0)).toList();
    return RegExp(r"^((https|http|ftp|rtsp|mms)?:\/\/)[^\s]+")
        .hasMatch(urls[0]);
  }

  Future _futureGetLink(String url) async {
    bool validate = isUrl(url);
    String _videoLink = '';
    if (!validate) {
      FlutterToastManage().showToast("请输入正确的网址哦~");
      return;
    }
    final urlRegex =
        new RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    List<String> urls =
        urlRegex.allMatches(url).map((m) => m.group(0)).toList();
    setState(() {
      showLoading = true;
    });
    final Response response =
        await HttpManager().get('video/', data: {'url': urls[0]});
    setState(() {
      showLoading = false;
    });
    Map result = Map.from(response.data);
    if (result['code'] == 200) {
      _videoLink = result['url'];
      FlutterToastManage().showToast("已找到视频,您可选择播放或者下载视频");
    } else {
      FlutterToastManage().showToast(result['msg']);
    }
    return _videoLink;
  }

  _startDownLoad(ReadyDownLoad readyDownLoad) async {
    print(readyDownLoad.url);
    final url = await _futureGetLink(readyDownLoad.url);
    if (url.isEmpty) {
      return;
    }
    var str = readyDownLoad.url.split('/');
    Iterable<String> urlArr = str.where((item) {
      return item != null && item.isNotEmpty;
    });
    String fileName = urlArr.last;
    bool hasDownLoad = await DataBaseDownLoadListProvider.db
        .queryWithFileName(fileName + '.mp4');
    if (hasDownLoad) {
      FlutterToastManage().showToast("已经下载过该视频了哦~");
      _deleteLocalFile(readyDownLoad);
      return;
    }
    await DownLoadInstance().startDownLoad(url, fileName);
    FlutterToastManage().showToast("正在下载中~");
    _deleteLocalFile(readyDownLoad);
  }

  Future _showDeleteDialog(ReadyDownLoad video) async {
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
                  child: Stack(
                    children: <Widget>[
                      ListView(
                        children: ListTile.divideTiles(
                                tiles: playList, context: context)
                            .toList(),
                      ),
                      showLoading ? LoginLoading() : Container()
                    ],
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
