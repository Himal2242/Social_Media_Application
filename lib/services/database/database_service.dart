import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media/models/comment.dart';
import 'package:social_media/models/post.dart';
import 'package:social_media/models/user.dart';

/// DatabaseService handles all direct communication with Firebase Firestore.
/// It provides CRUD operations and streams for:
/// - User Profiles
/// - Posts (create, delete, like/unlike)
/// - Comments (add, delete, like/unlike, pin/unpin)
/// - Comment Replies (add, delete, like/unlike)
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========================= USER PROFILE =========================

  /// Save a new user's profile info to Firestore under "Users" collection.
  Future<void> saveUserInfoFirebase({
    required String name,
    required String email,
  }) async {
    final String uid = _auth.currentUser!.uid;
    final String username = email.split('@')[0];

    UserProfile user = UserProfile(
      uid: uid,
      name: name,
      email: email,
      username: username,
      bio: '',
    );

    await _db.collection("Users").doc(uid).set(user.toMap());
  }

  /// Fetch user profile document by UID.
  Future<UserProfile?> getUserFromFirebase(String uid) async {
    try {
      final doc = await _db.collection("Users").doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromDocument(doc);
    } catch (e) {
      print("Error fetching user profile: $e");
      return null;
    }
  }

  /// Update current user's bio field.
  Future<void> updateUserBioInFirebase(String bio) async {
    final uid = _auth.currentUser!.uid;
    try {
      await _db.collection("Users").doc(uid).update({'bio': bio});
    } catch (e) {
      print("Error updating user bio: $e");
    }
  }

  // ========================= POSTS =========================

  /// Create a new post with message, current user info, and timestamp.
  Future<void> postMessageInFirebase(String message) async {
    try {
      final uid = _auth.currentUser!.uid;
      final user = await getUserFromFirebase(uid);
      if (user == null) throw Exception("User not found");

      Post newPost = Post(
        id: '', // Firestore will generate
        uid: uid,
        name: user.name,
        username: user.username,
        message: message,
        timestamp: Timestamp.now(),
        likeCount: 0,
        likedBy: [],
      );

      await _db.collection("Posts").add(newPost.toMap());
    } catch (e) {
      print("Error posting message: $e");
    }
  }

  /// Delete post by document ID.
  Future<void> deletePostFromFirebase(String postId) async {
    try {
      await _db.collection("Posts").doc(postId).delete();
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  /// Get all posts ordered by timestamp descending.
  Future<List<Post>> getAllPostsFromFirebase() async {
    try {
      final snapshot = await _db
          .collection("Posts")
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
  }

  /// Like or unlike a post by toggling userId in likedBy array atomically.
  /// Uses Firestore transaction to ensure atomicity.
  Future<void> toggleLikeInFirebase(String postId, String userId) async {
    final postDoc = _db.collection("Posts").doc(postId);
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(postDoc);
        if (!snapshot.exists) throw Exception("Post not found");

        // Get current likedBy list or empty
        List<String> likedBy =
            List<String>.from(snapshot.get('likedBy') ?? []);

        // Get current likeCount or zero
        int likeCount = snapshot.get('likeCount') ?? 0;

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          likeCount = (likeCount > 0) ? likeCount - 1 : 0;
        } else {
          likedBy.add(userId);
          likeCount += 1;
        }

        // Update post document atomically
        transaction.update(postDoc, {
          'likedBy': likedBy,
          'likeCount': likeCount, // Updated field name for consistency
        });
      });
    } catch (e) {
      print("Error toggling like on post: $e");
    }
  }

  // ========================= COMMENTS =========================

  /// Add a comment to a post.
  Future<void> addCommentInFirebase(String postId, String message) async {
    try {
      final uid = _auth.currentUser!.uid;
      final user = await getUserFromFirebase(uid);
      if (user == null) throw Exception("User not found");

      Comment newComment = Comment(
        id: '',
        postId: postId,
        uid: uid,
        name: user.name,
        username: user.username,
        message: message,
        timestamp: Timestamp.now(),
        commentLikeCount: 0,
        likedBy: [],
        commentReplyCount: 0,
        isPinned: false,
      );

      await _db.collection("Comments").add(newComment.toMap());
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  /// Delete a comment by ID.
  Future<void> deleteCommentInFirebase(String commentId) async {
    try {
      await _db.collection("Comments").doc(commentId).delete();
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }

  /// Fetch comments for a post, pinned first then by timestamp descending.
  Future<List<Comment>> getCommentsFromFirebase(String postId) async {
    try {
      final snapshot = await _db
          .collection("Comments")
          .where("postId", isEqualTo: postId)
          .orderBy("isPinned", descending: true)
          .orderBy("timestamp", descending: true)
          .get();

      return snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
    } catch (e) {
      print("Error fetching comments: $e");
      return [];
    }
  }

  /// Update likes count and likedBy array on a comment.
  Future<void> updateCommentLikesInFirebase(
      String commentId, int likeCount, List<String> likedBy) async {
    try {
      await _db.collection("Comments").doc(commentId).update({
        'commentLikeCount': likeCount,
        'likedBy': likedBy,
      });
    } catch (e) {
      print("Error updating comment likes: $e");
    }
  }

  // ========================= COMMENT REPLIES =========================

  /// Add a reply to a comment (subcollection "CommentReply").
  Future<void> addCommentReplyInFirebase(String commentId, String message) async {
    try {
      final uid = _auth.currentUser!.uid;
      final user = await getUserFromFirebase(uid);
      if (user == null) throw Exception("User not found");

      final replyData = {
        'commentId': commentId,
        'uid': uid,
        'name': user.name,
        'username': user.username,
        'message': message,
        'timestamp': Timestamp.now(),
        'commentLikeCount': 0,
        'likedBy': [],
      };

      await _db
          .collection("Comments")
          .doc(commentId)
          .collection("CommentReply")
          .add(replyData);
    } catch (e) {
      print("Error adding comment reply: $e");
    }
  }

  /// Fetch replies for a comment, ordered by timestamp descending.
  Future<List<Comment>> getCommentRepliesFromFirebase(String commentId) async {
    try {
      final snapshot = await _db
          .collection("Comments")
          .doc(commentId)
          .collection("CommentReply")
          .orderBy("timestamp", descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Comment(
          id: doc.id,
          postId: commentId, // parent comment id stored as postId here for reply
          uid: data['uid'] ?? '',
          name: data['name'] ?? '',
          username: data['username'] ?? '',
          message: data['message'] ?? '',
          timestamp: data['timestamp'] ?? Timestamp.now(),
          commentLikeCount: data['commentLikeCount'] ?? 0,
          likedBy: List<String>.from(data['likedBy'] ?? []),
          commentReplyCount: 0,
          isPinned: false,
        );
      }).toList();
    } catch (e) {
      print("Error fetching comment replies: $e");
      return [];
    }
  }

  /// Delete a reply inside a comment subcollection.
  Future<void> deleteCommentReplyInFirebase(String commentId, String replyId) async {
    try {
      await _db
          .collection("Comments")
          .doc(commentId)
          .collection("CommentReply")
          .doc(replyId)
          .delete();
    } catch (e) {
      print("Error deleting comment reply: $e");
    }
  }

  /// Update likes on a comment reply.
  Future<void> updateCommentReplyLikesInFirebase(
      String commentId, String replyId, int likeCount, List<String> likedBy) async {
    try {
      await _db
          .collection("Comments")
          .doc(commentId)
          .collection("CommentReply")
          .doc(replyId)
          .update({
        'commentLikeCount': likeCount,
        'likedBy': likedBy,
      });
    } catch (e) {
      print("Error updating comment reply likes: $e");
    }
  }

  // ========================= PIN COMMENTS =========================

  /// Pin or unpin a comment (boolean isPinned field).
  Future<void> setPinComment({
    required String postId,
    required String commentId,
    required bool pin,
  }) async {
    try {
      await _db.collection("Comments").doc(commentId).update({'isPinned': pin});
    } catch (e) {
      print("Error updating pin status on comment: $e");
    }
  }

  // ========================= REAL-TIME STREAMS =========================

  /// Stream of comments for a post, pinned comments first.
  Stream<List<Comment>> commentsStream(String postId) {
    return _db
        .collection("Comments")
        .where("postId", isEqualTo: postId)
        .orderBy("isPinned", descending: true)
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList());
  }

  /// Stream of replies for a comment.
  Stream<List<Comment>> commentRepliesStream(String commentId) {
    return _db
        .collection("Comments")
        .doc(commentId)
        .collection("CommentReply")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Comment(
                id: doc.id,
                postId: commentId,
                uid: data['uid'] ?? '',
                name: data['name'] ?? '',
                username: data['username'] ?? '',
                message: data['message'] ?? '',
                timestamp: data['timestamp'] ?? Timestamp.now(),
                commentLikeCount: data['commentLikeCount'] ?? 0,
                likedBy: List<String>.from(data['likedBy'] ?? []),
                commentReplyCount: 0,
                isPinned: false,
              );
            }).toList());
  }
}





















// /*

// DATABASE SERVICE

// This class handles all the data from and to Firebase

// - User profile
// - post message
// - likes
// - comments
// - account stuff (report / block / delete account)
// - follow / unfollow
// - Search users

// */



// /*
//   DATABASE SERVICE
//   ----------------
//   This class handles ALL data communication with Firebase Firestore.

//   Responsibilities:
//   - User Profile management
//   - Post management
//   - Likes
//   - Comments
//   - Replies
//   - Pinning comments
// */

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:social_media/models/comment.dart';
// import 'package:social_media/models/post.dart';
// import 'package:social_media/models/user.dart';
// import 'package:social_media/services/auth/auth_service.dart';

// class DatabaseService {
//   // Firestore & Auth instances
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // ========================= USER PROFILE =========================

//   /// Save a new user's profile in Firestore
//   Future<void> saveUserInfoFirebase({
//     required String name,
//     required String email,
//   }) async {
//     String uid = _auth.currentUser!.uid;
//     String username = email.split('@')[0];

//     UserProfile user = UserProfile(
//       uid: uid,
//       name: name,
//       email: email,
//       username: username,
//       bio: '',
//     );

//     await _db.collection("Users").doc(uid).set(user.toMap());
//   }

//   /// Get user profile by UID
//   Future<UserProfile?> getUserFromFirebase(String uid) async {
//     try {
//       DocumentSnapshot userDoc = await _db.collection("Users").doc(uid).get();
//       return UserProfile.fromDocument(userDoc);
//     } catch (e) {
//       print("Error getting user: $e");
//       return null;
//     }
//   }

//   /// Update current user's bio
//   Future<void> updateUserBioInFirebase(String bio) async {
//     String uid = AuthService().getCurrentUid();
//     try {
//       await _db.collection("Users").doc(uid).update({'bio': bio});
//     } catch (e) {
//       print("Error updating bio: $e");
//     }
//   }

//   // ========================= POSTS =========================

//   /// Create a new post
//   Future<void> postMessageInFirebase(String message) async {
//     try {
//       String uid = _auth.currentUser!.uid;
//       UserProfile? user = await getUserFromFirebase(uid);

//       Post newPost = Post(
//         id: '',
//         uid: uid,
//         name: user!.name,
//         username: user.username,
//         message: message,
//         timestamp: Timestamp.now(),
//         likeCount: 0,
//         likedBy: [],
//       );

//       await _db.collection("Posts").add(newPost.toMap());
//     } catch (e) {
//       print("Error posting message: $e");
//     }
//   }

//   /// Delete post
//   Future<void> deletePostFromFirebase(String postId) async {
//     try {
//       await _db.collection("Posts").doc(postId).delete();
//     } catch (e) {
//       print("Error deleting post: $e");
//     }
//   }

//   /// Fetch all posts
//   Future<List<Post>> getAllPostsFromFirebase() async {
//     try {
//       QuerySnapshot snapshot = await _db
//           .collection("Posts")
//           .orderBy('timestamp', descending: true)
//           .get();
//       return snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
//     } catch (e) {
//       print("Error getting posts: $e");
//       return [];
//     }
//   }

//   /// Like / Unlike a post
//   Future<void> toggleLikeInFirebase(String postId, String userId) async {
//   // Use userId passed instead of _auth.currentUser.uid
//   try {
//     final postDoc = _db.collection("Posts").doc(postId);

//     await _db.runTransaction((transaction) async {
//       final postSnapshot = await transaction.get(postDoc);

//       if (!postSnapshot.exists) {
//         throw Exception("Post does not exist!");
//       }

//       final likedBy = List<String>.from(postSnapshot.get('likedBy') ?? []);
//       final currentLikeCount = postSnapshot.get('likes') ?? 0;

//       if (!likedBy.contains(userId)) {
//         likedBy.add(userId);
//         transaction.update(postDoc, {
//           'likes': currentLikeCount + 1,
//           'likedBy': likedBy,
//         });
//       } else {
//         likedBy.remove(userId);
//         transaction.update(postDoc, {
//           'likes': (currentLikeCount > 0) ? currentLikeCount - 1 : 0,
//           'likedBy': likedBy,
//         });
//       }
//     });
//   } catch (e) {
//     print("Error toggling like: $e");
//   }
// }


//   // ========================= COMMENTS =========================

//   /// Add comment
//   Future<void> addCommentInFirebase(String postId, String message) async {
//     try {
//       String uid = _auth.currentUser!.uid;
//       UserProfile? user = await getUserFromFirebase(uid);

//       Comment newComment = Comment(
//         id: '',
//         postId: postId,
//         uid: uid,
//         name: user!.name,
//         username: user.username,
//         message: message,
//         timestamp: Timestamp.now(),
//         commentLikeCount: 0,
//         likedBy: [],
//       );

//       await _db.collection("Comments").add(newComment.toMap());
//     } catch (e) {
//       print("Error adding comment: $e");
//     }
//   }

//   /// Delete comment
//   Future<void> deleteCommentInFirebase(String commentId) async {
//     try {
//       await _db.collection("Comments").doc(commentId).delete();
//     } catch (e) {
//       print("Error deleting comment: $e");
//     }
//   }

//   /// Get comments (pinned first)
//   Future<List<Comment>> getCommentsFromFirebase(String postId) async {
//   try {
//     QuerySnapshot snapshot = await _db
//         .collection("Comments")
//         .where("postId", isEqualTo: postId)
//         .orderBy("isPinned", descending: true)    // Add this line
//         .orderBy("timestamp", descending: true)   // Then by timestamp
//         .get();
//     return snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
//   } catch (e) {
//     print("Error getting comments: $e");
//     return [];
//   }
// }


//   /// Update likes on comment
//   Future<void> updateCommentLikesInFirebase(
//       String commentId, int likeCount, List<String> likedBy) async {
//     try {
//       await _db.collection("Comments").doc(commentId).update({
//         'commentLikeCount': likeCount,
//         'likedBy': likedBy,
//       });
//     } catch (e) {
//       print("Error updating comment likes: $e");
//     }
//   }

//   // ——— COMMENT REPLIES ———

// // Add a reply to a specific comment
// Future<void> addCommentReplyInFirebase(
//     String commentId, String message) async {
//   try {
//     String uid = _auth.currentUser!.uid;
//     UserProfile? user = await getUserFromFirebase(uid);

//     final replyData = {
//       'commentId': commentId,
//       'uid': uid,
//       'name': user!.name,
//       'username': user.username,
//       'message': message,
//       'timestamp': Timestamp.now(),
//       'commentLikeCount': 0,
//       'likedBy': [],
//     };

//     await _db
//         .collection("Comments")
//         .doc(commentId)
//         .collection("CommentReply")
//         .add(replyData);
//   } catch (e) {
//     print('Error adding comment reply: $e');
//   }
// }

// // Fetch replies for a specific comment
// Future<List<Comment>> getCommentRepliesFromFirebase(String commentId) async {
//   try {
//     QuerySnapshot snapshot = await _db
//         .collection("Comments")
//         .doc(commentId)
//         .collection("CommentReply")
//         .orderBy("timestamp", descending: true)
//         .get();

//     return snapshot.docs.map((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       return Comment(
//         id: doc.id,
//         postId: commentId, // parent comment id as postId for replies (or you can add a separate field)
//         uid: data['uid'] ?? '',
//         name: data['name'] ?? '',
//         username: data['username'] ?? '',
//         message: data['message'] ?? '',
//         timestamp: data['timestamp'] ?? Timestamp.now(),
//         commentLikeCount: data['commentLikeCount'] ?? 0,
//         likedBy: List<String>.from(data['likedBy'] ?? []),
//       );
//     }).toList();
//   } catch (e) {
//     print('Error fetching comment replies: $e');
//     return [];
//   }
// }

// // Delete a comment reply
// Future<void> deleteCommentReplyInFirebase(String commentId, String replyId) async {
//   try {
//     await _db
//         .collection("Comments")
//         .doc(commentId)
//         .collection("CommentReply")
//         .doc(replyId)
//         .delete();
//   } catch (e) {
//     print('Error deleting comment reply: $e');
//   }
// }

// // Update likes for a comment reply in Firebase
// Future<void> updateCommentReplyLikesInFirebase(
//   String commentId,
//   String replyId,
//   int likeCount,
//   List<String> likedBy,
// ) async {
//   try {
//     await _db
//       .collection("Comments")
//       .doc(commentId)
//       .collection("CommentReply")
//       .doc(replyId)
//       .update({
//         'commentLikeCount': likeCount,
//         'likedBy': likedBy,
//       });
//   } catch (e) {
//     print('Error updating comment reply likes: $e');
//   }
// }

// // Real-time stream for replies of a comment
// Stream<List<Comment>> commentRepliesStream(String commentId) {
//   return _db
//       .collection("Comments")
//       .doc(commentId)
//       .collection("CommentReply")
//       .orderBy("timestamp", descending: true)
//       .snapshots()
//       .map((snapshot) {
//         return snapshot.docs.map((doc) {
//           final data = doc.data() as Map<String, dynamic>;
//           return Comment(
//             id: doc.id,
//             postId: commentId,
//             uid: data['uid'] ?? '',
//             name: data['name'] ?? '',
//             username: data['username'] ?? '',
//             message: data['message'] ?? '',
//             timestamp: data['timestamp'] ?? Timestamp.now(),
//             commentLikeCount: data['commentLikeCount'] ?? 0,
//             likedBy: List<String>.from(data['likedBy'] ?? []),
//           );
//         }).toList();
//       });
// }
//   // ========================= PIN COMMENTS =========================

//   Future<void> setPinComment({
//     required String postId,
//     required String commentId,
//     required bool pin,
//   }) async {
//     final commentRef =
//         _db.collection("Comments").doc(commentId);
//     await commentRef.update({'isPinned': pin});
//   }

// // stream vision 

// Stream<List<Comment>> commentsStream(String postId) {
//   return _db
//       .collection("Comments")
//       .where("postId", isEqualTo: postId)
//       .orderBy("isPinned", descending: true)
//       .orderBy("timestamp", descending: true)
//       .snapshots()
//       .map((snapshot) => snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList());
// }

// }





/*

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media/models/comment.dart';
import 'package:social_media/models/post.dart';
import 'package:social_media/models/user.dart';
import 'package:social_media/services/auth/auth_service.dart';

class DatabaseService {
  // get instance of firestore db and auth
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /*
  USER PROFILE

  - when new user registers, we create an account for them and also store details in database
  */

  // Save user info
  Future<void> saveUserInfoFirebase({required String name, required String email}) async {
    // get current user uid
    String uid = _auth.currentUser!.uid;

    // extract username from email
    String username = email.split('@')[0];

    // create user profile
    UserProfile user = UserProfile(uid: uid, name: name, email: email, username: username, bio: '');

    // convert user into a map so that we can store in firebase
    final userMap = user.toMap();

    // save user info in firebase
    await _db.collection("Users").doc(uid).set(userMap);
  }

  // Get user info
  Future<UserProfile?> getUserFromFirebase(String uid) async {
    try {
      // retrieve document to user profile
      DocumentSnapshot userDoc = await _db.collection("Users").doc(uid).get();

      // convert doc to user profile
      return UserProfile.fromDocument(userDoc);
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Update user bio
  Future<void> updateUserBioInFirebase(String bio) async {
    // get current uid
    String uid = AuthService().getCurrentUid();

    // attempt to update in firebase
    try {
      await _db.collection("Users").doc(uid).update({'bio': bio});
    } catch (e) {
      print(e);
    }
  }

  /*
  
  POST MESSAGE

   */

  //  Post a message
  Future<void> postMessageInFirebase(String message) async {
    try {

      // get curret uid
      String uid = _auth.currentUser!.uid;

      // use this uid to get the users profile
      UserProfile? user = await getUserFromFirebase(uid);

      // create a new post
       Post newPost = Post(
        id: '', //firebase will auto generate this
        uid: uid,
        name: user!.name,
        username: user.username,
        message: message,
        timestamp: Timestamp.now(),
        likeCount: 0,
        likedBy: [],
      );

      // convet post object --> map
      Map<String, dynamic> newPostMap = newPost.toMap();

      // add to the firebase
      await _db.collection("Posts").add(newPostMap);

    } 
    
    // catch any error
    catch (e) {
      print(e);
    }


    
  }

  // Delete a post from Firebase using its document ID
Future<void> deletePostFromFirebase(String postId) async {
  try {
    await _db.collection("Posts").doc(postId).delete();
    print("Post deleted: $postId");
  } catch (e) {
    print("Failed to delete post: $e");
  }
}


  // get all post 
  Future<List<Post>> getAllPostsFromFirebse() async {
    try{
      QuerySnapshot snapshot = await _db 

      // go to collection ==> post
      .collection("Posts")
      // cronological order
      .orderBy('timestamp',descending: true)
      // get the data
      .get();

      // return as a list post
      return snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    }
    catch(e) {
      return [];
    }
  }

  // get individual post

  // LIKE A POST
  Future<void> toggleLikeInFirebase(String postId) async {
    try {
      // get current uid
      String uid = _auth.currentUser!.uid;

      // go to doc for this 
      DocumentReference postDoc = _db.collection("Posts").doc(postId);

      // execute like
      await _db.runTransaction((transaction) async {
        
        // get post data
        DocumentSnapshot postSnapshot = await transaction.get(postDoc);

        // get like of user who like this post
        List<String> likedBy = 
          List<String>.from(postSnapshot['likedBy'] ?? []); 

        // get like count
        int currentLikeCount = postSnapshot["likes"];

        // if user has not liked this post yet --> then like
        if (!likedBy.contains(uid)) {
          // add user to like list
          likedBy.add(uid);

          // increment like count
          currentLikeCount++;
        }

        // if user has alredy like this post --> then unlike
        else {
          // remove user from list
          likedBy.remove(uid);

          // decrement like count
          currentLikeCount--;
        }

        // update in firebase
        transaction.update(postDoc, {
          'likes': currentLikeCount,
          'likedBy':likedBy,
        });

      }, );
    } catch (e) {
      print(e);
    }
  }




//   // COMMENTS

//     // 1️⃣ Add a comment to a post
//     Future<void> addCommentInFirebase(String postId, message, ) async {
//     try {

//       // get current user
//       String uid = _auth.currentUser!.uid; 
//       UserProfile? user = await getUserFromFirebase(uid);

//       // create new comment
//       Comment newComment = Comment(
//         id: '', 
//         postId: postId, 
//         uid: uid, 
//         name: user!.name, 
//         username: user.username, 
//         message: message, 
//         timestamp: Timestamp.now(),
//          commentLikeCount: 0,
//   likedBy: [],           // <-- initialize empty likedBy list
//         );

//         // convert the comment to map
//         Map<String, dynamic> newCommentMap = newComment.toMap();

//         // to store in firebase
//         await _db.collection("Comments").add(newCommentMap);

//     } catch (e) {
//       print(e);
//     }
//   }

//     // Delete comment from a post
//     Future<void> deleteCommentInFirebase(String commentId) async {
//     try {
//       await _db.collection("Comments").doc(commentId).delete();
//     } catch (e) {
//       print(e);
//     }
//   }

//     // Fetch comments for a post
//     Future<List<Comment>> getCommentsFromFirebase(String postId) async {
//       try{
//         // get comments from firebase
//         QuerySnapshot snapshot = await _db
//         .collection("Comments")
//         .where("postId", isEqualTo: postId)
//          .orderBy("timestamp", descending: true) 
//         .get();

//         // returen as a list of comments
//         return snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
//       } catch (e) {
//         print(e);
//         return [];
//       }
//     }

//     // Update likes for a comment in Firebase (count and likedBy list)
// Future<void> updateCommentLikesInFirebase(
//     String commentId, int likeCount, List<String> likedBy) async {
//   try {
//     await _db.collection("Comments").doc(commentId).update({
//       'commentLikeCount': likeCount,
//       'likedBy': likedBy,
//     });
//   } catch (e) {
//     print('Error updating comment likes: $e');
//   }
// }

// // ——— COMMENT REPLIES ———

// // Add a reply to a specific comment
// Future<void> addCommentReplyInFirebase(
//     String commentId, String message) async {
//   try {
//     String uid = _auth.currentUser!.uid;
//     UserProfile? user = await getUserFromFirebase(uid);

//     final replyData = {
//       'commentId': commentId,
//       'uid': uid,
//       'name': user!.name,
//       'username': user.username,
//       'message': message,
//       'timestamp': Timestamp.now(),
//       'commentLikeCount': 0,
//       'likedBy': [],
//     };

//     await _db
//         .collection("Comments")
//         .doc(commentId)
//         .collection("CommentReply")
//         .add(replyData);
//   } catch (e) {
//     print('Error adding comment reply: $e');
//   }
// }

// // Fetch replies for a specific comment
// Future<List<Comment>> getCommentRepliesFromFirebase(String commentId) async {
//   try {
//     QuerySnapshot snapshot = await _db
//         .collection("Comments")
//         .doc(commentId)
//         .collection("CommentReply")
//         .orderBy("timestamp", descending: true)
//         .get();

//     return snapshot.docs.map((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       return Comment(
//         id: doc.id,
//         postId: commentId, // parent comment id as postId for replies (or you can add a separate field)
//         uid: data['uid'] ?? '',
//         name: data['name'] ?? '',
//         username: data['username'] ?? '',
//         message: data['message'] ?? '',
//         timestamp: data['timestamp'] ?? Timestamp.now(),
//         commentLikeCount: data['commentLikeCount'] ?? 0,
//         likedBy: List<String>.from(data['likedBy'] ?? []),
//       );
//     }).toList();
//   } catch (e) {
//     print('Error fetching comment replies: $e');
//     return [];
//   }
// }

// // Delete a comment reply
// Future<void> deleteCommentReplyInFirebase(String commentId, String replyId) async {
//   try {
//     await _db
//         .collection("Comments")
//         .doc(commentId)
//         .collection("CommentReply")
//         .doc(replyId)
//         .delete();
//   } catch (e) {
//     print('Error deleting comment reply: $e');
//   }
// }

// // Update likes for a comment reply in Firebase
// Future<void> updateCommentReplyLikesInFirebase(
//   String commentId,
//   String replyId,
//   int likeCount,
//   List<String> likedBy,
// ) async {
//   try {
//     await _db
//       .collection("Comments")
//       .doc(commentId)
//       .collection("CommentReply")
//       .doc(replyId)
//       .update({
//         'commentLikeCount': likeCount,
//         'likedBy': likedBy,
//       });
//   } catch (e) {
//     print('Error updating comment reply likes: $e');
//   }
// }




//   /// Pin or unpin a comment by setting 'isPinned' field.
//   /// Only the post owner should be allowed to call this.
//   Future<void> setPinComment({
//     required String postId,
//     required String commentId,
//     required bool pin,
//   }) async {
//     final commentRef = _firestore
//         .collection('posts')
//         .doc(postId)
//         .collection('comments')
//         .doc(commentId);

//     await commentRef.update({'isPinned': pin});
//   }

 
//   // TODO: POST MESSAGE, likes, comments, follow/unfollow etc.


 }


 */