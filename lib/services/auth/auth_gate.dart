/*
AUTH GATE

Listens to authentication state:
- If user is logged in → go to HomePage
- If not logged in → show LoginOrRegister page
*/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media/pages/home_page.dart';
import 'package:social_media/services/auth/login_or_register.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to auth state changes
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // If user is logged in → go to HomePage
        else if (snapshot.hasData) {
          return const HomePage();
        }
        // User not logged in → show login/register screen
        else {
          return const LoginOrRegister();
        }
      },
    );
  }
}





// /* 

// AUTH GATE 

// This is to check if the user is logged in or not 

// if user is logged in --> go to home page
// if user is not logged in --> go to register page

// */

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:social_media/pages/home_Page.dart';
// import 'package:social_media/services/auth/login_or_register.dart';

// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(), 
//       builder: (context, snapshot){

//         // user logged in
//         if(snapshot.hasData) {
//           return const HomePage();
//         }

//         // user not logged in 
//         else{
//           return const LoginOrRegister();
//         }
//       }),
//     );
//   }
// }