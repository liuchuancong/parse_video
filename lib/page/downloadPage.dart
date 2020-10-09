import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flashy_tab_bar/flashy_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:parse_video/components/bottomSheet.dart';
import 'package:parse_video/components/loading.dart';
import 'package:parse_video/components/taskListItem.dart';
import 'package:parse_video/plugin/download.dart';
import 'package:parse_video/plugin/flutterToastManage.dart';
import 'package:parse_video/plugin/httpManage.dart';

class DownLoadPage extends StatefulWidget {
  @override
  _DownLoadPageState createState() => _DownLoadPageState();
}

class _DownLoadPageState extends State<DownLoadPage> {
  @override
  Widget build(BuildContext context) {
    return NeumorphicTheme(
        themeMode: ThemeMode.light,
        theme: NeumorphicThemeData(
          defaultTextColor: Color(0xFF3E3E3E),
          baseColor: Colors.white,
          intensity: 0.5,
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
  List<Widget> tasksList = [];
  int _selectedIndex = 0;
  bool showLoading = false;
  List<DownloadTask> tasks = [];
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
            child: Container(
              width: 150,
              child: FlashyTabBar(
                backgroundColor: Colors.black,
                animationCurve: Curves.linear,
                selectedIndex: _selectedIndex,
                showElevation: false, // use this to remove appBar's elevation
                onItemSelected: (index) => loadTasks(index),
                items: [
                  FlashyTabBarItem(
                    activeColor: Colors.white,
                    icon: Icon(
                      Icons.cloud_download,
                      color: Colors.white,
                    ),
                    title: Text(
                      '下载中',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  FlashyTabBarItem(
                    activeColor: Colors.white,
                    icon: Icon(
                      Icons.queue_music,
                      color: Colors.white,
                    ),
                    title: Text(
                      '已下载',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///验证URL
  bool isUrl(String value) {
    final urlRegex =
        new RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    List<String> urls =
        urlRegex.allMatches(value).map((m) => m.group(0)).toList();
    print(urls);
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

  _startDownLoad(videoFileName) async {
    final url = await _futureGetLink(videoFileName);
    if (url.isEmpty) {
      return;
    }
    await DownLoadInstance().startDownLoad(url, videoFileName);
    FlutterToastManage().showToast("正在下载中~");
    loadTasks(_selectedIndex);
  }

  @override
  void initState() {
    loadTasks(_selectedIndex);

    super.initState();
  }

  loadTasks(int index) async {
    String query = '';
    if (index == 0) {
      query = 'SELECT * FROM task WHERE status!=3';
    } else {
      query = 'SELECT * FROM task WHERE status=3';
    }
    tasks = await FlutterDownloader.loadTasksWithRawQuery(query: query);
    List<DownloadTask> taskTemp = [];
    for (var i = 0; i < tasks.length; i++) {
      print(tasks[i].savedDir);
      File file =
          File(tasks[i].savedDir + Platform.pathSeparator + tasks[i].filename);
      bool exits = await file.exists();
      if (exits) {
        taskTemp.add(tasks[i]);
      } else {
        DownLoadInstance().delete(tasks[i].taskId);
      }
    }
    print(taskTemp);
    tasksList = taskTemp
        .map((DownloadTask movie) => TaskListTile(
              movie: movie,
              refrish: () {
                loadTasks(_selectedIndex);
              },
              onPressed: () {
                showBottomOperateSheet(movie);
              },
            ))
        .toList();
    setState(() {
      _selectedIndex = index;
    });
  }

  showBottomOperateSheet(DownloadTask movie) async {
    if (_selectedIndex == 0) {
      await BottomSheetManage().showDownLoadBottomSheet(
        context,
        [
          SimpleListTile(
            title: '取消下载',
            onTap: () {
              Navigator.pop(context);
              DownLoadInstance().cancel(movie.taskId);
            },
          ),
          SimpleListTile(
            title: '暂停下载',
            onTap: () {
              Navigator.pop(context);
              DownLoadInstance().pause(movie.taskId);
            },
          ),
          SimpleListTile(
            title: '恢复下载',
            onTap: () {
              Navigator.pop(context);
              DownLoadInstance()
                  .resume(movie.taskId)
                  .then((value) => {loadTasks(_selectedIndex)});
            },
          ),
          SimpleListTile(
            title: '重试',
            onTap: () {
              Navigator.pop(context);
              DownLoadInstance().remove(movie.taskId);
              _startDownLoad(movie.filename);
            },
          ),
          SimpleListTile(
            title: '删除',
            onTap: () {
              Navigator.pop(context);
              DownLoadInstance().remove(movie.taskId);
            },
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Container(
              color: Colors.black,
              child: Column(
                children: <Widget>[
                  _buildTopBar(context),
                  Expanded(
                    child: Container(
                      decoration: new BoxDecoration(
                        color: Colors.white,
                        //设置四周圆角 角度
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0)),
                      ),
                      child: ListView(children: tasksList),
                    ),
                  ),
                ],
              ),
            ),
          ),
          showLoading ? LoginLoading() : Container()
        ],
      ),
    );
  }
}
