import 'dart:io';
import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:parse_video/components/bottom_sheet.dart';
import 'package:parse_video/components/drawer_common_page.dart';
import 'package:parse_video/components/loading.dart';
import 'package:parse_video/components/task_list_item.dart';
import 'package:parse_video/database/download_video_database.dart';
import 'package:parse_video/plugin/download.dart';
import 'package:parse_video/plugin/flutter_toast_manage.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
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
  List<Widget> tasksList = [];
  int _selectedIndex = 0;
  bool showLoading = false;
  List<DownloadTask> tasks = [];
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
          Align(
            alignment: Alignment.center,
            child: SizedBox(
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
                    icon: const Icon(
                      Icons.cloud_download,
                      color: Colors.white,
                    ),
                    title: const Text(
                      '下载中',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  FlashyTabBarItem(
                    activeColor: Colors.white,
                    icon: const Icon(
                      Icons.queue_music,
                      color: Colors.white,
                    ),
                    title: const Text(
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
    final urlRegExp = RegExp(
        r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");
    List<String?> urlMatches =
        urlRegExp.allMatches(value).map((m) => m.group(0)).toList();
    return urlMatches.isNotEmpty;
  }


  _startDownLoad(DownloadTask  movie) async {
    String? fileName = movie.filename;
    await DataBaseDownLoadListProvider.db.deleteMovieWithTaskId(movie.taskId);
    await DownLoadInstance().startDownLoad(movie.url, fileName!,fullFileName: true);
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
    tasks = (await FlutterDownloader.loadTasksWithRawQuery(query: query))!;
    List<DownloadTask> taskTemp = [];
    if (tasks.isNotEmpty) {
      for (var i = 0; i < tasks.length; i++) {
        File file = File(
            tasks[i].savedDir + Platform.pathSeparator + tasks[i].filename!);
        bool exits = await file.exists();
        if (exits) {
          taskTemp.add(tasks[i]);
        } else {
          DownLoadInstance().delete(tasks[i].taskId);
        }
      }
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
    } else {
      tasksList = [];
    }

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
              setState(() {});
              DownLoadInstance().cancel(movie.taskId);
            },
          ),
          SimpleListTile(
            title: '暂停下载',
            onTap: () {
              Navigator.pop(context);
              setState(() {});
              DownLoadInstance().pause(movie.taskId);
            },
          ),
          SimpleListTile(
            title: '恢复下载',
            onTap: () {
              Navigator.pop(context);
              setState(() {});
              DownLoadInstance()
                  .resume(movie.taskId)
                  .then((value) => {loadTasks(_selectedIndex)});
            },
          ),
          SimpleListTile(
            title: '重试',
            onTap: () {
              Navigator.pop(context);
              setState(() {});
              DownLoadInstance()
                  .remove(movie.taskId)
                  .then((_) => {_startDownLoad(movie)});
            },
          ),
          SimpleListTile(
            title: '删除',
            onTap: () {
              Navigator.pop(context);
              setState(() {});
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
                      decoration: const BoxDecoration(
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
          showLoading ? const LoginLoading() : Container()
        ],
      ),
    );
  }
}
