/*
POST MODEL

This defines the structure of every Post in the app
*/

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;            // Firestore doc ID
  final String uid;           // User ID of the post owner
  final String name;          // Display name
  final String username;      // Unique username
  final String message;       // Post content
  final Timestamp timestamp;  // When the post was created
  final int likeCount;        // Number of likes
  final List<String> likedBy; // List of user UIDs who liked

  Post({
    required this.id,
    required this.uid,
    required this.name,
    required this.username,
    required this.message,
    required this.timestamp,
    required this.likeCount,
    required this.likedBy,
  });

  // Create Post object from Firestore document
  factory Post.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Post(
      id: doc.id,
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp']
          : Timestamp.now(), // fallback to now if missing
      likeCount: data['likeCount'] ?? 0, // Make sure Firestore has this field
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  // Convert Post object to Firestore-friendly map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'message': message,
      'timestamp': timestamp,
      'likeCount': likeCount,
      'likedBy': likedBy,
    };
  }
}







// /*

// POST MODEL

// This is what every post should have

//  */
// import 'package:cloud_firestore/cloud_firestore.dart';

// class Post {
//   final String id;           // ID of the post
//   final String uid;          // User ID of the post author
//   final String name;         // Name of the post author
//   final String username;     // Username of the post author
//   final String message;      // Message content of the post
//   final Timestamp timestamp;    // Timestamp of the post
//   final int likeCount;       // Like count of this post
//   final List<String> likedBy; // List of user IDs who liked this post

//   Post({
//     required this.id,
//     required this.uid,
//     required this.name,
//     required this.username,
//     required this.message,
//     required this.timestamp,
//     required this.likeCount,
//     required this.likedBy,
//   });

//   // Convert a Firestore document to a post object (to use in our app).
//   factory Post.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return Post(
//       id: doc.id,
//       uid: data['uid'] ?? '',
//       name: data['name'] ?? '',
//       username: data['username'] ?? '',
//       message: data['message'] ?? '',
//       timestamp: data['timestamp'] ?? '',
//       likeCount: data['likes'] ?? 0,
//       likedBy: List<String>.from(data['likedBy'] ?? []),
//     );
//   }

//   // Convert a Post object to a map (to store in firebase).
//   Map<String, dynamic> toMap() {
//     return {
//       'uid' : uid,
//       'name' : name,
//       'username' : username,
//       'message' : message,
//       'timestamp': timestamp,
//       'likes' : likeCount,
//       'likedBy' : likedBy,
//     };
//   }

  
// }
