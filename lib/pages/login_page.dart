/*
LOGIN PAGE

- Allows user to login with email & password
- Shows error dialogs if login fails
- Shows loading indicator inside the Login button in Cupertino style
*/

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_media/Components/my_button.dart';
import 'package:social_media/Components/my_loading_circle.dart';
import 'package:social_media/Components/my_text-fields.dart';
import 'package:social_media/services/auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  // Callback to toggle to register page
  final VoidCallback onTap;

  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Instance of AuthService
  final AuthService _authService = AuthService();

  // Text controllers for input fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Loading state
  bool isLoading = false;

  // Method to handle login logic
  Future<void> _login() async {
    // Validate fields are not empty
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Attempt login
      await _authService.loginWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // On success: auth gate will handle navigation
    } catch (e) {
      // Show error dialog
      _showErrorDialog(e.toString().replaceAll('Exception:', '').trim());
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Helper to show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // App icon / logo
                  Icon(Icons.lock_open_rounded, size: 72, color: theme.primary),

                  const SizedBox(height: 40),

                  // Welcome message
                  Text('Welcome Back!',
                      style: TextStyle(color: theme.primary, fontSize: 18)),

                  const SizedBox(height: 40),

                  // Email input field
                  MyTextField(
                    controller: emailController,
                    hintText: 'Enter email...',
                    obsecureText: false,
                  ),

                  const SizedBox(height: 12),

                  // Password input field
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Enter password...',
                    obsecureText: true,
                  ),

                  const SizedBox(height: 12),

                  // Forgotten password text
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Forgotten Password?',
                      style: TextStyle(
                          color: theme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Login button: shows spinner inside button when loading
                  MyButton(
                    text: 'Login',
                    onTap: isLoading ? null : _login,
                    child: isLoading
                        ? const CupertinoActivityIndicator(radius: 10)
                        : null,
                  ),

                  const SizedBox(height: 10),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Not a member?', style: TextStyle(color: theme.primary)),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text('Register now',
                            style: TextStyle(
                                color: theme.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}









// /*
// LOGIN PAGE

// - Allows user to login with email & password
// - Shows error dialogs if login fails
// - Shows loading indicator while logging in
// */

// import 'package:flutter/material.dart';
// import 'package:social_media/Components/my_button.dart';
// import 'package:social_media/Components/my_loading_circle.dart';
// import 'package:social_media/Components/my_text-fields.dart';
// import 'package:social_media/services/auth/auth_service.dart';

// class LoginPage extends StatefulWidget {
//   // Callback to toggle to register page
//   final VoidCallback onTap;

//   const LoginPage({super.key, required this.onTap});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   // Instance of AuthService
//   final AuthService _authService = AuthService();

//   // Text controllers for input fields
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   // Loading state
//   bool isLoading = false;

//   // Method to handle login logic
//   Future<void> _login() async {

//     // show loading circle
//     showLoadingCircle(context);

//     // Validate fields are not empty
//     if (emailController.text.isEmpty || passwordController.text.isEmpty) {
//       _showErrorDialog('Please fill in all fields.');
//       return;
//     }

//     setState(() => isLoading = true);

//     try {
//       // Attempt login

//       await _authService.loginWithEmailPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       );

//       // finish loading
//       if (mounted) hideLoadingCircle(context);

//       // On success: auth gate will handle navigation
//     } catch (e) {
//       // Show error dialog
//       _showErrorDialog(e.toString().replaceAll('Exception:', '').trim());
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   // Helper to show error dialog
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Login failed'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context).colorScheme;

//     return Scaffold(
//       backgroundColor: theme.surface,

//       // Body content
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 25),
//           child: Center(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   // App icon / logo
//                   Icon(Icons.lock_open_rounded, size: 72, color: theme.primary),

//                   const SizedBox(height: 40),

//                   // Welcome message
//                   Text('Welcome Back!',
//                       style: TextStyle(color: theme.primary, fontSize: 18)),

//                   const SizedBox(height: 40),

//                   // Email input field
//                   MyTextField(
//                     controller: emailController,
//                     hintText: 'Enter email...',
//                     obsecureText: false,
//                   ),

//                   const SizedBox(height: 12),

//                   // Password input field
//                   MyTextField(
//                     controller: passwordController,
//                     hintText: 'Enter password...',
//                     obsecureText: true,
//                   ),

//                   const SizedBox(height: 12),

//                   // Forgotten password text
//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: Text(
//                       'Forgotten Password?',
//                       style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
//                     ),
//                   ),

//                   const SizedBox(height: 25),

//                  // Login button or loading spinner
                  

//                   /*
//                    isLoading
//                        ? const CircularProgressIndicator()
//                        : MyButton(text: 'Login', onTap: _login),

//                   */     

//                   MyButton(text: 'Login', onTap: _login),

//                   const SizedBox(height: 10),

//                   // Register link
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text('Not a member?', style: TextStyle(color: theme.primary)),
//                       const SizedBox(width: 5),
//                       GestureDetector(
//                         onTap: widget.onTap,
//                         child: Text('Register now',
//                             style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold)),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }







