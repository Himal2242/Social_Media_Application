import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_media/models/comment.dart';
import 'package:social_media/models/post.dart';
import 'package:social_media/models/user.dart';
import 'package:social_media/services/auth/auth_service.dart';
import 'package:social_media/services/database/database_service.dart';

class DatabaseProvider extends ChangeNotifier {
  final _db = DatabaseService();
  final _auth = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Subscriptions for real-time updates of comments, replies, and posts
  final Map<String, StreamSubscription> _commentsSubs = {};
  final Map<String, StreamSubscription> _repliesSubs = {};
  StreamSubscription? _postsSubscription;

  // List holding all posts locally
  List<Post> _allPosts = [];
  List<Post> get allPosts => _allPosts;

  // Set of post IDs liked by current user for quick lookup
  final Set<String> _userLikedPosts = {};

  DatabaseProvider() {
    _initialize();
  }

  // Initialize listeners for posts and set up data caches
  void _initialize() {
    startListeningToPosts();
  }

  @override
  void dispose() {
    _commentsSubs.values.forEach((sub) => sub.cancel());
    _repliesSubs.values.forEach((sub) => sub.cancel());
    _postsSubscription?.cancel();
    super.dispose();
  }

  /* ==================== */
  /* === USER PROFILE === */
  /* ==================== */

  /// Fetch a user profile by UID
  Future<UserProfile?> userProfile(String uid) => _db.getUserFromFirebase(uid);

  /// Update the user's bio text
  Future<bool> updateBio(String bio) async {
    try {
      await _db.updateUserBioInFirebase(bio);
      return true;
    } catch (e) {
      debugPrint('Bio update failed: $e');
      return false;
    }
  }

  /* ================= */
  /* === POSTS ======= */
  /* ================= */

  /// Create a new post with a message
  Future<bool> postMessage(String message) async {
    try {
      await _db.postMessageInFirebase(message);
      return true;
    } catch (e) {
      debugPrint('Post creation failed: $e');
      return false;
    }
  }

  /// Load all posts from Firestore (non-stream method)
  Future<void> loadAllPosts() async {
    try {
      _allPosts = await _db.getAllPostsFromFirebase();
      _updateUserLikedPostsCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Post loading failed: $e');
    }
  }

  /// Filter posts to only those created by a particular user
  List<Post> filterUserPosts(String uid) =>
      _allPosts.where((post) => post.uid == uid).toList();

  /// Delete a post by its ID and refresh posts
  Future<bool> deletePost(String postId) async {
    try {
      await _db.deletePostFromFirebase(postId);
      await loadAllPosts();
      return true;
    } catch (e) {
      debugPrint('Post deletion failed: $e');
      return false;
    }
  }

  /* ==================== */
  /* === LIKES ON POSTS == */
  /* ==================== */

  /// Check if current user liked a post (fast lookup)
  bool isPostLikedByCurrentUser(String postId) => _userLikedPosts.contains(postId);

  /// Update local cache of liked posts for current user
  void _updateUserLikedPostsCache() {
    final currentUser = _auth.getCurrentUid();
    if (currentUser == null) return;

    _userLikedPosts.clear();

    for (final post in _allPosts) {
      if (post.likedBy.contains(currentUser)) {
        _userLikedPosts.add(post.id);
      }
    }
  }

