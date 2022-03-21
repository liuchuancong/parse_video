import 'dart:io';
import 'package:android_path_provider/android_path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:parse_video/database/download_video_database.dart';
import 'package:parse_video/plugin/flutter_toast_manage.dart';
import 'package:permission_handler/permission_handler.dart';

class DownLoadInstance {
  // 单例公开访问点
  factory DownLoadInstance() => _getInstance();
  // 静态私有成员，没有初始化
  static late DownLoadInstance _instance;
  static DownLoadInstance get instance => _getInstance();
  // 私有构造函数
  DownLoadInstance._internal();

  // 静态、同步、私有访问点
  static DownLoadInstance _getInstance() {
    _instance = DownLoadInstance._internal();
    return _instance;
  }

  Future<void> startDownLoad(String url, String fileName,{bool fullFileName = false}) async {
    final downloadPath = await prepare();
    FlutterToastManage().showToast("正在下载");
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      fileName: !fullFileName ? fileName + '.mp4' : fileName,
      savedDir: downloadPath,
      showNotification: true,
      openFileFromNotification: true,
    );
    await DataBaseDownLoadListProvider.db.insetDB(taskId: taskId ?? '', movieName: !fullFileName ? fileName + '.mp4' : fileName);
  }

  // 申请权限
  Future<void> requestPermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      await Permission.storage.request();
    }
  }

  Future<String> prepare() async {
    await requestPermission();
    String moviesPath = await AndroidPathProvider.moviesPath;
    String localPath = moviesPath + Platform.pathSeparator + 'Downloads';
    final savedDir = Directory(localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
    return savedDir.path;
  }

  void showCenterShortToast() {
    FlutterToastManage().showToast("下载失败");
  }

  Future<List<DownloadTask>?> loadTasks() async {
    return await FlutterDownloader.loadTasks();
  }

  Future cancel(String taskId) async {
     await DataBaseDownLoadListProvider.db.deleteMovieWithTaskId(taskId);
    FlutterDownloader.cancel(taskId: taskId);
  }

  Future pause(String taskId) async {
    FlutterDownloader.pause(taskId: taskId);
  }

  Future resume(String taskId) async {
    FlutterDownloader.resume(taskId: taskId);
  }

  Future retry(String taskId) async {
    FlutterDownloader.retry(taskId: taskId);
  }

  Future remove(String taskId) async {
    FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: false);
  }

  Future delete(String taskId) async {
    FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }

  Future cancelAll(String taskId) async {
    FlutterDownloader.cancelAll();
  }
}
