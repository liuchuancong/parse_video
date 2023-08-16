import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:parse_video/model/current_down_load.dart';
import 'package:provider/provider.dart';

class TaskListTile extends StatefulWidget {
  final DownloadTask movie;
  final void Function()? onPressed;
  final Function refrish;
  const TaskListTile(
      {Key? key,
      required this.movie,
      required this.onPressed,
      required this.refrish})
      : super(key: key);

  @override
  State<TaskListTile> createState() => TaskListTileState();
}

class TaskListTileState extends State<TaskListTile> {
  String fileSize = '';
  @override
  void initState() {
    super.initState();
    getFileSize(widget.movie.status);
  }

  getFileSize(status) {
    if (status == DownloadTaskStatus.complete ||
        status == DownloadTaskStatus.running ||
        status == DownloadTaskStatus.paused) {
      var file = File(widget.movie.savedDir + Platform.pathSeparator + widget.movie.filename!);
      setState(() {
        fileSize = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
      });
    }
  }

  Widget _buildDownLoadStatus() {
    DownloadTaskStatus? status;
    if (widget.movie.taskId ==
        context.watch<CurrentDownLoad>().downLoadAbleItem.id) {
      status = context.watch<CurrentDownLoad>().downLoadAbleItem.status;
      getFileSize(status);
      if (context.watch<CurrentDownLoad>().downLoadAbleItem.progress == 100) {
        widget.refrish();
      }
    } else {
      status = widget.movie.status;
    }
    if (status == DownloadTaskStatus.running) {
      return SizedBox(
        width: 200,
        child: NeumorphicSlider(
          height: 2.0,
          min: 0.0,
          max: 100.0,
          value: widget.movie.taskId ==
                  context.watch<CurrentDownLoad>().downLoadAbleItem.id
              ? context
                  .watch<CurrentDownLoad>()
                  .downLoadAbleItem
                  .progress
                  .toDouble()
              : 0.1,
        ),
      );
    } else if (status == DownloadTaskStatus.canceled) {
      return const Text('下载取消');
    } else if (status == DownloadTaskStatus.complete) {
      return const Text('下载完成');
    } else if (status == DownloadTaskStatus.failed) {
      return const Text('下载失败');
    } else if (status == DownloadTaskStatus.paused) {
      return const Text('下载暂停');
    } else if (status == DownloadTaskStatus.undefined) {
      return const Text('未知错误');
    } else if (status == DownloadTaskStatus.enqueued) {
      return const Text('等待下载');
    } else {
      return Container();
    }
  }

  bool getConditions() {
    bool widgetFlag = false;
    bool downLoadFlag = false;
    DownloadTaskStatus widgetStatus = widget.movie.status;
    DownloadTaskStatus? downLoadStatus =
        context.watch<CurrentDownLoad>().downLoadAbleItem.status;
    if ((widgetStatus == DownloadTaskStatus.complete ||
        widgetStatus == DownloadTaskStatus.running ||
        widgetStatus == DownloadTaskStatus.paused)) {
      widgetFlag = true;
    }
    if (widget.movie.taskId ==
        context.watch<CurrentDownLoad>().downLoadAbleItem.id) {
      if ((downLoadStatus == DownloadTaskStatus.complete ||
          downLoadStatus == DownloadTaskStatus.running ||
          downLoadStatus == DownloadTaskStatus.paused)) {
        downLoadFlag = true;
      }
    }

    return widgetFlag || downLoadFlag;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(6.0),
          child: ListTile(
            title: Text(
              widget.movie.filename!,
              softWrap: false,
            ),
            subtitle: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getConditions()
                    ? Text(
                        '$fileSize MB',
                        softWrap: false,
                      )
                    : Container(),
                _buildDownLoadStatus()
              ],
            ),
            onTap: widget.onPressed,
          ),
        ),
      ],
    );
  }
}

class SimpleListTile extends StatelessWidget {
  final String title;
  final void Function()? onTap;
  final Widget? leading;
  final Widget? trailing;

  const SimpleListTile(
      {Key? key,
      required this.title,
      required this.onTap,
      this.leading,
      this.trailing})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            title,
            style: const TextStyle(fontSize: 16),
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
          leading: leading,
          trailing: trailing,
          onTap: onTap,
        ),
      ],
    );
  }
}
