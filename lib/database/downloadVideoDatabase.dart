import 'dart:async';

import 'dart:io';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// 注册时模拟表
class DataBaseDownLoadListProvider {
  DataBaseDownLoadListProvider._();
  static final table = 'DownLoadPlayList';
  static final DataBaseDownLoadListProvider db =
      DataBaseDownLoadListProvider._();
  Database _database;
  Future<Database> get dataBase async {
    if (_database != null) return _database;
    _database = await initDB();
    return _database;
  }

  initDB() async {
    /// On Android, this returns the AppData directory.
    String musicPath = await AndroidPathProvider.moviesPath;
    String _localPath = musicPath + Platform.pathSeparator + 'DataBase';
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
    String path = join(savedDir.path, "download_play_list.db");
    return await openDatabase(
      path,
      version: 1,
      onOpen: (db) {},
      onCreate: (Database db, int version) async {
        await db.execute(
          "CREATE TABLE $table ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "movie_name VARCHAR ( 256 ),"
          "task_id VARCHAR ( 256 )"
          ")",
        );
      },
    );
  }

  Future insetDB({
    String taskId,
    String movieName,
  }) async {
    Database db = await dataBase;
    await db.insert(table, {
      'movie_name': movieName,
      'task_id': taskId,
    });
  }

  Future<List<DwonloadDBInfoMation>> queryAll() async {
    var db = await dataBase;
    var result = await db.query(table);
    List<DwonloadDBInfoMation> list = result.isNotEmpty
        ? result.map((movie) => DwonloadDBInfoMation.formMap(movie)).toList()
        : [];
    return list;
  }

  Future<bool> queryWithFileName(String fileName) async {
    var db = await dataBase;
    var result = await db.rawQuery(
        "SELECT * FROM $table WHERE movie_name='${fileName.toString()}'");
    List<DwonloadDBInfoMation> list = result.isNotEmpty
        ? result.map((movie) => DwonloadDBInfoMation.formMap(movie)).toList()
        : [];
    if (list.length == 0) {
      return false;
    }
    return true;
  }

  Future deleteMovieWithId(int movieId) async {
    var db = await dataBase;
    await db.rawQuery("DELETE FROM $table WHERE id=$movieId");
  }
}

class DwonloadDBInfoMation {
  int id;
  String taskId;
  String movieName;
  DwonloadDBInfoMation({this.id, this.taskId, this.movieName});

  factory DwonloadDBInfoMation.formMap(Map<String, dynamic> json) =>
      new DwonloadDBInfoMation(
        id: json['id'],
        movieName: json['movie_name'],
        taskId: json['task_id'],
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'movie_name': movieName, 'task_id': taskId};
}
