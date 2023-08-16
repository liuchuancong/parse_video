import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:parse_video/components/drawer_common_page.dart';
import 'package:parse_video/components/loading.dart';
import 'package:parse_video/components/simple_list_tile.dart';
import 'package:parse_video/database/download_video_database.dart';
import 'package:parse_video/database/ready_to_down_database.dart';
import 'package:parse_video/plugin/download.dart';
import 'package:parse_video/plugin/flutter_toast_manage.dart';
import 'package:parse_video/plugin/http_manage.dart';

class ReadyToDownPage extends StatefulWidget {
  const ReadyToDownPage({Key? key}) : super(key: key);

  @override
  State<ReadyToDownPage> createState() => _ReadyToDownPageState();
}

class _ReadyToDownPageState extends State<ReadyToDownPage> {
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
  List<ReadyDownLoad> allLocalFiles = [];
  bool showLoading = false;
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
    final List<ReadyDownLoad> playDownLoadList =
        await DataBaseReadyDownLoadProvider.db.queryAll();
    allLocalFiles = playDownLoadList;
    var tempList = playDownLoadList.map((video) {
      return SimpleListTile(
          title: video.url,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                  icon: const Icon(Icons.file_download),
                  onPressed: () {
                    _startDownLoad(video);
                  }),
              IconButton(
                  icon: const Icon(Icons.delete_outline),
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
    final urlRegExp = RegExp(
        r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");
    List<String?> urlMatches =
        urlRegExp.allMatches(value).map((m) => m.group(0)).toList();
    return urlMatches.isNotEmpty;
  }

  Future _futureGetLink(String url) async {
    bool validate = isUrl(url);
    String videoLink = '';
    if (!validate) {
      FlutterToastManage().showToast("请输入正确的网址哦~");
      return;
    }
    final urlRegExp = RegExp(
        r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");
    List<String?> urlMatches =
        urlRegExp.allMatches(url).map((m) => m.group(0)).toList();
    setState(() {
      showLoading = true;
    });
    Response? response =
        await HttpManager().get('video/', data: {'url': urlMatches.first});
    setState(() {
      showLoading = false;
    });

    if (response != null) {
      var responseData = jsonDecode(response.data);
      if (responseData['code'] == 200) {
        videoLink = responseData['data']['url'];
        FlutterToastManage().showToast("已找到视频,您可选择播放或者下载视频");
      } else {
        FlutterToastManage().showToast(responseData['msg']);
      }
    }
    return videoLink;
  }

  _startDownLoad(ReadyDownLoad readyDownLoad) async {
    final url = await _futureGetLink(readyDownLoad.url);
    if (url.isEmpty) {
      return;
    }
    var str = readyDownLoad.url.split('/');
    Iterable<String> urlArr = str.where((item) {
      return item.isNotEmpty;
    });

    String fileName = urlArr.last;
    bool hasDownLoad = await DataBaseDownLoadListProvider.db
        .queryWithFileName('$fileName.mp4');
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
          backendColor: Colors.red,
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
                  child: Stack(
                    children: <Widget>[
                      ListView(
                        children: ListTile.divideTiles(
                                tiles: playList, context: context)
                            .toList(),
                      ),
                      showLoading ? const LoginLoading() : Container()
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