  /// Toggle like/unlike for a post
  ///
  /// Updates both `likedBy` list and `likeCount` integer atomically in Firestore.
  /// Also updates local cache and UI optimistically.
  Future<void> toggleLike(String postId) async {
    final currentUser = _auth.getCurrentUid();
    if (currentUser == null) return;

    final postIndex = _allPosts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = _allPosts[postIndex];
    final userLiked = post.likedBy.contains(currentUser);

    // Prepare updated likedBy list and likeCount
    final List<String> updatedLikedBy = List<String>.from(post.likedBy);
    int updatedLikeCount = post.likeCount;

    if (userLiked) {
      updatedLikedBy.remove(currentUser);
      updatedLikeCount = (updatedLikeCount > 0) ? updatedLikeCount - 1 : 0;
    } else {
      updatedLikedBy.add(currentUser);
      updatedLikeCount += 1;
    }

    // Optimistically update local post data
    final updatedPost = Post(
      id: post.id,
      uid: post.uid,
      name: post.name,
      username: post.username,
      message: post.message,
      timestamp: post.timestamp,
      likedBy: updatedLikedBy,
      likeCount: updatedLikeCount,
      // Keep other fields unchanged if any
      // Add any other Post fields here if your Post model has more
    );

    _allPosts[postIndex] = updatedPost;

    // Update liked posts cache
    if (userLiked) {
      _userLikedPosts.remove(postId);
    } else {
      _userLikedPosts.add(postId);
    }

    notifyListeners();

    // Firestore transaction to update atomically
    final postRef = _firestore.collection('Posts').doc(postId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);
        if (!snapshot.exists) throw Exception('Post not found');

        final List<dynamic> currentLikedBy =
            List<dynamic>.from(snapshot.get('likedBy') ?? []);
        int currentLikeCount = snapshot.get('likeCount') ?? 0;

        if (userLiked) {
          currentLikedBy.remove(currentUser);
          currentLikeCount = (currentLikeCount > 0) ? currentLikeCount - 1 : 0;
        } else {
          currentLikedBy.add(currentUser);
          currentLikeCount += 1;
        }

        transaction.update(postRef, {
          'likedBy': currentLikedBy,
          'likeCount': currentLikeCount,
        });
      });
    } catch (e) {
      debugPrint('Failed to toggle like: $e');

      // Revert local changes on failure
      _allPosts[postIndex] = post;
      if (userLiked) {
        _userLikedPosts.add(postId);
      } else {
        _userLikedPosts.remove(postId);
      }
      notifyListeners();
    }
  }

  /* =================== */
  /* === COMMENTS ====== */
  /* =================== */

  final Map<String, List<Comment>> _comments = {};
  final Map<String, DocumentSnapshot?> _lastCommentDoc = {};
  final Map<String, bool> _hasMoreComments = {};
  final int _commentsPerPage = 15;

  List<Comment> getComments(String postId) => _comments[postId] ?? [];
  bool hasMoreComments(String postId) => _hasMoreComments[postId] ?? true;

  /// Load initial comments page for post
  Future<void> loadComments(String postId) async {
    _comments[postId] = [];
    _lastCommentDoc[postId] = null;
    _hasMoreComments[postId] = true;
    await loadMoreComments(postId);
  }

  /// Load more comments (pagination)
  Future<void> loadMoreComments(String postId) async {
    if (!(_hasMoreComments[postId] ?? true)) return;

    Query query = _firestore
        .collection('Comments')
        .where('postId', isEqualTo: postId)
        .orderBy('isPinned', descending: true)
        .orderBy('timestamp', descending: true)
        .limit(_commentsPerPage);

    if (_lastCommentDoc[postId] != null) {
      query = query.startAfterDocument(_lastCommentDoc[postId]!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      _hasMoreComments[postId] = false;
      notifyListeners();
      return;
    }

    final newComments = snapshot.docs.map(Comment.fromDocument).toList();
    _comments[postId] = [...(_comments[postId] ?? []), ...newComments];
    _lastCommentDoc[postId] = snapshot.docs.last;
    _hasMoreComments[postId] = newComments.length >= _commentsPerPage;
    notifyListeners();
  }

  /// Add new comment to post
  Future<bool> addComment(String postId, String message) async {
    try {
      await _db.addCommentInFirebase(postId, message);
      await loadComments(postId);
      return true;
    } catch (e) {
      debugPrint('Comment add failed: $e');
      return false;
    }
  }

  /// Delete a comment and reload
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      await _db.deleteCommentInFirebase(commentId);
      await loadComments(postId);
      return true;
    } catch (e) {
      debugPrint('Comment delete failed: $e');
      return false;
    }
  }

  /// Toggle like on a comment, updating likedBy list and likeCount integer
  Future<void> toggleLikeComment(
      String postId, String commentId, String userId) async {
    final comments = _comments[postId];
    if (comments == null) return;

    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final comment = comments[index];
    final userLiked = comment.likedBy.contains(userId);

    final List<String> updatedLikedBy = List<String>.from(comment.likedBy);
    int updatedLikeCount = comment.commentLikeCount;

    if (userLiked) {
      updatedLikedBy.remove(userId);
      updatedLikeCount = (updatedLikeCount > 0) ? updatedLikeCount - 1 : 0;
    } else {
      updatedLikedBy.add(userId);
      updatedLikeCount += 1;
    }

    // Create a new Comment instance with updated fields
    final updatedComment = Comment(
      id: comment.id,
      postId: comment.postId,
      uid: comment.uid,
      name: comment.name,
      username: comment.username,
      message: comment.message,
      timestamp: comment.timestamp,
      likedBy: updatedLikedBy,
      commentLikeCount: updatedLikeCount,
      commentReplyCount: comment.commentReplyCount,
      isPinned: comment.isPinned,
    );

    comments[index] = updatedComment;
    notifyListeners();

    try {
      await _db.updateCommentLikesInFirebase(
        commentId,
        updatedLikeCount,
        updatedLikedBy,
      );
    } catch (e) {
      debugPrint('Comment like failed: $e');
    }
  }

  /// Toggle pin status for a comment (used by post owner)
  Future<void> togglePinComment({
    required String postId,
    required String commentId,
    required bool newPinState,
  }) async {
    try {
      await _db.setPinComment(
        postId: postId,
        commentId: commentId,
        pin: newPinState,
      );
      await loadComments(postId);
    } catch (e) {
      debugPrint('Comment pin failed: $e');
    }
  }

  /* ================== */
  /* === REPLIES ====== */
  /* ================== */

  final Map<String, List<Comment>> _commentReplies = {};

  List<Comment> getCommentReplies(String commentId) =>
      _commentReplies[commentId] ?? [];

  Future<void> loadCommentReplies(String commentId) async {
    try {
      _commentReplies[commentId] = await _db.getCommentRepliesFromFirebase(commentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Reply loading failed: $e');
    }
  }

  Future<bool> addCommentReply(String commentId, String message) async {
    try {
      await _db.addCommentReplyInFirebase(commentId, message);
      await loadCommentReplies(commentId);
      return true;
    } catch (e) {
      debugPrint('Reply add failed: $e');
      return false;
    }
  }

  Future<bool> deleteCommentReply(String commentId, String replyId) async {
    try {
      await _db.deleteCommentReplyInFirebase(commentId, replyId);
      await loadCommentReplies(commentId);
      return true;
    } catch (e) {
      debugPrint('Reply delete failed: $e');
      return false;
    }
  }

  Future<void> toggleLikeCommentReply(
      String commentId, String replyId, String userId) async {
    final replies = _commentReplies[commentId];
    if (replies == null) return;

    final index = replies.indexWhere((r) => r.id == replyId);
    if (index == -1) return;

    final reply = replies[index];
    final userLiked = reply.likedBy.contains(userId);

    final List<String> updatedLikedBy = List<String>.from(reply.likedBy);
    int updatedLikeCount = reply.commentLikeCount;

    if (userLiked) {
      updatedLikedBy.remove(userId);
      updatedLikeCount = (updatedLikeCount > 0) ? updatedLikeCount - 1 : 0;
    } else {
      updatedLikedBy.add(userId);
      updatedLikeCount += 1;
    }

    final updatedReply = Comment(
      id: reply.id,
      postId: reply.postId,
      uid: reply.uid,
      name: reply.name,
      username: reply.username,
      message: reply.message,
      timestamp: reply.timestamp,
      likedBy: updatedLikedBy,
      commentLikeCount: updatedLikeCount,
      commentReplyCount: reply.commentReplyCount,
      isPinned: reply.isPinned,
    );

    replies[index] = updatedReply;
    notifyListeners();

    try {
      await _db.updateCommentReplyLikesInFirebase(
        commentId,
        replyId,
        updatedLikeCount,
        updatedLikedBy,
      );
    } catch (e) {
      debugPrint('Reply like failed: $e');
    }
  }

  /* ======================= */
  /* === REAL-TIME STREAMS == */
  /* ======================= */

  /// Stream of all posts ordered by timestamp descending
  Stream<List<Post>> postsStream() => _firestore
      .collection('Posts')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Post.fromDocument).toList());

  /// Listen to post changes in real-time
  void startListeningToPosts() {
    _postsSubscription?.cancel();
    _postsSubscription = postsStream().listen((posts) {
      _allPosts = posts;
      _updateUserLikedPostsCache();
      notifyListeners();
    });
  }

  /// Stream of comments for a post, ordered by pinned and timestamp descending
  Stream<List<Comment>> commentsStream(String postId) => _firestore
      .collection('Comments')
      .where('postId', isEqualTo: postId)
      .orderBy('isPinned', descending: true)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Comment.fromDocument).toList());

  /// Start listening to comments updates for a specific post
  void listenToComments(String postId) {
    _commentsSubs[postId]?.cancel();
    _commentsSubs[postId] = commentsStream(postId).listen((comments) {
      _comments[postId] = comments;
      notifyListeners();
    });
  }

  /// Stream of replies for a specific comment
  Stream<List<Comment>> commentRepliesStream(String commentId) => _firestore
      .collection('Comments')
      .doc(commentId)
      .collection('CommentReply')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Comment.fromDocument).toList());

  /// Start listening to replies updates for a comment
  void listenToReplies(String commentId) {
    _repliesSubs[commentId]?.cancel();
    _repliesSubs[commentId] = commentRepliesStream(commentId).listen((replies) {
      _commentReplies[commentId] = replies;
      notifyListeners();
    });
  }

  int getLikeCount(String postId) {
  try {
    final post = _allPosts.firstWhere((p) => p.id == postId);
    return post.likeCount;
  } catch (e) {
    return 0;
  }
}

  String? get currentUserId => _auth.getCurrentUid();

  // other experiment

  
}





// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:social_media/models/comment.dart';
// import 'package:social_media/models/post.dart';
// import 'package:social_media/models/user.dart';
// import 'package:social_media/services/auth/auth_service.dart';
// import 'package:social_media/services/database/database_service.dart';

// class DatabaseProvider extends ChangeNotifier {
//   final _db = DatabaseService();
//   final _auth = AuthService();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   final Map<String, StreamSubscription> _commentsSubs = {};
//   final Map<String, StreamSubscription> _repliesSubs = {};

//   @override
//   void dispose() {
//     for (final sub in _commentsSubs.values) {
//       sub.cancel();
//     }
//     for (final sub in _repliesSubs.values) {
//       sub.cancel();
//     }
//     super.dispose();
//   }

//   // ---------------------------------------------------------------------------
//   // USER PROFILE
//   // ---------------------------------------------------------------------------

//   Future<UserProfile?> userProfile(String uid) => _db.getUserFromFirebase(uid);

//   Future<bool> updateBio(String bio) async {
//     try {
//       await _db.updateUserBioInFirebase(bio);
//       return true;
//     } catch (e) {
//       debugPrint('Error updating bio: $e');
//       return false;
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // POSTS
//   // ---------------------------------------------------------------------------

//   List<Post> _allPosts = [];
//   List<Post> get allPosts => _allPosts;

