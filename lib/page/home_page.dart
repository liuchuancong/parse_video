import 'dart:isolate';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:parse_video/components/loading.dart';
import 'package:parse_video/components/nice_button.dart';
import 'package:parse_video/components/simple_list_tile.dart';
import 'package:parse_video/components/text_search_field.dart';
import 'package:parse_video/database/download_video_database.dart';
import 'package:parse_video/database/ready_to_down_database.dart';
import 'package:parse_video/model/current_down_load.dart';
import 'package:parse_video/page/download_page.dart';
import 'package:parse_video/page/local_video_page.dart';
import 'package:parse_video/page/ready_to_down_page.dart';
import 'package:parse_video/page/video_page.dart';
import 'package:parse_video/plugin/download.dart';
import 'package:parse_video/plugin/flutter_toast_manage.dart';
import 'package:parse_video/plugin/http_manage.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  String result = '';
  String _videoLink = '';
  final ReceivePort _port = ReceivePort();
  bool showLoading = false;
  late DateTime lastPopTime = DateTime.now().subtract(const Duration(days: 1));
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

  _onTextSearchFiledChanged(String text) {
    final urlRegExp = RegExp(
        r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");
    List<String?> urlMatches =
        urlRegExp.allMatches(text).map((m) => m.group(0)).toList();
    if (urlMatches.isNotEmpty) {
      result = urlMatches.first!;
    }
  }

  _onTextSearchFiledSubmited(String text) {
    if (DateTime.now().difference(lastPopTime) > const Duration(seconds: 2)) {
      lastPopTime = DateTime.now();
      _futureGetLink(text);
    } else {
      lastPopTime = DateTime.now();
    }
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
    FocusScope.of(context).requestFocus(FocusNode()); // 获取焦点
    if (url.isEmpty) {
      FlutterToastManage().showToast("请输入网址~");
      return;
    }
    bool validate = isUrl(url);
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
      result = urlMatches.first ?? '';
    });
    if (response != null) {
      Map responseData = Map.from(response.data);
      if (responseData['code'] == 200) {
        _videoLink = responseData['url'];
        FlutterToastManage().showToast("已找到视频,您可选择播放或者下载视频");
      } else {
        FlutterToastManage().showToast(responseData['msg']);
      }
    }
  }

  _startDownLoad() async {
    if (_videoLink.isEmpty) {
      FlutterToastManage().showToast("请先搜索下载视频~");
      return;
    }
    var str = result.split('/');
    Iterable<String> urlArr = str.where((item) {
      return item.isNotEmpty;
    });

    String fileName = urlArr.last;
    bool hasDownLoad = await DataBaseDownLoadListProvider.db
        .queryWithFileName(fileName + '.mp4');
    if (hasDownLoad) {
      FlutterToastManage().showToast("已经下载过该视频了哦~");
      return;
    }
    DownLoadInstance().startDownLoad(_videoLink, fileName);
  }

  _addVideoToReadyDownload() async {
    if (result.isEmpty) {
      FlutterToastManage().showToast("请输入视频链接~");
      return;
    }
    bool hasadded = await DataBaseReadyDownLoadProvider.db.queryWithUrl(result);
    if (!hasadded) {
      await DataBaseReadyDownLoadProvider.db.insetDB(url: result);
      FlutterToastManage().showToast("已添加到待下载列表了~");
    } else {
      FlutterToastManage().showToast("已经添加过了~");
    }
  }

  @pragma('vm:entry-point')
  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  _portListen() {
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      context.read<CurrentDownLoad>().setDownLoadAbleItem(
          DownLoadAbleItem(id: id, progress: progress, status: status));
    });
    FlutterDownloader.registerCallback(downloadCallback);
  }

  Future<bool> _onBackPressed() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0))),
              contentPadding: const EdgeInsets.only(top: 10.0),
              title: const Text('确定退出程序吗?'),
              actions: <Widget>[
                TextButton(
                  child:
                      const Text('暂不', style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
                TextButton(
                    child: const Text(
                      '确定',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () {
                      Navigator.pop(context, true);
                    }),
              ],
            ));
  }

  @override
  void initState() {
    DownLoadInstance().prepare();
    _portListen();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: const Color(0xFF000000),
          actionsIconTheme: NeumorphicTheme.currentTheme(context).iconTheme,
          leading: IconButton(
            icon: NeumorphicIcon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: NeumorphicText(
            "去水印视频下载",
            style: const NeumorphicStyle(
              depth: 4, //customize depth here
              color: Colors.white, //customize color here
            ),
            textStyle: NeumorphicTextStyle(
              fontSize: 16, //customize size here
            ),
          ),
        ),
        drawer: Drawer(
          child: Column(
            children: [
              const UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/2.png"), fit: BoxFit.cover)),
                accountEmail: Text(''),
                accountName: Text(''),
              ),
              SimpleListTile(
                title: '待下载列表',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _openRoute(page: const ReadyToDownPage());
                },
              ),
              SimpleListTile(
                title: '本地视频',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _openRoute(page: const LocalVideoPage());
                },
              ),
              SimpleListTile(
                title: '我的下载',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _openRoute(page: const DownloadPage());
                },
              )
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: Container(
            width: double.maxFinite,
            decoration: const BoxDecoration(
              color: Colors.white,
              //设置四周圆角 角度
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0)),
            ),
            child: Stack(
              children: [
                ListView(
                  children: <Widget>[
                    const SizedBox(
                      height: 20,
                    ),
                    TextSearchField(
                      hint: "请输入视频链接",
                      onChanged: (text) {
                        _onTextSearchFiledChanged(text);
                      },
                      onSubmit: (text) {
                        _onTextSearchFiledSubmited(text);
                      },
                      clear: () {},
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Column(
                      children: [
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: <Widget>[
                            NiceButton(
                              width: MediaQuery.of(context).size.width / 3,
                              elevation: 8.0,
                              radius: 52.0,
                              text: "下载",
                              fontSize: 12,
                              background: const Color(0xff000000),
                              onPressed: () {
                                _startDownLoad();
                              },
                            ),
                            NiceButton(
                              width: MediaQuery.of(context).size.width / 3,
                              elevation: 8.0,
                              radius: 52.0,
                              text: "播放",
                              fontSize: 12,
                              background: const Color(0xff000000),
                              onPressed: () {
                                if (_videoLink.isEmpty) {
                                  FlutterToastManage().showToast("请先搜索下载视频~");
                                  return;
                                }
                                _openRoute(page: VideoScreen(url: _videoLink));
                              },
                            ),
                            NiceButton(
                              width: MediaQuery.of(context).size.width / 3,
                              elevation: 8.0,
                              radius: 52.0,
                              fontSize: 12,
                              text: "添加到待下载",
                              background: const Color(0xff000000),
                              onPressed: () {
                                _addVideoToReadyDownload();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const <Widget>[
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            '抖音/皮皮虾/火山/微视/微博/绿洲/最右/轻视频/instagram/哔哩哔哩/快手/全民小视频/皮皮搞笑/全民k歌/巴塞电影/陌陌/Before避风/开眼/Vue Vlog/小咖秀/西瓜视频/逗拍/虎牙/6间房/新片场/Acfun/美拍',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                showLoading ? const LoginLoading() : Container()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
