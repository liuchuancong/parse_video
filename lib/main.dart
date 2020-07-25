import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:parse_video/components/loading.dart';
import 'package:parse_video/page/downloadPage.dart';
import 'package:parse_video/page/local_video_page.dart';
import 'package:parse_video/page/readyToDown.dart';
import 'package:parse_video/page/video_page.dart';
import 'package:parse_video/plugin/download.dart';
import 'package:parse_video/plugin/flutterToastManage.dart';
import 'package:parse_video/plugin/httpManage.dart';
import 'common/niceButton.dart';
import 'components/taskListItem.dart';
import 'components/textField.dart';
import 'database/downloadVideoDatabase.dart';
import 'database/readyToDownDatabase.dart';
import 'model/currentDownLoad.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  if (Platform.isAndroid) {
    SystemUiOverlayStyle systemUiOverlayStyle =
        SystemUiOverlayStyle(statusBarColor: Colors.black);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => CurrentDownLoad()),
  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return NeumorphicApp(
      debugShowCheckedModeBanner: false,
      title: '无水印视频下载',
      themeMode: ThemeMode.light,
      theme: NeumorphicThemeData(
        baseColor: Color(0xFFFFFFFF),
        lightSource: LightSource.topLeft,
        depth: 10,
      ),
      darkTheme: NeumorphicThemeData(
        baseColor: Color(0xFF3E3E3E),
        lightSource: LightSource.topLeft,
        depth: 6,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String result = '';
  String _videoLink = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();
  ReceivePort _port = ReceivePort();
  DateTime lastPopTime;
  bool showLoading = false;
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

  _portListen() {
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    FlutterDownloader.registerCallback(downloadCallback);
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      context.read<CurrentDownLoad>().setDownLoadAbleItem(
          new DownLoadAbleItem(id: id, progress: progress, status: status));
    });
  }

  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
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
    if (result['code'] == '200') {
      _videoLink = result['url'];
      FlutterToastManage().showToast("已找到视频,您可选择播放或者下载视频");
    } else {
      FlutterToastManage().showToast(result['msg']);
    }
  }

  Future<bool> _onBackPressed() {
    if (_scaffoldKey.currentState.isDrawerOpen) {
      Navigator.of(context).pop();
    }
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0))),
              contentPadding: EdgeInsets.only(top: 10.0),
              title: Text('确定退出程序吗?'),
              actions: <Widget>[
                FlatButton(
                  child: Text('暂不'),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
                FlatButton(
                    child: Text('确定'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    }),
              ],
            ));
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

  _addVideoToReadyDownload() async {
    print(result);
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

  _startDownLoad() async {
    if (_videoLink.isEmpty) {
      FlutterToastManage().showToast("请先搜索下载视频~");
      return;
    }
    var str = result.split('/');
    Iterable<String> urlArr = str.where((item) {
      return item != null && item.isNotEmpty;
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: _onBackPressed, child: _buildScaffold());
  }

  Widget _buildScaffold() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color(0xFF000000),
        actionsIconTheme: NeumorphicTheme.currentTheme(context).iconTheme,
        leading: IconButton(
          icon: new NeumorphicIcon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState.openDrawer();
          },
        ),
        title: NeumorphicText(
          "无水印视频下载",
          style: NeumorphicStyle(
            depth: 4, //customize depth here
            color: Colors.white, //customize color here
          ),
          textStyle: NeumorphicTextStyle(
            fontSize: 18, //customize size here
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/2.png"), fit: BoxFit.cover)),
              accountEmail: Text('17792321552@163.com'),
              accountName: Text('刘传聪'),
            ),
            SimpleListTile(
              title: '待下载列表',
              onTap: () {
                _openRoute(page: new ReadyToDownPage());
              },
            ),
            SimpleListTile(
              title: '本地视频',
              onTap: () {
                _openRoute(page: new LocalVideoPage());
              },
            ),
            SimpleListTile(
              title: '我的下载',
              onTap: () {
                _openRoute(page: new DownLoadPage());
              },
            ),
            SimpleListTile(title: '本产品为个人学习作品,切勿商用', onTap: null),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            children: <Widget>[
              SizedBox(
                height: 20,
              ),
              TextSearchField(
                hint: "请输入视频链接",
                onChanged: (text) {
                  final urlRegex = new RegExp(
                      r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
                  List<String> urls =
                      urlRegex.allMatches(text).map((m) => m.group(0)).toList();
                  result = urls[0];
                },
                onSubmit: (text) {
                  if (lastPopTime == null ||
                      DateTime.now().difference(lastPopTime) >
                          Duration(seconds: 2)) {
                    lastPopTime = DateTime.now();
                    _futureGetLink(text);
                  } else {
                    lastPopTime = DateTime.now();
                  }
                },
                clear: () {
                  result = '';
                  _videoLink = '';
                },
              ),
              SizedBox(
                height: 10,
              ),
              Column(
                children: <Widget>[
                  new Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: <Widget>[
                      NiceButton(
                        width: MediaQuery.of(context).size.width / 4,
                        elevation: 8.0,
                        radius: 52.0,
                        text: "下载",
                        fontSize: 12,
                        background: Color(0xff000000),
                        onPressed: () {
                          _startDownLoad();
                        },
                      ),
                      NiceButton(
                        width: MediaQuery.of(context).size.width / 4,
                        elevation: 8.0,
                        radius: 52.0,
                        text: "播放",
                        fontSize: 12,
                        background: Color(0xff000000),
                        onPressed: () {
                          _openRoute(page: new VideoScreen(url: _videoLink));
                        },
                      ),
                      NiceButton(
                        width: MediaQuery.of(context).size.width / 4,
                        elevation: 8.0,
                        radius: 52.0,
                        fontSize: 12,
                        text: "添加到待下载",
                        background: Color(0xff000000),
                        onPressed: () {
                          _addVideoToReadyDownload();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                    ),
                    new Container(
                      child: Text(
                        '短视频去水印下载，支持 抖音、Tiktok、快手、火山小视频、皮皮虾',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    new Container(
                      child: Text(
                        '使用方法:复制视频链接,选择粘贴,然后点击搜索,待搜索完成后您可播放或者下载视频到您的手机。也可将复制的链接添加到待下载列表,wifi情况下下载。',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          showLoading ? LoginLoading() : Container()
        ],
      ),
    );
  }
}
