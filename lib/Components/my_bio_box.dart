import 'package:flutter/material.dart';

//  USER BIO

//  simple bio to view bio on profile

class MyBioBox extends StatelessWidget {

  final String text;

  const MyBioBox({super.key, required this.text});

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    
    // container
    return Container(

      decoration: BoxDecoration(
      // color
        color: Theme.of(context).colorScheme.secondary,

        borderRadius: BorderRadius.circular(8)
        
        ),

      // Paddinh inside
      padding: const EdgeInsets.all(25),

      // Padding outside

      // text
      child: Text(
        text.isNotEmpty ? text : "Empty bio..",
        style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
    );
  }
}