// navigate_page.dart
// This file contains helper functions to navigate between key pages in the app.

import 'package:flutter/material.dart';
import 'package:social_media/models/post.dart';
import 'package:social_media/pages/Profile_page.dart';
import 'package:social_media/pages/post_page.dart';

/// Navigates to a user's profile page.
///
/// [context] - The current BuildContext from which navigation is initiated.
/// [uid] - The user ID of the profile to view.
void goUserPage(BuildContext context, String uid) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProfilePage(uid: uid),
    ),
  );
}

/// Navigates to a single post detail page.
///
/// [context] - The current BuildContext from which navigation is initiated.
/// [post] - The post object to display in detail.
void goPostPage(BuildContext context, Post post) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PostPage(post: post),
    ),
  );
}



// // GO TO USER PAGE

// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:social_media/models/post.dart';
// import 'package:social_media/pages/Profile_page.dart';
// import 'package:social_media/pages/post_page.dart';

// void goUserPage(BuildContext context, String uid) {
  
//   // Navigate to the page

//   Navigator.push(
//     context, 
//     MaterialPageRoute(builder: (context) => ProfilePage(uid: uid))); 
// }

// // Navigate to post page
//   void goPostPage(BuildContext context, Post post) {
//     // navigate to post page
//     Navigator.push(
//       context, 
//       MaterialPageRoute(builder: (context) => PostPage(post: post,)
//       ),
//       );
//   }