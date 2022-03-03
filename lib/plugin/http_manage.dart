import 'dart:io';
import 'package:dio/dio.dart';
import 'flutter_toast_manage.dart';

class HttpManager {
  final String baseUrl = 'https://tenapi.cn/';
  final int connectTimeOut = 10000;
  final int receiveTimeOut = 10000;

  //单例模式
  static late HttpManager _instance;
  late Dio _dio;
  BaseOptions _options = BaseOptions();
  HttpManager._internal();
  //单例模式，只创建一次实例
  static HttpManager getInstance() {
    _instance = HttpManager._internal();
    return _instance;
  }

  //构造函数
  HttpManager() {
    _options = BaseOptions(
        baseUrl: baseUrl,
        //连接时间为5秒
        connectTimeout: connectTimeOut,
        //响应时间为3秒
        receiveTimeout: receiveTimeOut,
        //设置请求头
        headers: {},
        responseType: ResponseType.json,
        contentType:
            ContentType.parse("application/json;charset=utf-8").toString());
    _dio = Dio(_options);

    //添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      return handler.next(options);
    }, onResponse: (response, handler) {
      return handler.next(response);
    }, onError: (DioError e, handler) {
      return handler.next(e);
    }));
  }

  //get请求方法
  Future<Response?> get(url, {data, options, cancelToken}) async {
    Response? response;
    try {
      response = await _dio.get(url,
          queryParameters: data, options: options, cancelToken: cancelToken);
    } on DioError catch (e) {
      formatError(e);
    }
    return response;
  }

  //post请求
  Future<Response?> post(url, {params, options, cancelToken, data}) async {
    Response? response;
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
  Future<Response?> postForm(url, {data, options, cancelToken}) async {
    Response? response;
    try {
      response = await _dio.post(url,
          options: options, cancelToken: cancelToken, data: data);
    } on DioError catch (e) {
      formatError(e);
    }
    return response;
  }

  //取消请求
  cancleRequests(CancelToken token) {
    token.cancel("cancelled");
  }

  void formatError(DioError e) {
    if (e.type == DioErrorType.connectTimeout) {
      FlutterToastManage().showToast("连接超时");
    } else if (e.type == DioErrorType.sendTimeout) {
      FlutterToastManage().showToast("请求超时");
    } else if (e.type == DioErrorType.receiveTimeout) {
      FlutterToastManage().showToast("响应超时");
    } else if (e.type == DioErrorType.response) {
      FlutterToastManage().showToast("出现异常");
    } else if (e.type == DioErrorType.cancel) {
      FlutterToastManage().showToast("请求取消");
    } else {
      FlutterToastManage().showToast("未知错误");
    }
  }
}
