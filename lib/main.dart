import 'dart:io';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:parse_video/page/home_page.dart';
import 'package:parse_video/model/current_down_load.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: false);
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.dark, // Android：图标黑色
    ));
  }
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => CurrentDownLoad()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // 重复设置一次，防止被页面局部样式覆盖
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.dark, // Android：图标黑色
      ),
      child: const NeumorphicApp(
        debugShowCheckedModeBanner: false,
        title: '去水印视频下载',
        themeMode: ThemeMode.light,
        theme: NeumorphicThemeData(
          baseColor: Color(0xFFFFFFFF),
          lightSource: LightSource.topLeft,
          depth: 10,
        ),
        darkTheme: NeumorphicThemeData(
          baseColor: Color(0xFF3E3E3E),
          lightSource: LightSource.topLeft,
          depth: 6,
        ),
        home: HomePage(),
      ),
    );
  }
}
