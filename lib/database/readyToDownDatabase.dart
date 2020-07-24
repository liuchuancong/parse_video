import 'dart:async';

import 'dart:io';

import 'package:android_path_provider/android_path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// 注册时模拟表
class DataBaseReadyDownLoadProvider {
  DataBaseReadyDownLoadProvider._();
  static final table = 'ReadyToDownLoadList';
  static final DataBaseReadyDownLoadProvider db =
      DataBaseReadyDownLoadProvider._();
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
    String path = join(savedDir.path, "ready_to_download_list.db");
    return await openDatabase(
      path,
      version: 1,
      onOpen: (db) {},
      onCreate: (Database db, int version) async {
        await db.execute(
          "CREATE TABLE $table ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "url VARCHAR ( 256 )"
          ")",
        );
      },
    );
  }

  Future insetDB({
    String url,
  }) async {
    Database db = await dataBase;
    await db.insert(table, {
      'url': url,
    });
  }

  Future<List<ReadyDownLoad>> queryAll() async {
    var db = await dataBase;
    var result = await db.query(table);
    List<ReadyDownLoad> list = result.isNotEmpty
        ? result.map((movie) => ReadyDownLoad.formMap(movie)).toList()
        : [];
    return list;
  }

  Future<bool> queryWithUrl(String url) async {
    var db = await dataBase;
    var result =
        await db.rawQuery("SELECT * FROM $table WHERE url='${url.toString()}'");
    List<ReadyDownLoad> list = result.isNotEmpty
        ? result.map((movie) => ReadyDownLoad.formMap(movie)).toList()
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

class ReadyDownLoad {
  int id;
  String url;
  ReadyDownLoad({this.id, this.url});

  factory ReadyDownLoad.formMap(Map<String, dynamic> json) => new ReadyDownLoad(
        id: json['id'],
        url: json['url'],
      );

  Map<String, dynamic> toMap() => {'id': id, 'url': url};
}
