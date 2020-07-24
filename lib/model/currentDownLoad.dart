import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class CurrentDownLoad with ChangeNotifier {
  DownLoadAbleItem _downLoadAbleItem = new DownLoadAbleItem();
  DownLoadAbleItem get downLoadAbleItem => _downLoadAbleItem;
  void setDownLoadAbleItem(DownLoadAbleItem downLoadAbleItem) {
    this._downLoadAbleItem = downLoadAbleItem;
    notifyListeners();
  }
}

class DownLoadAbleItem {
  final int progress;
  final String id;
  final DownloadTaskStatus status;
  DownLoadAbleItem({this.progress = 0, this.id, this.status});
}
