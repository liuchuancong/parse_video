import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class DrawerCommonPage extends StatefulWidget {
  final Widget page;
  const DrawerCommonPage({Key? key, required this.page}) : super(key: key);

  @override
  State<DrawerCommonPage> createState() => _DrawerCommonPageState();
}

class _DrawerCommonPageState extends State<DrawerCommonPage> {
  @override
  Widget build(BuildContext context) {
    return NeumorphicTheme(
        themeMode: ThemeMode.light,
        theme: const NeumorphicThemeData(
          baseColor: Color(0xFFFFFFFF),
          lightSource: LightSource.topLeft,
          depth: 10,
        ),
        darkTheme: neumorphicDefaultDarkTheme.copyWith(
            defaultTextColor: Colors.white70),
        child: widget.page);
  }
}