//   Future<bool> postMessage(String message) async {
//     final currentUid = _auth.getCurrentUid();
//     if (currentUid == null) return false;
//     try {
//       await _db.postMessageInFirebase(message);
//       return true;
//     } catch (e) {
//       debugPrint('Error posting message: $e');
//       return false;
//     }
//   }

//   Future<void> loadAllPosts() async {
//     _allPosts = await _db.getAllPostsFromFirebase();
//     initializeLikeMap();
//     notifyListeners();
//   }

//   List<Post> filterUserPosts(String uid) =>
//       _allPosts.where((post) => post.uid == uid).toList();

//   Future<bool> deletePost(String postId) async {
//     try {
//       await _db.deletePostFromFirebase(postId);
//       await loadAllPosts();
//       return true;
//     } catch (e) {
//       debugPrint('Error deleting post: $e');
//       return false;
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // POST LIKES
//   // ---------------------------------------------------------------------------

//   Map<String, int> _likeCounts = {};
//   List<String> _likedPosts = [];

//   bool isPostLikedByCurrentUser(String postId) => _likedPosts.contains(postId);
//   int getLikeCount(String postId) => _likeCounts[postId] ?? 0;

//   void initializeLikeMap() {
//     final currentUserID = _auth.getCurrentUid() ?? '';
//     _likeCounts.clear();
//     _likedPosts.clear();
//     for (var post in _allPosts) {
//       _likeCounts[post.id] = post.likeCount;
//       if (post.likedBy.contains(currentUserID)) {
//         _likedPosts.add(post.id);
//       }
//     }
//   }

//   Future<void> toggleLike(String postId) async {
//     final currentUserID = _auth.getCurrentUid();
//     if (currentUserID == null) return;

//     final originalLikedPosts = List<String>.from(_likedPosts);
//     final originalLikeCounts = Map<String, int>.from(_likeCounts);

//     if (_likedPosts.contains(postId)) {
//       _likedPosts.remove(postId);
//       _likeCounts[postId] = (_likeCounts[postId] ?? 1) - 1;
//     } else {
//       _likedPosts.add(postId);
//       _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
//     }
//     notifyListeners();

//     try {
//       await _db.toggleLikeInFirebase(postId, currentUserID);
//     } catch (e) {
//       _likedPosts = originalLikedPosts;
//       _likeCounts = originalLikeCounts;
//       notifyListeners();
//       debugPrint('Error toggling like: $e');
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // COMMENTS WITH LAZY LOADING
//   // ---------------------------------------------------------------------------

//   final Map<String, List<Comment>> _comments = {};
//   final Map<String, DocumentSnapshot?> _lastCommentDoc = {};
//   final Map<String, bool> _hasMoreComments = {};
//   final int _commentsPerPage = 15;

//   List<Comment> getComments(String postId) => _comments[postId] ?? [];
//   bool hasMoreComments(String postId) => _hasMoreComments[postId] ?? true;

//   Future<void> loadComments(String postId) async {
//     _comments[postId] = [];
//     _lastCommentDoc[postId] = null;
//     _hasMoreComments[postId] = true;
//     await loadMoreComments(postId);
//   }

//   Future<void> loadMoreComments(String postId) async {
//     if (_hasMoreComments[postId] == false) return;

