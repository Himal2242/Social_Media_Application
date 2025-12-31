/*

COMMENT MODEL

This is what every comment model should have

 */

import 'package:cloud_firestore/cloud_firestore.dart';

/// Comment model representing a comment on a post
class Comment {
  final String id;                 // Unique ID of the comment (Firestore doc ID)
  final String postId;             // ID of the post this comment belongs to
  final String uid;                // User ID of the commenter
  final String name;               // Name of the commenter
  final String username;           // Username of the commenter
  final String message;            // The comment text
  final Timestamp timestamp;       // When the comment was created
  final int commentLikeCount;      // Number of likes on this comment
  final List<String> likedBy;      // List of userIds who liked this comment
  final int commentReplyCount;     // Number of replies to this comment
  final bool isPinned;             // Whether the comment is pinned by the post owner

  Comment({
    required this.id,
    required this.postId,
    required this.uid,
    required this.name,
    required this.username,
    required this.message,
    required this.timestamp,
    this.commentLikeCount = 0,
    List<String>? likedBy,
    this.commentReplyCount = 0,
    this.isPinned = false,            // Default to false
  }) : likedBy = likedBy ?? [];

  /// Create a Comment from Firestore document snapshot
  factory Comment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      postId: data['postId'] ?? '',
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      commentLikeCount: data['commentLikeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentReplyCount: data['commentReplyCount'] ?? 0,
      isPinned: data['isPinned'] ?? false,  // Read pin status from Firestore
    );
  }

  /// Convert Comment to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'uid': uid,
      'name': name,
      'username': username,
      'message': message,
      'timestamp': timestamp,
      'commentLikeCount': commentLikeCount,
      'likedBy': likedBy,
      'commentReplyCount': commentReplyCount,
      'isPinned': isPinned,          // Include pin status when saving
    };
  }
}



// import 'package:cloud_firestore/cloud_firestore.dart';

// /// Comment model representing a comment on a post
// class Comment {
//   final String id;                 // Unique ID of the comment (Firestore doc ID)
//   final String postId;             // ID of the post this comment belongs to
//   final String uid;                // User ID of the commenter
//   final String name;               // Name of the commenter
//   final String username;           // Username of the commenter
//   final String message;            // The comment text
//   final Timestamp timestamp;       // When the comment was created
//   final int commentLikeCount;      // Number of likes on this comment
//   final List<String> likedBy;      // List of userIds who liked this comment
//   final int commentReplyCount;     // Number of replies to this comment

//   Comment({
//     required this.id,
//     required this.postId,
//     required this.uid,
//     required this.name,
//     required this.username,
//     required this.message,
//     required this.timestamp,
//     this.commentLikeCount = 0,
//     List<String>? likedBy,
//     this.commentReplyCount = 0,
//   }) : likedBy = likedBy ?? [];

//   /// Create a Comment from Firestore document snapshot
//   factory Comment.fromDocument(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return Comment(
//       id: doc.id,
//       postId: data['postId'] ?? '',
//       uid: data['uid'] ?? '',
//       name: data['name'] ?? '',
//       username: data['username'] ?? '',
//       message: data['message'] ?? '',
//       timestamp: data['timestamp'] ?? Timestamp.now(),
//       commentLikeCount: data['commentLikeCount'] ?? 0,
//       likedBy: List<String>.from(data['likedBy'] ?? []),
//       commentReplyCount: data['commentReplyCount'] ?? 0,
//     );
//   }

//   /// Convert Comment to map for Firestore storage
//   Map<String, dynamic> toMap() {
//     return {
//       'postId': postId,
//       'uid': uid,
//       'name': name,
//       'username': username,
//       'message': message,
//       'timestamp': timestamp,
//       'commentLikeCount': commentLikeCount,
//       'likedBy': likedBy,
//       'commentReplyCount': commentReplyCount,
//     };
//   }
// }




