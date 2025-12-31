import 'package:flutter/material.dart';

final ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Colors.grey.shade500,
  onPrimary: Colors.white,
  secondary: Colors.grey.shade200,
  onSecondary: Colors.black,
  surface: Colors.grey.shade300,
  onSurface: Colors.black,
  error: Colors.red,
  onError: Colors.white,
  tertiary: Colors.white,
  inversePrimary: Colors.grey.shade900,
);

ThemeData lightMode = ThemeData.from(
  colorScheme: lightColorScheme,
).copyWith(
  
);



// import 'package:flutter/material.dart';

// ThemeData lightMode = ThemeData(
//   colorScheme: ColorScheme.light(
//     surface: Colors.grey.shade300,
//     primary: Colors.grey.shade500,
//     secondary: Colors.grey.shade200,
//     tertiary: Colors.white,
//     inversePrimary: Colors.grey.shade900,
//   )
// );

