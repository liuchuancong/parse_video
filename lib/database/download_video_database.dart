import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DataBaseDownLoadListProvider {
  DataBaseDownLoadListProvider._();
  static const table = 'download_video_database';
  static final DataBaseDownLoadListProvider db =
      DataBaseDownLoadListProvider._();
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
    String path = join(databasesPath, "download_play_list.db");
    return await openDatabase(
      path,
      version: 1,
      readOnly: false,
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
    required String taskId,
    required String movieName,
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
        "SELECT * FROM $table WHERE task_id='${fileName.toString()}'");
    List<DwonloadDBInfoMation> list = result.isNotEmpty
        ? result.map((movie) => DwonloadDBInfoMation.formMap(movie)).toList()
        : [];
    if (list.isEmpty) {
      return false;
    }
    return true;
  }
  Future<bool> deleteMovieWithTaskId(String taskId) async {
    var db = await dataBase;
    var result = await db.rawQuery(
        "SELECT * FROM $table WHERE task_id='$taskId'");
    List<DwonloadDBInfoMation> list = result.isNotEmpty ? result.map((movie) => DwonloadDBInfoMation.formMap(movie)).toList() : [];
    if(list.isNotEmpty){
      for (var item in list) {
        int movieId = item.id;
        await deleteMovieWithId(movieId);
      }
      return true;
    }
    return false;
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
  DwonloadDBInfoMation(
      {required this.id, required this.taskId, required this.movieName});

  factory DwonloadDBInfoMation.formMap(Map<String, dynamic> json) =>
      DwonloadDBInfoMation(
        id: json['id'],
        movieName: json['movie_name'],
        taskId: json['task_id'],
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'movie_name': movieName, 'task_id': taskId};
}
