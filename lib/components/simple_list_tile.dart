import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class SimpleListTile extends StatelessWidget {
  const SimpleListTile({Key? key, this.title, this.onTap, this.leading, this.trailing}) : super(key: key);
  final String? title;
  final void Function()? onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            title!,
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