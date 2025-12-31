/* 

LOADING CIRCLE

*/

// show loading circle

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void showLoadingCircle(BuildContext context) {
  showDialog(context: context, 
              builder: (context) => const AlertDialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                content: Center(child: CircularProgressIndicator(),),
              ));
}

// hide loading circle

void hideLoadingCircle (BuildContext context) {
  Navigator.pop(context);
}