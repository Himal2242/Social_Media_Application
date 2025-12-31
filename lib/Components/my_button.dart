import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  final Widget? child; // <-- added

  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
    this.child, // <-- added
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Padding inside
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          // Color of the button
          color: Theme.of(context).colorScheme.secondary,
          // Curved corners
          borderRadius: BorderRadius.circular(12),
        ),
        // Text or child (spinner)
        child: Center(
          child: child ??
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:flutter/src/cupertino/activity_indicator.dart';

// class MyButton extends StatelessWidget {
//   final String text;
//   final void Function()? onTap;

//   const MyButton({
//     super.key,
//     required this.text,
//     required this.onTap, CupertinoActivityIndicator? child,
//     });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(

//         // Padding inside
//         padding: const EdgeInsets.all(25),

//         decoration: BoxDecoration(

//           // Color of the button 
//           color: Theme.of(context).colorScheme.secondary,
        

//           // Curved corners
//           borderRadius: BorderRadius.circular(12)
//         ),

//         //Text
//         child: Center
//           (child: 
//             Text(
//               text,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//               )),
//       ),
//     );
//   }
// }