//     Query query = _firestore
//         .collection('Comments')
//         .where('postId', isEqualTo: postId)
//         .orderBy('isPinned', descending: true)
//         .orderBy('timestamp', descending: true)
//         .limit(_commentsPerPage);

//     if (_lastCommentDoc[postId] != null) {
//       query = query.startAfterDocument(_lastCommentDoc[postId]!);
//     }

//     final snapshot = await query.get();
//     if (snapshot.docs.isEmpty) {
//       _hasMoreComments[postId] = false;
//       notifyListeners();
//       return;
//     }

//     final newComments =
//         snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();

//     _comments[postId] = [..._comments[postId] ?? [], ...newComments];
//     _lastCommentDoc[postId] = snapshot.docs.last;

//     if (newComments.length < _commentsPerPage) {
//       _hasMoreComments[postId] = false;
//     }
//     notifyListeners();
//   }

//   Future<bool> addComment(String postId, String message) async {
//     final currentUserID = _auth.getCurrentUid();
//     if (currentUserID == null) return false;
//     try {
//       await _db.addCommentInFirebase(postId, message);
//       await loadComments(postId);
//       return true;
//     } catch (e) {
//       debugPrint('Error adding comment: $e');
//       return false;
//     }
//   }

//   Future<bool> deleteComment(String commentId, String postId) async {
//     try {
//       await _db.deleteCommentInFirebase(commentId);
//       await loadComments(postId);
//       return true;
//     } catch (e) {
//       debugPrint('Error deleting comment: $e');
//       return false;
//     }
//   }

//   Future<void> toggleLikeComment(
//       String postId, String commentId, String userId) async {
//     final list = _comments[postId];
//     if (list == null) return;
//     final idx = list.indexWhere((c) => c.id == commentId);
//     if (idx == -1) return;

//     final c = list[idx];
//     final alreadyLiked = c.likedBy.contains(userId);

//     final updatedLikedBy = alreadyLiked
//         ? (List<String>.from(c.likedBy)..remove(userId))
//         : (List<String>.from(c.likedBy)..add(userId));

//     final updatedComment = Comment(
//       id: c.id,
//       postId: c.postId,
//       uid: c.uid,
//       name: c.name,
//       username: c.username,
//       message: c.message,
//       timestamp: c.timestamp,
//       commentLikeCount:
//           alreadyLiked ? c.commentLikeCount - 1 : c.commentLikeCount + 1,
//       likedBy: updatedLikedBy,
//       commentReplyCount: c.commentReplyCount,
//       isPinned: c.isPinned,
//     );

//     list[idx] = updatedComment;
//     notifyListeners();

//     try {
//       await _db.updateCommentLikesInFirebase(
//           commentId, updatedComment.commentLikeCount, updatedLikedBy);
//     } catch (e) {
//       debugPrint('Error liking comment: $e');
//     }
//   }

//   Future<void> togglePinComment({
//     required String postId,
//     required String commentId,
//     required bool newPinState,
//   }) async {
//     try {
//       await _db.setPinComment(
//           postId: postId, commentId: commentId, pin: newPinState);
//       await loadComments(postId);
//     } catch (e) {
//       debugPrint('Error pinning comment: $e');
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // REPLIES
//   // ---------------------------------------------------------------------------

//   final Map<String, List<Comment>> _commentReplies = {};

//   List<Comment> getCommentReplies(String commentId) =>
//       _commentReplies[commentId] ?? [];

//   Future<void> loadCommentReplies(String commentId) async {
//     try {
//       _commentReplies[commentId] =
//           await _db.getCommentRepliesFromFirebase(commentId);
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error loading replies: $e');
//     }
//   }

//   Future<bool> addCommentReply(String commentId, String message) async {
//     final uid = _auth.getCurrentUid();
//     if (uid == null) return false;
//     try {
//       await _db.addCommentReplyInFirebase(commentId, message);
//       await loadCommentReplies(commentId);
//       return true;
//     } catch (e) {
//       debugPrint('Error adding reply: $e');
//       return false;
//     }
//   }

//   Future<bool> deleteCommentReply(String commentId, String replyId) async {
//     try {
//       await _db.deleteCommentReplyInFirebase(commentId, replyId);
//       await loadCommentReplies(commentId);
//       return true;
//     } catch (e) {
//       debugPrint('Error deleting reply: $e');
//       return false;
//     }
//   }

//   Future<void> toggleLikeCommentReply(
//       String commentId, String replyId, String userId) async {
//     final list = _commentReplies[commentId];
//     if (list == null) return;
//     final idx = list.indexWhere((r) => r.id == replyId);
//     if (idx == -1) return;

