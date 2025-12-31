import 'package:flutter/material.dart';

/* 


*/

class MySettingsTile extends StatelessWidget {
  final String title;
  final Widget action;

  const MySettingsTile({
    super.key,
    required this.title,
    required this.action, required Null Function() onTap,
    
    });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(

        // color
        color: Theme.of(context).colorScheme.secondary,

        // Curve Corners
        borderRadius: BorderRadius.circular(12)

      ),

      // padding outside
      margin: const EdgeInsets.only(left: 25, right: 25, top: 10),

      // padding inside
      padding: const EdgeInsets.all(25),

      // row
      
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // title
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            ),

          //action
          action,
        ],
      ),
    );
  }
}