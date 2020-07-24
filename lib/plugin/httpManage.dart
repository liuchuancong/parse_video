import 'dart:io';
import 'package:dio/dio.dart';
import 'flutterToastManage.dart';

class HttpManager {
  //一个人工智能回答的免费API
  final String baseUrl = 'https://tenapi.cn/';
  final int connectTimeOut = 10000;
  final int receiveTimeOut = 10000;

  //单例模式
  static HttpManager _instance;
  Dio _dio;
  BaseOptions _options;
  HttpManager._internal();
  //单例模式，只创建一次实例
  static HttpManager getInstance() {
    _instance = HttpManager._internal();
    return _instance;
  }
  //构造函数
  HttpManager() {
    _options = new BaseOptions(
        baseUrl: baseUrl,
        //连接时间为5秒
        connectTimeout: connectTimeOut,
        //响应时间为3秒
        receiveTimeout: receiveTimeOut,
        //设置请求头
        headers: {},
        //默认值是"application/json; charset=utf-8",Headers.formUrlEncodedContentType会自动编码请求体.
        //共有三种方式json,bytes(响应字节),stream（响应流）,plain
        responseType: ResponseType.json,
        contentType:
            ContentType.parse("application/json;charset=utf-8").toString());
    _dio = new Dio(_options);

    //添加拦截器
    _dio.interceptors
        .add(InterceptorsWrapper(onRequest: (RequestOptions options) {
      return options;
    }, onResponse: (Response response) {
      return response;
    }, onError: (DioError e) {
      return e;
    }));
  }

  //get请求方法
  get(url, {data, options, cancelToken}) async {
    Response response;
    try {
      response = await _dio.get(url,
          queryParameters: data, options: options, cancelToken: cancelToken);
    } on DioError catch (e) {
      print('getHttp exception: $e');
      formatError(e);
    }
    return response;
  }

  //post请求
  post(url, {params, options, cancelToken, data}) async {
    Response response;
    try {
      response = await _dio.post(
        url,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken,
        data: data,
      );
    } on DioError catch (e) {
      formatError(e);
    }
    return response;
  }

  //post Form请求
  postForm(url, {data, options, cancelToken}) async {
    Response response;
    try {
      response = await _dio.post(url,
          options: options, cancelToken: cancelToken, data: data);
    } on DioError catch (e) {
      formatError(e);
    }
    return response;
  }

  //下载文件
  downLoadFile(urlPath, savePath) async {
    Response response;
    try {
      response = await _dio.download(urlPath, savePath,
          onReceiveProgress: (int count, int total) {
        print('$count $total');
      });
      print('downLoadFile response: $response');
    } on DioError catch (e) {
      print('downLoadFile exception: $e');
      formatError(e);
    }
    return response;
  }

  //取消请求
  cancleRequests(CancelToken token) {
    token.cancel("cancelled");
  }

  void formatError(DioError e) {
    if (e.type == DioErrorType.CONNECT_TIMEOUT) {
      FlutterToastManage().showToast("连接超时");
    } else if (e.type == DioErrorType.SEND_TIMEOUT) {
      FlutterToastManage().showToast("请求超时");
    } else if (e.type == DioErrorType.RECEIVE_TIMEOUT) {
      FlutterToastManage().showToast("响应超时");
    } else if (e.type == DioErrorType.RESPONSE) {
      FlutterToastManage().showToast("出现异常");
    } else if (e.type == DioErrorType.CANCEL) {
      FlutterToastManage().showToast("请求取消");
    } else {
      FlutterToastManage().showToast("未知错误");
    }
  }
}
