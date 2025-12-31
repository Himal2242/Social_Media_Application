import 'package:flutter/material.dart';

final ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: const Color.fromARGB(255, 105, 105, 105),
  onPrimary: const Color.fromARGB(255, 230, 230, 230),
  secondary: const Color.fromARGB(255, 30, 30, 30),
  onSecondary: Colors.white,
  surface: const Color.fromARGB(255, 0, 0, 0),
  onSurface: const Color.fromARGB(255, 86, 86, 86),
  error: const Color.fromARGB(255, 245, 245, 245),
  onError: Colors.black,
  tertiary: const Color.fromARGB(255, 47, 47, 47),
  inversePrimary: Colors.grey.shade900,
);

ThemeData darkMode = ThemeData.from(
  colorScheme: darkColorScheme,
).copyWith(
  
);



// import 'package:flutter/material.dart';

// ThemeData darkMode = ThemeData(
//   colorScheme: ColorScheme.light(
//     surface: const Color.fromARGB(255, 20, 20, 20),
//     primary: const Color.fromARGB(255, 105, 105, 105),
//     secondary: const Color.fromARGB(255, 30, 30, 30),
//     tertiary: const Color.fromARGB(255, 47, 47, 47),
//     inversePrimary: Colors.grey.shade900,
//   )
// );