//     final r = list[idx];
//     final alreadyLiked = r.likedBy.contains(userId);

//     final updatedLikedBy = alreadyLiked
//         ? (List<String>.from(r.likedBy)..remove(userId))
//         : (List<String>.from(r.likedBy)..add(userId));

//     final updatedReply = Comment(
//       id: r.id,
//       postId: r.postId,
//       uid: r.uid,
//       name: r.name,
//       username: r.username,
//       message: r.message,
//       timestamp: r.timestamp,
//       commentLikeCount:
//           alreadyLiked ? r.commentLikeCount - 1 : r.commentLikeCount + 1,
//       likedBy: updatedLikedBy,
//       commentReplyCount: r.commentReplyCount,
//       isPinned: r.isPinned,
//     );

//     list[idx] = updatedReply;
//     notifyListeners();

//     try {
//       await _db.updateCommentReplyLikesInFirebase(
//           commentId, replyId, updatedReply.commentLikeCount, updatedLikedBy);
//     } catch (e) {
//       debugPrint('Error liking reply: $e');
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // REAL-TIME STREAMS
//   // ---------------------------------------------------------------------------

//   Stream<List<Post>> postsStream() {
//     return _firestore
//         .collection("Posts")
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .map((s) => s.docs.map((d) => Post.fromDocument(d)).toList());
//   }

//   void startListeningToPosts() {
//     postsStream().listen((posts) {
//       _allPosts = posts;
//       initializeLikeMap();
//       notifyListeners();
//     });
//   }

//   Stream<List<Comment>> commentsStream(String postId) {
//     return _firestore
//         .collection("Comments")
//         .where("postId", isEqualTo: postId)
//         .orderBy("isPinned", descending: true)
//         .orderBy("timestamp", descending: true)
//         .snapshots()
//         .map((s) => s.docs.map((d) => Comment.fromDocument(d)).toList());
//   }

//   void listenToComments(String postId) {
//     _commentsSubs[postId]?.cancel();
//     _commentsSubs[postId] = commentsStream(postId).listen((comments) {
//       _comments[postId] = comments;
//       notifyListeners();
//     });
//   }

//   Stream<List<Comment>> commentRepliesStream(String commentId) {
//     return _firestore
//         .collection("Comments")
//         .doc(commentId)
//         .collection("CommentReply")
//         .orderBy("timestamp", descending: true)
//         .snapshots()
//         .map((s) => s.docs.map((d) => Comment.fromDocument(d)).toList());
//   }

//   void listenToReplies(String commentId) {
//     _repliesSubs[commentId]?.cancel();
//     _repliesSubs[commentId] =
//         commentRepliesStream(commentId).listen((replies) {
//       _commentReplies[commentId] = replies;
//       notifyListeners();
//     });
//   }
// }












/*

/*
DATABASE PROVIDER

This provider is to seperate the firebase data handelling and the ui of app

- The database service class handles data to and from firebase
- The database provider class processes the data to display in our app
- This is to make the code clear and easy to understand


-------- EASY TO CHANGE THE DATA FROM FIREBASE TO ELSE
 */


import 'package:flutter/material.dart';
import 'package:social_media/models/comment.dart';
import 'package:social_media/models/post.dart';
import 'package:social_media/models/user.dart';
import 'package:social_media/services/auth/auth_service.dart';
import 'package:social_media/services/database/database_service.dart';

class DatabaseProvider extends ChangeNotifier{
  
  // SERVICES

  // get db and auth services
  final _db = DatabaseService();
  final _auth = AuthService();

  // USER PROFILE

  // get user profile given uid
  Future<UserProfile?> userProfile(String uid) => _db.getUserFromFirebase(uid);

  // update the user bio
  Future<void> updateBio(String bio) => _db.updateUserBioInFirebase(bio);

  /*
  
  POSTS

   */

  // local list of posts
  List<Post> _allPosts = [];

  // get post
  List<Post> get allPosts => _allPosts;

  // post message
  Future<void> postMessage(String message) async {
    // post message in firebase
    await _db.postMessageInFirebase(message);  
    }

    // Fetch all posts
    Future<void> loadAllPosts() async {
      // get all posts from firebase
      final allPosts = await _db.getAllPostsFromFirebse();

      // update local data
      _allPosts = allPosts;

      // initialize local like data
      initializeLikeMap();

      // update UI
      notifyListeners();
    }


  // filter and return posts given uid
  List<Post> filterUserPosts(String uid) {
    return _allPosts.where((post) => post.uid == uid).toList();
  }

  // delete post
  Future<void> deletePost(String postId) async {
    // delete from firebase
    await _db.deletePostFromFirebase(postId);

    // reload from firebase
    await loadAllPosts();
  }



