import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_media/Components/my_button.dart';
import 'package:social_media/Components/my_text-fields.dart';
import 'package:social_media/services/auth/auth_service.dart';
import 'package:social_media/services/database/database_service.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  // access auth & service
  final _auth = AuthService();
  final _db = DatabaseService();

  // Text controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  // Instance of AuthService
  final AuthService _authService = AuthService();

  // Loading state
  bool isLoading = false;

  // Method to handle registration logic
  Future<void> _register() async {
    // Validate fields first
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        pwController.text.isEmpty ||
        confirmPwController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    if (pwController.text != confirmPwController.text) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Call register method from AuthService
      await _authService.registerWithEmailPassword(
        email: emailController.text.trim(),
        password: pwController.text.trim(),
      );

      // On success, your auth gate should handle navigation automatically
    
      // once register, create and save user profile in database.
      await _db.saveUserInfoFirebase(name: nameController.text, email: emailController.text);
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll('Exception:', '').trim());
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registration failed'),
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
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),

                  // App icon / logo
                  Icon(
                    Icons.lock_open_rounded,
                    size: 72,
                    color: theme.primary,
                  ),

                  const SizedBox(height: 40),

                  // Welcome text
                  Text(
                    "Let's create an account for you!",
                    style: TextStyle(color: theme.primary, fontSize: 16),
                  ),

                  const SizedBox(height: 40),

                  // Name input
                  MyTextField(
                    controller: nameController,
                    hintText: "Enter name...",
                    obsecureText: false,
                  ),

                  const SizedBox(height: 12),

                  // Email input
                  MyTextField(
                    controller: emailController,
                    hintText: "Enter email...",
                    obsecureText: false,
                  ),

                  const SizedBox(height: 12),

                  // Password input
                  MyTextField(
                    controller: pwController,
                    hintText: "Enter password...",
                    obsecureText: true,
                  ),

                  const SizedBox(height: 12),

                  // Confirm password input
                  MyTextField(
                    controller: confirmPwController,
                    hintText: "Confirm password...",
                    obsecureText: true,
                  ),

                  const SizedBox(height: 25),

                  // Register button: show loading spinner inside when loading
                  MyButton(
                    text: "Register",
                    onTap: isLoading ? null : _register,
                    child: isLoading
                        ? const CupertinoActivityIndicator(radius: 12)
                        : null,
                  ),

                  const SizedBox(height: 10),

                  // Already a member? Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already a member?", style: TextStyle(color: theme.primary)),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(
                          "Login now",
                          style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
                        ),
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














// import 'package:flutter/material.dart';
// import 'package:social_media/Components/my_button.dart';
// import 'package:social_media/Components/my_text-fields.dart';

// class RegisterPage extends StatefulWidget {

//   final void Function()? onTap;

//   const RegisterPage({super.key, required this.onTap});

//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
//   // text controllers
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController pwController = TextEditingController();
//   final TextEditingController confirmPwController = TextEditingController();


//   @override
//   Widget build(BuildContext context) {
//     return  Scaffold(
//       backgroundColor: Theme.of(context).colorScheme.surface,
   

//       //BODY
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 25.0),
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
          
//                 SizedBox(height: 50,),
            
//                 // logo
//                 Icon(
//                   Icons.lock_open_rounded,
//                   size: 72,
//                   color: Theme.of(context).colorScheme.primary,
//                   ),
          
//                   SizedBox(height: 50), 
            
//                 // Create an Account
          
//                 Text("Lets Create an Account for You!", 
//                  style: TextStyle(
//                   color: Theme.of(context).colorScheme.primary,
//                   fontSize: 16,
//                   ),
//                 ),
            
//                   SizedBox(height: 50), 
          
//                 // name
//                 MyTextField(
//                   controller: nameController, 
//                   hintText: "Enter Name...", 
//                   obsecureText: false),
          
//                   SizedBox(height: 10), 
          

//                 // email
//                 MyTextField(
//                   controller: emailController, 
//                   hintText: "Enter Email...", 
//                   obsecureText: false),
          
//                   SizedBox(height: 10), 
          
          
//                 // password
//                 MyTextField(
//                   controller: pwController, 
//                   hintText: "Enter password...", 
//                   obsecureText: true),

//                   SizedBox(height: 10), 


//                 // confirm password
//                 MyTextField(
//                   controller: confirmPwController, 
//                   hintText: "Confirm password...", 
//                   obsecureText: true),

//                   SizedBox(height: 10),   

            
//                 // sign up button 
//                 MyButton(text: "Register", onTap: (){}),
//                 SizedBox(height: 10),
                
//                 // Alredy a member? Login
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
                    
//                     Text("Alredy a member?", style: TextStyle(color: Theme.of(context).colorScheme.primary),),
                    
//                     const SizedBox(width: 5,),
                    
//                     GestureDetector(
//                       onTap: widget.onTap,
//                       child: Text("Login now",style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
//                   ],
//                 ), 

            
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }