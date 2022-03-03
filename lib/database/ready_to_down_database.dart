import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// 注册时模拟表
class DataBaseReadyDownLoadProvider {
  DataBaseReadyDownLoadProvider._();
  static const table = 'ready_to_down_database';
  static final DataBaseReadyDownLoadProvider db =
      DataBaseReadyDownLoadProvider._();
  static Database? _database;
  Future<Database> get dataBase async {
    if (_database != null) {
      return _database!;
    }
    _database = await initializeDB();
    return _database!;
  }

  initializeDB() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "ready_to_download_list.db");
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
    required String url,
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
    if (list.isEmpty) {
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
  ReadyDownLoad({required this.id, required this.url});

  factory ReadyDownLoad.formMap(Map<String, dynamic> json) => ReadyDownLoad(
        id: json['id'],
        url: json['url'],
      );

  Map<String, dynamic> toMap() => {'id': id, 'url': url};
}