  /*
  
  LIKES

   */
   

  // local map to track like count for each post
  Map<String, int> _likeCounts = {
    // for each post id: like count
  };

  // local list to track post liked by current user
  List<String> _likedPosts = [];

  // does current user like the post?
  bool isPostLikedByCurrentUser(String postId) => _likedPosts.contains(postId);

  // get like count of a post
  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;

  // initialize like map locally 
  
  void initializeLikeMap() {
  final currentUserID = _auth.getCurrentUid();

  _likeCounts.clear();     
  _likedPosts.clear();     

  for (var post in _allPosts) {
    _likeCounts[post.id] = post.likeCount; 
    if (post.likedBy.contains(currentUserID)) {
      _likedPosts.add(post.id);
    }
  }
}


  // toggle like
  Future<void> toggleLike(String postId) async {

    // this first part will update the local values first so that ui feels imediate and responsive

    // store origanal values in case it fails
    final likePostsOrignal = _likedPosts;
    final likeCountsOrignal = _likeCounts;

    // perform like/unlike
  
  if (_likedPosts.contains(postId)) {
  _likedPosts.remove(postId);
  final currentCount = _likeCounts[postId] ?? 0;
  _likeCounts[postId] = currentCount > 0 ? currentCount - 1 : 0;
} else {
  _likedPosts.add(postId);
  _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
}

  // update UI locally
  notifyListeners();

  // Now lets try to update it in our database

    // attempt like in database
    try {
      await _db.toggleLikeInFirebase(postId);
    }
    
    // revert back to initial state if update fails 
    catch (e) {
      _likedPosts = likePostsOrignal;
      _likeCounts = likeCountsOrignal;

      // update ui again
      notifyListeners();
    }
}

  /*

  COMMENTS

  {
  
  postId1: [ comment1, comment2, .. ],
  postId2: [ comment1, comment2, .. ],
  postId3: [ comment1, comment2, .. ],

  }

  */

  // ------------------ COMMENTS ------------------

// Local cache: Map<postId, List<Comment>>
final Map<String, List<Comment>> _comments = {};

// Get comments for a post from local cache
List<Comment> getComments(String postId) => _comments[postId] ?? [];

// Load comments from Firestore, pinned first, then newest
Future<void> loadComments(String postId) async {
  try {
    // getCommentsFromFirebase already sorts pinned first, then by time
    final allComments = await _db.getCommentsFromFirebase(postId);
    _comments[postId] = allComments;
    notifyListeners();
  } catch (e) {
    print('Error loading comments: $e');
  }
}

// Add a comment
Future<void> addComment(String postId, String message) async {
  await _db.addCommentInFirebase(postId, message);
  await loadComments(postId);
}

// Delete a comment
Future<void> deleteComment(String commentId, String postId) async {
  await _db.deleteCommentInFirebase(commentId);
  await loadComments(postId);
}

// Toggle like/unlike a comment
Future<void> toggleLikeComment(String postId, String commentId, String userId) async {
  final commentList = _comments[postId];
  if (commentList == null) return;

  final commentIndex = commentList.indexWhere((c) => c.id == commentId);
  if (commentIndex == -1) return;

  final comment = commentList[commentIndex];
  final alreadyLiked = comment.likedBy.contains(userId);

  // Update likedBy list locally
  final updatedLikedBy = alreadyLiked
      ? (List<String>.from(comment.likedBy)..remove(userId))
      : (List<String>.from(comment.likedBy)..add(userId));

  // Update like count locally
  final updatedLikeCount = alreadyLiked
      ? (comment.commentLikeCount - 1).clamp(0, 999999)
      : comment.commentLikeCount + 1;

  // Create updated comment object
  final updatedComment = Comment(
    id: comment.id,
    postId: comment.postId,
    uid: comment.uid,
    name: comment.name,
    username: comment.username,
    message: comment.message,
    timestamp: comment.timestamp,
    commentLikeCount: updatedLikeCount,
    likedBy: updatedLikedBy,
  );

  // Update local cache
  _comments[postId]![commentIndex] = updatedComment;
  notifyListeners();

  // Update Firestore
  await _db.updateCommentLikesInFirebase(commentId, updatedLikeCount, updatedLikedBy);
}

// Toggle pin/unpin comment (only post owner allowed)
Future<void> togglePinComment({
  required String postId,
  required String commentId,
  required bool newPinState,
}) async {
  try {
    await _db.setPinComment(
      postId: postId,
      commentId: commentId,
      pin: newPinState,
    );
    await loadComments(postId);
  } catch (e) {
    print('Error toggling pin comment: $e');
  }
}



//   // local list of comments
//   final Map<String, List<Comment>> _comments = {};

//   // get comments locally
//   List<Comment> getComments(String postId) => _comments[postId] ?? [];

//   // fetch comments from database for a post
//   Future<void> loadComments(String postId) async {
      
//       // get all comments for this post
//       final allComments = await _db.getCommentsFromFirebase(postId);

//       // update local data
//       _comments[postId] = allComments;

//       // update UI
//       notifyListeners(); 
//   } 

//   // add a comment
//   Future<void> addComment(String postId, message) async {

//       // add comments in firebase
//       await _db.addCommentInFirebase(postId, message);
      
//       // reload comments 
//       await loadComments(postId);
//   }

//   // delete comment
//   Future<void> deleteComment(String commentId, postId) async {
    
//     // delete comment in firebase
//     await _db.deleteCommentInFirebase(commentId);

//     // reload comment 
//     await loadComments(postId);
//   }

//   // toggle like on a comment
// Future<void> toggleLikeComment(
//   String postId,
//   String commentId,
//   String userId,
// ) async {
//   final commentList = _comments[postId];
//   if (commentList == null) return;

//   final commentIndex = commentList.indexWhere((c) => c.id == commentId);
//   if (commentIndex == -1) return;

//   final comment = commentList[commentIndex];
//   final alreadyLiked = comment.likedBy.contains(userId);

//   // Update likedBy list locally
//   final updatedLikedBy = alreadyLiked
//       ? (List<String>.from(comment.likedBy)..remove(userId))
//       : (List<String>.from(comment.likedBy)..add(userId));

//   // Update like count locally
//   final updatedLikeCount = alreadyLiked
//       ? (comment.commentLikeCount - 1).clamp(0, 999999)
//       : comment.commentLikeCount + 1;

//   // Create updated comment object
//   final updatedComment = Comment(
//     id: comment.id,
//     postId: comment.postId,
//     uid: comment.uid,
//     name: comment.name,
//     username: comment.username,
//     message: comment.message,
//     timestamp: comment.timestamp,
//     commentLikeCount: updatedLikeCount,
//     likedBy: updatedLikedBy,
//   );

//   // Update local cache
//   _comments[postId]![commentIndex] = updatedComment;
//   notifyListeners();

//   // Update in Firebase via service
//   await _db.updateCommentLikesInFirebase(
//     commentId,
//     updatedLikeCount,
//     updatedLikedBy,
//   );
// }

/// COMMENT REPLIES CACHE
  // Map of commentId to list of replies
  final Map<String, List<Comment>> _commentReplies = {};
  List<Comment> getCommentReplies(String commentId) => _commentReplies[commentId] ?? [];

