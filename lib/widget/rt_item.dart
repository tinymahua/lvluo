import 'package:flutter/material.dart';

class RtItem extends StatelessWidget {
  const RtItem(
      {super.key,
      required this.itemIcon,
      required this.labelText,
      this.infoText,
      this.infoContent});

  final Widget itemIcon;
  final String labelText;
  final String? infoText;
  final Widget? infoContent;

  get infoWidget {
    if (infoText != null) {
      return Text(
        infoText!,
        style: const TextStyle(
            decoration: TextDecoration.none,
            height: 1.2,
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w300),
      );
    }
    if (infoContent != null) {
      return infoContent;
    }
    throw Exception("infoText or infoContent must provider one");
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3, left: 3, right: 2),
          child: itemIcon,
          // child: Icon(
          //   Icons.arrow_upward,
          //   size: 12,
          // )
        ),
        // SizedBox(width: 5,),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: infoWidget,
        )
      ],
    );
  }
}
