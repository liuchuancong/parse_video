import 'dart:io';
import 'package:android_path_provider/android_path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:parse_video/database/downloadVideoDatabase.dart';
import 'package:permission_handler/permission_handler.dart';

import 'flutterToastManage.dart';

class DownLoadInstance {
  // 单例公开访问点
  factory DownLoadInstance() => _getInstance();
  // 静态私有成员，没有初始化
  static DownLoadInstance _instance;
  static DownLoadInstance get instance => _getInstance();
  // 私有构造函数
  String _localPath;
  DownLoadInstance._internal();

  // 静态、同步、私有访问点
  static DownLoadInstance _getInstance() {
    if (_instance == null) {
      _instance = DownLoadInstance._internal();
    }
    return _instance;
  }

  Future<void> startDownLoad(String url, String fileName) async {
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      fileName: fileName + '.mp4',
      savedDir: _localPath,
      showNotification: false,
      openFileFromNotification: false,
    );
    await DataBaseDownLoadListProvider.db
        .insetDB(taskId: taskId, movieName: fileName + '.mp4');
  }

  // 申请权限
  Future<void> requestPermission() async {
    var status = await Permission.storage.status;
    if (status.isUndetermined) {
      await Permission.storage.request();
    }
  }

  Future<Null> prepare() async {
    await requestPermission();
    String musicPath = await AndroidPathProvider.moviesPath;
    _localPath = musicPath + Platform.pathSeparator + 'Downloads';
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  void showCenterShortToast() {
    FlutterToastManage().showToast("下载失败");
  }

  Future<List<DownloadTask>> loadTasks() async {
    return await FlutterDownloader.loadTasks();
  }

  Future cancel(String taskId) async {
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