  // Load replies from Firebase for a comment and cache locally
  Future<void> loadCommentReplies(String commentId) async {
    final replies = await _db.getCommentRepliesFromFirebase(commentId);
    _commentReplies[commentId] = replies;
    notifyListeners();
  }

  // Add a reply to a comment and reload
  Future<void> addCommentReply(String commentId, String message) async {
    await _db.addCommentReplyInFirebase(commentId, message);
    await loadCommentReplies(commentId);
  }

  // Delete a reply and reload replies list
  Future<void> deleteCommentReply(String commentId, String replyId) async {
    await _db.deleteCommentReplyInFirebase(commentId, replyId);
    await loadCommentReplies(commentId);
  }

  // Toggle like on a comment reply, update local cache and Firebase
  Future<void> toggleLikeCommentReply(String commentId, String replyId, String userId) async {
  final replyList = _commentReplies[commentId];
  if (replyList == null) return;

  final replyIndex = replyList.indexWhere((r) => r.id == replyId);
  if (replyIndex == -1) return;

  final reply = replyList[replyIndex];
  final alreadyLiked = reply.likedBy.contains(userId);

  final updatedLikedBy = alreadyLiked
      ? (List<String>.from(reply.likedBy)..remove(userId))
      : (List<String>.from(reply.likedBy)..add(userId));

  final updatedLikeCount = alreadyLiked
      ? (reply.commentLikeCount - 1).clamp(0, 999999)
      : reply.commentLikeCount + 1;

  final updatedReply = Comment(
    id: reply.id,
    postId: reply.postId,
    uid: reply.uid,
    name: reply.name,
    username: reply.username,
    message: reply.message,
    timestamp: reply.timestamp,
    commentLikeCount: updatedLikeCount,
    likedBy: updatedLikedBy,
  );

  _commentReplies[commentId]![replyIndex] = updatedReply;
  notifyListeners();

  // Call updated method with commentId and replyId
  await _db.updateCommentReplyLikesInFirebase(
    commentId,
    replyId,
    updatedLikeCount,
    updatedLikedBy,
  );
}


}


*/