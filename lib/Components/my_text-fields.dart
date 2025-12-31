import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obsecureText;



  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obsecureText,
    
    });

  @override
  Widget build(BuildContext context) {
    return TextField(
        controller: controller,
        obscureText: obsecureText,
        decoration: InputDecoration(

          //unselected 
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary,),
            borderRadius: BorderRadius.circular(12),
          ),

          //selected
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary,),
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor: Theme.of(context).colorScheme.secondary,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary,)
        ),
    );
  }
}