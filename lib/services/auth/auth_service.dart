/*
AUTHENTICATION SERVICE

Handles everything related to Firebase Authentication:

- Login
- Register
- Logout
- Get current user
*/

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Get instance of FirebaseAuth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user (nullable)
          User? getCurrentuser() => _auth.currentUser;
          // User? get currentUser => _auth.currentUser;

  // Get current user's UID (nullable)
          String getCurrentUid() => _auth.currentUser!.uid;
          // String? get currentUid => _auth.currentUser?.uid;

  // Login using email & password
  Future<UserCredential> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Attempt sign in
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Throw readable message on error
      throw Exception(e.message ?? e.code);
    }
  }

  // Register new user using email & password
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Attempt to register
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Throw readable message on error
      throw Exception(e.message ?? e.code);
    }
  }

  // Logout current user
  Future<void> logout() async {
    await _auth.signOut();
  }
}





// /*

// AUTHENTICATION SERVICE

// This handles everything to do with authentication in firebase


// -Login
// -Register
// -Logout
// -Delete Account 

// */

// import 'package:firebase_auth/firebase_auth.dart';

// class AuthService {

//   // get Instance of the auth
//   final _auth = FirebaseAuth.instance;

//   // get current user and uid
//   User? getCurrentuser() => _auth.currentUser;
//   String getCurrentUid() => _auth.currentUser!.uid;

//   // login --> email & password
//   Future<UserCredential> loginEmailpassword(String email,String password) async {
    
//     // attempt login
//     try{
//       final UserCredential = await _auth.signInWithEmailAndPassword(
//         email: email, 
//         password: password,);

//         return UserCredential;
//     }

//     // catch any error
//     on FirebaseAuthException catch (e) {
//         throw Exception(e.code);
//     }
//   }

//   // register --> email & password
//   Future<UserCredential> registerEmailPassword(String email,String password) async {
//     // attempt to register
//     try{
//        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email, 
//         password: password,);

//         return userCredential;
//     } 
    
//     // catch error 
//     on FirebaseException catch (e) {
//       throw Exception(e.code);
//     }

//   }

//   // logout
//   Future<void> logout() async {
//     await _auth.signOut();
//   }

//   // Delete account 
// }