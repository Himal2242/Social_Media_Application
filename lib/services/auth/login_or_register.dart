/*
LOGIN OR REGISTER PAGE

Toggles between LoginPage and RegisterPage
*/

import 'package:flutter/material.dart';
import 'package:social_media/pages/login_page.dart';
import 'package:social_media/pages/register_page.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  // Initially show login page
  bool showLoginPage = true;

  // Toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Conditionally render login or register page
    return showLoginPage
        ? LoginPage(onTap: togglePages)
        : RegisterPage(onTap: togglePages);
  }
}




// import 'package:flutter/material.dart';
// import 'package:social_media/pages/login_page.dart';
// import 'package:social_media/pages/register_page.dart';

//     /*

//     Login or Register page
    
//     This page shows wheher to show login page or register page
//     */


// class LoginOrRegister extends StatefulWidget {
//   const LoginOrRegister({super.key});

//   @override
//   State<LoginOrRegister> createState() => _LoginOrRegisterState();
// }

// class _LoginOrRegisterState extends State<LoginOrRegister> {


// // initially show login page 
// bool showLoginPage = true;

// // toggle between login and register page
// void togglePages(){
//     setState(() {
//       showLoginPage = !showLoginPage;
//     });
// }


//   @override
//   Widget build(BuildContext context) {
//     if(showLoginPage){
//         return LoginPage(
//             onTap: togglePages,
//         );
//     } else {
//         return RegisterPage(
//             onTap: togglePages,
//         );
//     }
//   }
// }