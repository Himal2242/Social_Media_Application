import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:provider/provider.dart';
import 'package:social_media/Components/brick/glass_notification.dart';
import 'package:social_media/Components/my_comment_tile.dart';
import 'package:social_media/helper/navigate_page.dart';
import 'package:social_media/models/comment.dart';
import 'package:social_media/models/post.dart';
import 'package:social_media/services/database/database_provider.dart';

class PostPage extends StatefulWidget {
  final Post post;
  const PostPage({super.key, required this.post});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isPosting = false;
  Comment? _replyingTo;
  OverlayEntry? _notificationOverlay;

  @override
  void initState() {
    super.initState();
    _loadCommentsAndReplies();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeNotificationOverlay();
    super.dispose();
  }

  Future<void> _loadCommentsAndReplies() async {
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    await db.loadComments(widget.post.id);
    final comments = db.getComments(widget.post.id);
    await Future.wait(comments.map((c) => db.loadCommentReplies(c.id)));
    setState(() {}); // Only called once at init to load initial data
  }

  void _showNotification(String message) {
    _removeNotificationOverlay();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: MediaQuery.of(context).size.width / 2 - 100,
        width: 200,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: GlassNotificationToast(
              message: message,
              isDark: isDark,
              onDismissed: () => entry.remove(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(entry);
    _notificationOverlay = entry;

    Future.delayed(const Duration(seconds: 2), () {
      _notificationOverlay?.remove();
      _notificationOverlay = null;
    });
  }

  void _removeNotificationOverlay() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  Future<void> _submitCommentOrReply() async {
    if (_isPosting) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    final db = Provider.of<DatabaseProvider>(context, listen: false);

    try {
      if (_replyingTo == null) {
        await db.addComment(widget.post.id, text);
        // HapticFeedback.lightImpact();
        _showNotification("Comment posted");
      } else {
        await db.addCommentReply(_replyingTo!.id, text);
        // HapticFeedback.lightImpact();
        _showNotification("Reply posted");
      }
      _controller.clear();
      _focusNode.unfocus();
      setState(() => _replyingTo = null);
      // Removed reload here for smooth UX
    } catch (_) {
      _showNotification("Failed to post");
    }

    setState(() => _isPosting = false);
  }

  Future<void> _handleDeleteComment(Comment comment) async {
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    await db.deleteComment(comment.id, widget.post.id);
    // HapticFeedback.lightImpact();
    _showNotification("Comment deleted");
    // Removed reload here for smooth UX
  }

  Future<void> _handleDeleteReply(Comment parent, Comment reply) async {
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    await db.deleteCommentReply(parent.id, reply.id);
    // HapticFeedback.lightImpact();
    _showNotification("Reply deleted");
    // Removed reload here for smooth UX
  }

  Future<void> _handleToggleLikeComment(Comment comment) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    HapticFeedback.lightImpact();
    await Provider.of<DatabaseProvider>(context, listen: false)
        .toggleLikeComment(comment.postId, comment.id, uid);
    setState(() {});
  }
}

  Future<void> _handleToggleLikeReply(Comment parent, Comment reply) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    HapticFeedback.lightImpact(); // Trigger immediately on tap
    await Provider.of<DatabaseProvider>(context, listen: false)
        .toggleLikeCommentReply(parent.id, reply.id, uid);
    setState(() {});
  }
}

  Future<void> _handleTogglePinComment(Comment comment) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await Provider.of<DatabaseProvider>(context, listen: false).togglePinComment(
        postId: comment.postId,
        commentId: comment.id,
        newPinState: !comment.isPinned,
      );
      _showNotification(comment.isPinned ? "Unpinned comment" : "Pinned comment");
      // Removed reload here for smooth UX
    }
  }

  void _startReplying(Comment comment) {
    HapticFeedback.selectionClick();
    setState(() => _replyingTo = comment);
    _focusNode.requestFocus();
  }

  void _showActionSheetForComment(Comment comment) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final isOwner = comment.uid == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: Text(comment.isPinned ? "Unpin Comment" : "Pin Comment"),
                onTap: () {
                  Navigator.pop(context);
                  _handleTogglePinComment(comment);
                },
              ),
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Delete"),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeleteComment(comment);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text("Report"),
                onTap: () {
                  Navigator.pop(context);
                  _showNotification("Reported");
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showActionSheetForReply(Comment parent, Comment reply) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final bool isOwner = reply.uid == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Delete"),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeleteReply(parent, reply);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text("Report"),
                onTap: () {
                  Navigator.pop(context);
                  _showNotification("Reported");
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseProvider>(context);
    final comments = db.getComments(widget.post.id);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final colorScheme = Theme.of(context).colorScheme;

    // Sort pinned comments first, then newest first
    comments.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.timestamp.compareTo(a.timestamp);
    });

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! > 10) {
          Navigator.of(context).pop();
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 6,
                  margin: const EdgeInsets.only(top: 16, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                Text(
                  "Comments",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Divider(
                  thickness: 0.5,
                  color: Colors.grey.withOpacity(0.4),
                  indent: 100,
                  endIndent: 100,
                ),
                Expanded(
                  child: comments.isEmpty
                      ? Center(
                          child: Text(
                          "No comments yet...",
                          style: TextStyle(color: Colors.grey[600]),
                        ))
                      : ListView.builder(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final replies = db.getCommentReplies(comment.id);

                            return MyCommentTile(
                              username: comment.username,
                              comment: comment.message,
                              isOwnComment: comment.uid == currentUserId,
                              onLongPress: () => _showActionSheetForComment(comment),
                              isLiked: comment.likedBy.contains(currentUserId),
                              commentLikeCount: comment.commentLikeCount,
                              onLikeToggle: () => _handleToggleLikeComment(comment),
                              replies: replies,
                              onReplyTap: () => _startReplying(comment),
                              onDeleteReply: (reply) =>
                                  _showActionSheetForReply(comment, reply),
                              onLikeReply: (reply) => _handleToggleLikeReply(comment, reply),
                              currentUserId: currentUserId,
                              isPinned: comment.isPinned,
                              timestamp: comment.timestamp.toDate(),
                              onUserTap: () => goUserPage(context, comment.uid),
                            );
                          },
                        ),
                ),
                if (_replyingTo != null)
                  Container(
                    color: colorScheme.surfaceVariant.withOpacity(0.15),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Replying to @${_replyingTo!.username}",
                            style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _replyingTo = null),
                        ),
                      ],
                    ),
                  ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding:
                      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: colorScheme.surface,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              minLines: 1,
                              maxLines: 4,
                              enabled: !_isPosting,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: _replyingTo == null
                                    ? "Add a comment..."
                                    : "Add a reply...",
                                filled: true,
                                fillColor:
                                    colorScheme.surfaceVariant.withOpacity(0.2),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isPosting || _controller.text.trim().isEmpty
                                ? null
                                : _submitCommentOrReply,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.arrow_upward_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}





















// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // For haptic feedback
// import 'package:provider/provider.dart';
// import 'package:social_media/Components/brick/glass_notification.dart';
// import 'package:social_media/Components/my_comment_tile.dart';
// import 'package:social_media/models/comment.dart';
// import 'package:social_media/models/post.dart';
// import 'package:social_media/services/database/database_provider.dart';

// class PostPage extends StatefulWidget {
//   final Post post;
//   const PostPage({super.key, required this.post});

//   @override
//   State<PostPage> createState() => _PostPageState();
// }

// class _PostPageState extends State<PostPage> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();

//   bool _isPosting = false;
//   Comment? _replyingTo;
//   OverlayEntry? _notificationOverlay;

//   @override
//   void initState() {
//     super.initState();
//     _loadCommentsAndReplies();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _focusNode.dispose();
//     _removeNotificationOverlay();
//     super.dispose();
//   }

//   Future<void> _loadCommentsAndReplies() async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     await db.loadComments(widget.post.id);
//     final comments = db.getComments(widget.post.id);
//     await Future.wait(comments.map((c) => db.loadCommentReplies(c.id)));
//   }

//   void _showNotification(String message) {
//     _removeNotificationOverlay();
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     late OverlayEntry entry;
//     entry = OverlayEntry(
//       builder: (context) => Positioned(
//         bottom: 80,
//         left: MediaQuery.of(context).size.width / 2 - 100,
//         width: 200,
//         child: Material(
//           color: Colors.transparent,
//           child: Center(
//             child: GlassNotificationToast(
//               message: message,
//               isDark: isDark,
//               onDismissed: () => entry.remove(),
//             ),
//           ),
//         ),
//       ),
//     );

//     Overlay.of(context)?.insert(entry);
//     _notificationOverlay = entry;

//     Future.delayed(const Duration(seconds: 2), () {
//       _notificationOverlay?.remove();
//       _notificationOverlay = null;
//     });
//   }

//   void _removeNotificationOverlay() {
//     _notificationOverlay?.remove();
//     _notificationOverlay = null;
//   }

//   Future<void> _submitCommentOrReply() async {
//     if (_isPosting) return;
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() => _isPosting = true);
//     final db = Provider.of<DatabaseProvider>(context, listen: false);

//     try {
//       if (_replyingTo == null) {
//         await db.addComment(widget.post.id, text);
//         _showNotification("Comment posted");
//       } else {
//         await db.addCommentReply(_replyingTo!.id, text);
//         _showNotification("Reply posted");
//       }
//       _controller.clear();
//       _focusNode.unfocus();
//       setState(() => _replyingTo = null);
//     } catch (_) {
//       _showNotification("Failed to post");
//     }

//     setState(() => _isPosting = false);
//   }

//   Future<void> _handleDeleteComment(Comment comment) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     await db.deleteComment(comment.id, widget.post.id);
//     _showNotification("Comment deleted");
//   }

//   Future<void> _handleDeleteReply(Comment parent, Comment reply) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     await db.deleteCommentReply(parent.id, reply.id);
//     _showNotification("Reply deleted");
//   }

//   Future<void> _handleToggleLikeComment(Comment comment) async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid != null) {
//       await Provider.of<DatabaseProvider>(context, listen: false)
//           .toggleLikeComment(comment.postId, comment.id, uid);
//     }
//   }

//   Future<void> _handleToggleLikeReply(Comment parent, Comment reply) async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid != null) {
//       await Provider.of<DatabaseProvider>(context, listen: false)
//           .toggleLikeCommentReply(parent.id, reply.id, uid);
//     }
//   }

//   void _startReplying(Comment comment) {
//     HapticFeedback.selectionClick();
//     setState(() => _replyingTo = comment);
//     _focusNode.requestFocus();
//   }

//   void _showActionSheetForComment(Comment comment) {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
//     final isOwner = comment.uid == currentUserId;

//     showModalBottomSheet(
//       context: context,
//       builder: (context) => SafeArea(
//         child: Wrap(
//           children: [
//             if (isOwner)
//               ListTile(
//                 leading: const Icon(Icons.delete),
//                 title: const Text("Delete"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _handleDeleteComment(comment);
//                 },
//               )
//             else
//               ListTile(
//                 leading: const Icon(Icons.flag),
//                 title: const Text("Report"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _showNotification("Reported");
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showActionSheetForReply(Comment parent, Comment reply) {
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
//     final bool isOwner = reply.uid == currentUserId;

//     showModalBottomSheet(
//       context: context,
//       builder: (context) => SafeArea(
//         child: Wrap(
//           children: [
//             if (isOwner)
//               ListTile(
//                 leading: const Icon(Icons.delete),
//                 title: const Text("Delete"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _handleDeleteReply(parent, reply);
//                 },
//               )
//             else
//               ListTile(
//                 leading: const Icon(Icons.flag),
//                 title: const Text("Report"),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _showNotification("Reported");
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final db = Provider.of<DatabaseProvider>(context);
//     final comments = db.getComments(widget.post.id);
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
//     final colorScheme = Theme.of(context).colorScheme;

//     return GestureDetector(
//       onVerticalDragUpdate: (details) {
//         if (details.primaryDelta != null && details.primaryDelta! > 10) {
//           Navigator.of(context).pop();
//         }
//       },
//       child: DraggableScrollableSheet(
//         initialChildSize: 0.95,
//         minChildSize: 0.5,
//         maxChildSize: 0.95,
//         expand: false,
//         builder: (context, scrollController) {
//           return Container(
//             decoration: BoxDecoration(
//               color: Theme.of(context).scaffoldBackgroundColor,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
//             ),
//             child: Column(
//               children: [
//                 Container(
//                   width: 48,
//                   height: 6,
//                   margin: const EdgeInsets.only(top: 16, bottom: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[400],
//                     borderRadius: BorderRadius.circular(100),
//                   ),
//                 ),
//                 Text(
//                   "Comments",
//                   style: Theme.of(context)
//                       .textTheme
//                       .titleMedium
//                       ?.copyWith(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 6),
//                 Divider(
//                   thickness: 0.5,
//                   color: Colors.grey.withOpacity(0.4),
//                   indent: 100,
//                   endIndent: 100,
//                 ),
//                 Expanded(
//                   child: comments.isEmpty
//                       ? Center(
//                           child: Text(
//                           "No comments yet...",
//                           style: TextStyle(color: Colors.grey[600]),
//                         ))
//                       : ListView.builder(
//                           controller: scrollController,
//                           physics: const BouncingScrollPhysics(),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 20, vertical: 10),
//                           itemCount: comments.length,
//                           itemBuilder: (context, index) {
//                             final comment = comments[index];
//                             final replies = db.getCommentReplies(comment.id);

//                             return MyCommentTile(
//                               username: comment.username,
//                               comment: comment.message,
//                               isOwnComment: comment.uid == currentUserId,
//                               onLongPress: () => _showActionSheetForComment(comment),
//                               isLiked: comment.likedBy.contains(currentUserId),
//                               commentLikeCount: comment.commentLikeCount,
//                               onLikeToggle: () => _handleToggleLikeComment(comment),
//                               replies: replies,
//                               onReplyTap: () => _startReplying(comment),
//                               onDeleteReply: (reply) => _showActionSheetForReply(comment, reply),
//                               onLikeReply: (reply) => _handleToggleLikeReply(comment, reply),
//                               currentUserId: currentUserId,
//                             );
//                           },
//                         ),
//                 ),
//                 if (_replyingTo != null)
//                   Container(
//                     color: colorScheme.surfaceVariant.withOpacity(0.15),
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             "Replying to @${_replyingTo!.username}",
//                             style: TextStyle(
//                                 color: colorScheme.primary,
//                                 fontWeight: FontWeight.w500),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close),
//                           onPressed: () => setState(() => _replyingTo = null),
//                         ),
//                       ],
//                     ),
//                   ),
//                 AnimatedPadding(
//                   duration: const Duration(milliseconds: 150),
//                   curve: Curves.easeOut,
//                   padding:
//                       EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//                   child: SafeArea(
//                     top: false,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 10),
//                       color: colorScheme.surface,
//                       child: Row(
//                         children: [
//                           const CircleAvatar(
//                             radius: 18,
//                             backgroundColor: Colors.grey,
//                             child: Icon(Icons.person,
//                                 color: Colors.white, size: 18),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: TextField(
//                               controller: _controller,
//                               focusNode: _focusNode,
//                               minLines: 1,
//                               maxLines: 4,
//                               enabled: !_isPosting,
//                               onChanged: (_) => setState(() {}),
//                               decoration: InputDecoration(
//                                 hintText: _replyingTo == null
//                                     ? "Add a comment..."
//                                     : "Add a reply...",
//                                 filled: true,
//                                 fillColor:
//                                     colorScheme.surfaceVariant.withOpacity(0.2),
//                                 contentPadding: const EdgeInsets.symmetric(
//                                     vertical: 10, horizontal: 14),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(16),
//                                   borderSide: BorderSide.none,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           InkWell(
//                             borderRadius: BorderRadius.circular(12),
//                             onTap: _isPosting || _controller.text.trim().isEmpty
//                                 ? null
//                                 : _submitCommentOrReply,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.deepPurple,
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               padding: const EdgeInsets.all(8),
//                               child: const Icon(Icons.arrow_upward_rounded,
//                                   color: Colors.white, size: 22),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }








// import 'dart:ui';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // For haptics
// import 'package:provider/provider.dart';
// import 'package:social_media/Components/my_comment_tile.dart';
// import 'package:social_media/models/post.dart';
// import 'package:social_media/models/comment.dart';
// import 'package:social_media/services/database/database_provider.dart';

// class PostPage extends StatefulWidget {
//   final Post post;
//   const PostPage({super.key, required this.post});

//   @override
//   State<PostPage> createState() => _PostPageState();
// }

// class _PostPageState extends State<PostPage> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();

//   bool _isPosting = false;
//   OverlayEntry? _notificationOverlay;

//   Comment? _replyingTo; // Stores the comment or reply we're replying to

//   @override
//   void dispose() {
//     _controller.dispose();
//     _focusNode.dispose();
//     _removeNotificationOverlay();
//     super.dispose();
//   }

//   /// Glass toast notification
//   void _showNotification(String message) {
//     _removeNotificationOverlay();
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     _notificationOverlay = OverlayEntry(
//       builder: (context) => _GlassNotification(
//         message: message,
//         isDark: isDark,
//         onDismissed: _removeNotificationOverlay,
//       ),
//     );

//     // Added 1 second delay before showing notification
//     Future.delayed(const Duration(seconds: 1), () {
//       if (mounted && _notificationOverlay != null) {
//         Overlay.of(context)?.insert(_notificationOverlay!);
//       }
//     });
//   }

//   void _removeNotificationOverlay() {
//     _notificationOverlay?.remove();
//     _notificationOverlay = null;
//   }

//   Future<void> _submitCommentOrReply() async {
//     if (_isPosting) return;
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() => _isPosting = true);

//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     try {
//       if (_replyingTo == null) {
//         await db.addComment(widget.post.id, text);
//         _showNotification("Comment posted");
//       } else {
//         await db.addCommentReply(_replyingTo!.id, text);
//         _showNotification("Reply posted");
//       }
//       _controller.clear();
//       _focusNode.unfocus();
//       setState(() => _replyingTo = null);
//     } catch (_) {
//       _showNotification("Failed to post");
//     }
//     setState(() => _isPosting = false);
//   }

//   Future<void> _handleDeleteComment(Comment comment) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     try {
//       await db.deleteComment(comment.id, widget.post.id);
//       _showNotification("Comment deleted");
//     } catch (_) {
//       _showNotification("Failed to delete comment");
//     }
//   }

//   Future<void> _handleDeleteReply(String parentCommentId, Comment reply) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     try {
//       await db.deleteCommentReply(parentCommentId, reply.id);
//       _showNotification("Reply deleted");
//     } catch (_) {
//       _showNotification("Failed to delete reply");
//     }
//   }

//   Future<void> _handleToggleLikeComment(Comment comment) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;
//     await db.toggleLikeComment(comment.postId, comment.id, uid);
//   }

//   Future<void> _handleToggleLikeReply(String parentCommentId, Comment reply) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;
//     await db.toggleLikeCommentReply(parentCommentId, reply.id, uid);
//   }

//   void _startReplying(Comment comment) {
//     HapticFeedback.selectionClick();
//     setState(() => _replyingTo = comment);
//     _focusNode.requestFocus();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final db = Provider.of<DatabaseProvider>(context);
//     final comments = db.getComments(widget.post.id);
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;
//     final colorScheme = Theme.of(context).colorScheme;

//     return GestureDetector(
//       onVerticalDragUpdate: (details) {
//         if (details.primaryDelta != null && details.primaryDelta! > 10) {
//           Navigator.of(context).pop();
//         }
//       },
//       child: DraggableScrollableSheet(
//         initialChildSize: 0.95,
//         minChildSize: 0.5,
//         maxChildSize: 0.95,
//         expand: false,
//         builder: (context, scrollController) {
//           return Container(
//             decoration: BoxDecoration(
//               color: Theme.of(context).scaffoldBackgroundColor,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
//               boxShadow: const [
//                 BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -4))
//               ],
//             ),
//             clipBehavior: Clip.antiAlias,
//             child: Column(
//               children: [
//                 /// Handle bar
//                 Container(
//                   width: 48,
//                   height: 6,
//                   margin: const EdgeInsets.only(top: 16, bottom: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[400],
//                     borderRadius: BorderRadius.circular(100),
//                   ),
//                 ),

//                 Text(
//                   "Comments",
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 6),

//                 /// Subtle single divider
//                 Divider(
//                   thickness: 0.5,
//                   color: Colors.grey.withOpacity(0.4),
//                   indent: 100,
//                   endIndent: 100,
//                 ),

//                 /// Comment list
//                 Expanded(
//                   child: comments.isEmpty
//                       ? Center(
//                           child: Text(
//                             "No comments yet...",
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                         )
//                       : ListView.builder(
//                           controller: scrollController,
//                           physics: const BouncingScrollPhysics(),
//                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                           itemCount: comments.length,
//                           itemBuilder: (context, index) {
//   final comment = comments[index];
//   final replies = db.getCommentReplies(comment.id);

//   return MyCommentTile(
//     commentId: comment.id,
//     postId: comment.postId,
//     uid: comment.uid,
//     name: comment.name,
//     username: comment.username,
//     message: comment.message,
//     isOwner: comment.uid == currentUserId,
//     isReply: false,
//     isLiked: comment.likedBy.contains(currentUserId),
//     replies: replies,
//     showReplies: true, // or false if you want replies collapsed initially
//     onLike: () => _handleToggleLikeComment(comment),
//     onReply: () => _startReplying(comment),
//     onLongPress: () => _handleDeleteComment(comment),
//     onToggleReplies: () {
//       // toggle replies visibility if supported
//     },
//     // onDeleteReply: (reply) => _handleDeleteReply(comment.id, reply),
//     // onLikeReply: (reply) => _handleToggleLikeReply(comment.id, reply),
//     // currentUserId: currentUserId ?? "",
//   );
// }

//                         ),
//                 ),

//                 /// Reply banner
//                 if (_replyingTo != null)
//                   Container(
//                     color: colorScheme.surfaceVariant.withOpacity(0.15),
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             "Replying to @${_replyingTo!.username}",
//                             style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close),
//                           onPressed: () => setState(() => _replyingTo = null),
//                         ),
//                       ],
//                     ),
//                   ),

//                 /// Input field
//                 AnimatedPadding(
//                   duration: const Duration(milliseconds: 150),
//                   curve: Curves.easeOut,
//                   padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//                   child: SafeArea(
//                     top: false,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                       decoration: BoxDecoration(
//                         border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
//                         color: colorScheme.surface,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 6,
//                             offset: const Offset(0, -2),
//                           )
//                         ],
//                       ),
//                       child: Row(
//                         children: [
//                           const CircleAvatar(
//                             radius: 18,
//                             backgroundColor: Colors.grey,
//                             child: Icon(Icons.person, color: Colors.white, size: 18),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: TextField(
//                               controller: _controller,
//                               focusNode: _focusNode,
//                               minLines: 1,
//                               maxLines: 4,
//                               enabled: !_isPosting,
//                               onChanged: (_) => setState(() {}),
//                               style: TextStyle(color: colorScheme.onSurface),
//                               decoration: InputDecoration(
//                                 hintText: _replyingTo == null ? "Add a comment..." : "Add a reply...",
//                                 hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
//                                 filled: true,
//                                 fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
//                                 contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(16),
//                                   borderSide: BorderSide.none,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           InkWell(
//                             borderRadius: BorderRadius.circular(12),
//                             onTap: _isPosting || _controller.text.trim().isEmpty
//                                 ? null
//                                 : _submitCommentOrReply,
//                             child: AnimatedSwitcher(
//                               duration: const Duration(milliseconds: 200),
//                               transitionBuilder: (child, animation) =>
//                                   ScaleTransition(scale: animation, child: child),
//                               child: _controller.text.trim().isEmpty
//                                   ? Icon(Icons.emoji_emotions_outlined,
//                                       key: const ValueKey("emoji"),
//                                       color: colorScheme.primary)
//                                   : Container(
//                                       key: const ValueKey("send"),
//                                       decoration: BoxDecoration(
//                                         color: Colors.deepPurple,
//                                         borderRadius: BorderRadius.circular(12),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: Colors.deepPurple.withOpacity(0.5),
//                                             blurRadius: 6,
//                                             offset: const Offset(0, 2),
//                                           ),
//                                         ],
//                                       ),
//                                       padding: const EdgeInsets.all(8),
//                                       child: const Icon(Icons.arrow_upward_rounded,
//                                           color: Colors.white, size: 22),
//                                     ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// /// Glass notification widget with fade in/out
// class _GlassNotification extends StatefulWidget {
//   final String message;
//   final bool isDark;
//   final VoidCallback onDismissed;

//   const _GlassNotification({
//     required this.message,
//     required this.isDark,
//     required this.onDismissed,
//   });

//   @override
//   State<_GlassNotification> createState() => _GlassNotificationState();
// }

// class _GlassNotificationState extends State<_GlassNotification>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _opacity;

//   @override
//   void initState() {
//     super.initState();
//     _controller =
//         AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
//     _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
//     _controller.forward();
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) _controller.reverse().then((_) => widget.onDismissed());
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 100;
//     return Positioned(
//       bottom: bottomPadding,
//       left: 20,
//       right: 20,
//       child: FadeTransition(
//         opacity: _opacity,
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//               decoration: BoxDecoration(
//                 color: widget.isDark
//                     ? Colors.white.withOpacity(0.1)
//                     : Colors.grey.withOpacity(0.25),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.15),
//                     blurRadius: 12,
//                     offset: const Offset(0, 4),
//                   )
//                 ],
//               ),
//               child: Text(
//                 widget.message,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: widget.isDark ? Colors.white : Colors.black87,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 15,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }



// import 'dart:ui';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // For haptics
// import 'package:provider/provider.dart';
// import 'package:social_media/Components/my_comment_tile.dart';
// import 'package:social_media/models/post.dart';
// import 'package:social_media/models/comment.dart';
// import 'package:social_media/services/database/database_provider.dart';

// class PostPage extends StatefulWidget {
//   final Post post;
//   const PostPage({super.key, required this.post});

//   @override
//   State<PostPage> createState() => _PostPageState();
// }

// class _PostPageState extends State<PostPage> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();

//   bool _isPosting = false;
//   OverlayEntry? _notificationOverlay;

//   Comment? _replyingTo; // Stores the comment or reply we’re replying to

//   @override
//   void dispose() {
//     _controller.dispose();
//     _focusNode.dispose();
//     _removeNotificationOverlay();
//     super.dispose();
//   }

//   /// Glass toast notification
//   void _showNotification(String message) {
//     _removeNotificationOverlay();
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     _notificationOverlay = OverlayEntry(
//       builder: (context) => _GlassNotification(
//         message: message,
//         isDark: isDark,
//         onDismissed: _removeNotificationOverlay,
//       ),
//     );

//     /// Added 1 second delay before showing
//     Future.delayed(const Duration(seconds: 1), () {
//       if (mounted) {
//         Overlay.of(context)?.insert(_notificationOverlay!);
//       }
//     });
//   }

//   void _removeNotificationOverlay() {
//     _notificationOverlay?.remove();
//     _notificationOverlay = null;
//   }

//   Future<void> _submitCommentOrReply() async {
//     if (_isPosting) return;
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() => _isPosting = true);

//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     try {
//       if (_replyingTo == null) {
//         await db.addComment(widget.post.id, text);
//         _showNotification("Comment posted");
//       } else {
//         await db.addCommentReply(_replyingTo!.id, text);
//         _showNotification("Reply posted");
//       }
//       _controller.clear();
//       _focusNode.unfocus();
//       setState(() => _replyingTo = null);
//     } catch (_) {
//       // handle error
//     }
//     setState(() => _isPosting = false);
//   }

//   Future<void> _handleDeleteComment(Comment comment) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     await db.deleteComment(comment.id, widget.post.id);
//     _showNotification("Comment deleted");
//   }

//   Future<void> _handleDeleteReply(String parentCommentId, Comment reply) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     await db.deleteCommentReply(parentCommentId, reply.id);
//     _showNotification("Reply deleted");
//   }

//   Future<void> _handleToggleLikeComment(Comment comment) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;
//     await db.toggleLikeComment(comment.postId, comment.id, uid);
//   }

//   Future<void> _handleToggleLikeReply(String parentCommentId, Comment reply) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) return;
//     await db.toggleLikeCommentReply(parentCommentId, reply.id, uid);
//   }

//   void _startReplying(Comment comment) {
//     HapticFeedback.selectionClick();
//     setState(() => _replyingTo = comment);
//     _focusNode.requestFocus();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final db = Provider.of<DatabaseProvider>(context);
//     final comments = db.getComments(widget.post.id);
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;
//     final colorScheme = Theme.of(context).colorScheme;

//     return GestureDetector(
//       onVerticalDragUpdate: (details) {
//         if (details.primaryDelta != null && details.primaryDelta! > 10) {
//           Navigator.of(context).pop();
//         }
//       },
//       child: DraggableScrollableSheet(
//         initialChildSize: 0.95,
//         minChildSize: 0.5,
//         maxChildSize: 0.95,
//         expand: false,
//         builder: (context, scrollController) {
//           return Container(
//             decoration: BoxDecoration(
//               color: Theme.of(context).scaffoldBackgroundColor,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
//               boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -4))],
//             ),
//             clipBehavior: Clip.antiAlias,
//             child: Column(
//               children: [
//                 /// Handle bar
//                 Container(
//                   width: 48,
//                   height: 6,
//                   margin: const EdgeInsets.only(top: 16, bottom: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[400],
//                     borderRadius: BorderRadius.circular(100),
//                   ),
//                 ),

//                 Text(
//                   "Comments",
//                   style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 6),

//                 /// Subtle single divider
//                 Divider(
//                   thickness: 0.5,
//                   color: Colors.grey.withOpacity(0.4),
//                   indent: 100,
//                   endIndent: 100,
//                 ),

//                 /// Comment list
//                 Expanded(
//                   child: comments.isEmpty
//                       ? Center(
//                           child: Text("No comments yet...", style: TextStyle(color: Colors.grey[600])),
//                         )
//                       : ListView.builder(
//                           controller: scrollController,
//                           physics: const BouncingScrollPhysics(),
//                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                           itemCount: comments.length,
//                           itemBuilder: (context, index) {
//                             final comment = comments[index];
//                             final replies = db.getCommentReplies(comment.id);

//                             return MyCommentTile(
//                               username: comment.username,
//                               comment: comment.message,
//                               isOwnComment: comment.uid == currentUserId,
//                               onDelete: () => _handleDeleteComment(comment),
//                               isLiked: comment.likedBy.contains(currentUserId),
//                               commentLikeCount: comment.commentLikeCount,
//                               onLikeToggle: () => _handleToggleLikeComment(comment),
//                               replies: replies,
//                               onReplyTap: () => _startReplying(comment),
//                               onDeleteReply: (reply) => _handleDeleteReply(comment.id, reply),
//                               onLikeReply: (reply) => _handleToggleLikeReply(comment.id, reply),
//                               currentUserId: currentUserId ?? "",
//                             );
//                           },
//                         ),
//                 ),

//                 /// Reply banner
//                 if (_replyingTo != null)
//                   Container(
//                     color: colorScheme.surfaceVariant.withOpacity(0.15),
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             "Replying to @${_replyingTo!.username}",
//                             style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500),
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.close),
//                           onPressed: () => setState(() => _replyingTo = null),
//                         ),
//                       ],
//                     ),
//                   ),

//                 /// Input field
//                 AnimatedPadding(
//                   duration: const Duration(milliseconds: 150),
//                   curve: Curves.easeOut,
//                   padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//                   child: SafeArea(
//                     top: false,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                       decoration: BoxDecoration(
//                         border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
//                         color: colorScheme.surface,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 6,
//                             offset: const Offset(0, -2),
//                           )
//                         ],
//                       ),
//                       child: Row(
//                         children: [
//                           const CircleAvatar(
//                             radius: 18,
//                             backgroundColor: Colors.grey,
//                             child: Icon(Icons.person, color: Colors.white, size: 18),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: TextField(
//                               controller: _controller,
//                               focusNode: _focusNode,
//                               minLines: 1,
//                               maxLines: 4,
//                               enabled: !_isPosting,
//                               onChanged: (_) => setState(() {}),
//                               style: TextStyle(color: colorScheme.onSurface),
//                               decoration: InputDecoration(
//                                 hintText: _replyingTo == null ? "Add a comment..." : "Add a reply...",
//                                 hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
//                                 filled: true,
//                                 fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
//                                 contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(16),
//                                   borderSide: BorderSide.none,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           InkWell(
//                             borderRadius: BorderRadius.circular(12),
//                             onTap: _isPosting || _controller.text.trim().isEmpty
//                                 ? null
//                                 : _submitCommentOrReply,
//                             child: AnimatedSwitcher(
//                               duration: const Duration(milliseconds: 200),
//                               transitionBuilder: (child, animation) =>
//                                   ScaleTransition(scale: animation, child: child),
//                               child: _controller.text.trim().isEmpty
//                                   ? Icon(Icons.emoji_emotions_outlined,
//                                       key: const ValueKey("emoji"),
//                                       color: colorScheme.primary)
//                                   : Container(
//                                       key: const ValueKey("send"),
//                                       decoration: BoxDecoration(
//                                         color: Colors.deepPurple,
//                                         borderRadius: BorderRadius.circular(12),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color: Colors.deepPurple.withOpacity(0.5),
//                                             blurRadius: 6,
//                                             offset: const Offset(0, 2),
//                                           ),
//                                         ],
//                                       ),
//                                       padding: const EdgeInsets.all(8),
//                                       child: const Icon(Icons.arrow_upward_rounded,
//                                           color: Colors.white, size: 22),
//                                     ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// /// Glass notification widget with fade in/out
// class _GlassNotification extends StatefulWidget {
//   final String message;
//   final bool isDark;
//   final VoidCallback onDismissed;

//   const _GlassNotification({
//     required this.message,
//     required this.isDark,
//     required this.onDismissed,
//   });

//   @override
//   State<_GlassNotification> createState() => _GlassNotificationState();
// }

// class _GlassNotificationState extends State<_GlassNotification>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _opacity;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
//     _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
//     _controller.forward();
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) _controller.reverse().then((_) => widget.onDismissed());
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 100;
//     return Positioned(
//       bottom: bottomPadding,
//       left: 20,
//       right: 20,
//       child: FadeTransition(
//         opacity: _opacity,
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//               decoration: BoxDecoration(
//                 color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.25),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.15),
//                     blurRadius: 12,
//                     offset: const Offset(0, 4),
//                   )
//                 ],
//               ),
//               child: Text(
//                 widget.message,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: widget.isDark ? Colors.white : Colors.black87,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 15,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }






// import 'dart:ui';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:social_media/Components/my_comment_tile.dart';
// import 'package:social_media/models/post.dart';
// import 'package:social_media/models/comment.dart';
// import 'package:social_media/services/database/database_provider.dart';

// class PostPage extends StatefulWidget {
//   final Post post;
//   const PostPage({super.key, required this.post});

//   @override
//   State<PostPage> createState() => _PostPageState();
// }

// class _PostPageState extends State<PostPage> with TickerProviderStateMixin {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();

//   bool _isPosting = false;
//   OverlayEntry? _notificationOverlay;

//   @override
//   void dispose() {
//     _controller.dispose();
//     _focusNode.dispose();
//     _removeNotificationOverlay();
//     super.dispose();
//   }

//   void _showNotification(String message) {
//     _removeNotificationOverlay();

//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     _notificationOverlay = OverlayEntry(
//       builder: (context) => _GlassNotification(
//         message: message,
//         isDark: isDark,
//         onDismissed: _removeNotificationOverlay,
//       ),
//     );

//     Overlay.of(context)?.insert(_notificationOverlay!);
//   }

//   void _removeNotificationOverlay() {
//     _notificationOverlay?.remove();
//     _notificationOverlay = null;
//   }

//   Future<void> _submitComment() async {
//     if (_isPosting) return;
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() => _isPosting = true);

//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     try {
//       await db.addComment(widget.post.id, text);
//       _controller.clear();
//       _focusNode.unfocus();
//       _showNotification("Comment posted");
//     } catch (_) {
//       // Handle error if needed
//     }
//     setState(() => _isPosting = false);
//   }

//   Future<void> _handleDeleteComment(String commentId) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     try {
//       await db.deleteComment(commentId, widget.post.id);
//       _showNotification("Comment deleted");
//     } catch (_) {
//       // Handle error if needed
//     }
//   }

//   Future<void> _handleToggleLikeComment(Comment comment) async {
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;
//     if (currentUserId == null) return;

//     try {
//       await db.toggleLikeComment(comment.postId, comment.id, currentUserId);
//     } catch (_) {
//       // Handle error if needed
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final db = Provider.of<DatabaseProvider>(context);
//     final comments = db.getComments(widget.post.id);
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;
//     final colorScheme = Theme.of(context).colorScheme;

//     return GestureDetector(
//       onVerticalDragUpdate: (details) {
//         if (details.primaryDelta != null && details.primaryDelta! > 10) {
//           Navigator.of(context).pop();
//         }
//       },
//       child: DraggableScrollableSheet(
//         initialChildSize: 0.95,
//         minChildSize: 0.5,
//         maxChildSize: 0.95,
//         expand: false,
//         builder: (context, scrollController) {
//           return Container(
//             decoration: BoxDecoration(
//               color: Theme.of(context).scaffoldBackgroundColor,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black26,
//                   blurRadius: 12,
//                   offset: Offset(0, -4),
//                 ),
//               ],
//             ),
//             clipBehavior: Clip.antiAlias,
//             child: Material(
//               color: Colors.transparent,
//               child: Column(
//                 children: [
//                   Container(
//                     width: 48,
//                     height: 6,
//                     margin: const EdgeInsets.only(top: 16, bottom: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[400],
//                       borderRadius: BorderRadius.circular(100),
//                     ),
//                   ),
//                   Text(
//                     "Comments",
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                   ),
//                   const SizedBox(height: 6),
//                   Divider(
//                     thickness: 1,
//                     color: Colors.grey[300],
//                     indent: 100,
//                     endIndent: 100,
//                   ),
//                   const SizedBox(height: 10),
//                   Expanded(
//                     child: comments.isEmpty
//                         ? Center(
//                             child: Text(
//                               "No comments yet...",
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .bodyMedium
//                                   ?.copyWith(color: Colors.grey[600]),
//                             ),
//                           )
//                         : ListView.builder(
//                             controller: scrollController,
//                             physics: const BouncingScrollPhysics(),
//                             padding: const EdgeInsets.symmetric(horizontal: 20),
//                             itemCount: comments.length,
//                             itemBuilder: (context, index) {
//                               final comment = comments[index];
//                               return AnimatedSize(
//                                 duration: const Duration(milliseconds: 250),
//                                 child: Padding(
//                                   padding: const EdgeInsets.only(bottom: 12),
//                                   child: MyCommentTile(
//                                     username: comment.username,
//                                     comment: comment.message,
//                                     isOwnComment: comment.uid == currentUserId,
//                                     onDelete: () => _handleDeleteComment(comment.id),
//                                     isLiked: comment.likedBy.contains(currentUserId),
//                                     commentLikeCount: comment.commentLikeCount,
//                                     onLikeToggle: () => _handleToggleLikeComment(comment),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                   ),
//                   AnimatedPadding(
//                     duration: const Duration(milliseconds: 150),
//                     curve: Curves.easeOut,
//                     padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//                     child: SafeArea(
//                       top: false,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                         decoration: BoxDecoration(
//                           border: Border(
//                             top: BorderSide(
//                               color: colorScheme.outline.withOpacity(0.1),
//                             ),
//                           ),
//                           color: colorScheme.surface,
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.05),
//                               blurRadius: 6,
//                               offset: const Offset(0, -2),
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           children: [
//                             const CircleAvatar(
//                               radius: 18,
//                               backgroundColor: Colors.grey,
//                               child: Icon(Icons.person, color: Colors.white, size: 18),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: TextField(
//                                 controller: _controller,
//                                 focusNode: _focusNode,
//                                 minLines: 1,
//                                 maxLines: 4,
//                                 enabled: !_isPosting,
//                                 onChanged: (_) => setState(() {}),
//                                 style: TextStyle(color: colorScheme.onSurface),
//                                 decoration: InputDecoration(
//                                   hintText: "Add a comment...",
//                                   hintStyle: TextStyle(
//                                     color: colorScheme.onSurface.withOpacity(0.5),
//                                   ),
//                                   filled: true,
//                                   fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
//                                   contentPadding: const EdgeInsets.symmetric(
//                                       vertical: 10, horizontal: 14),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(16),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 10),
//                             InkWell(
//                               borderRadius: BorderRadius.circular(12),
//                               onTap: _isPosting || _controller.text.trim().isEmpty
//                                   ? null
//                                   : _submitComment,
//                               child: AnimatedSwitcher(
//                                 duration: const Duration(milliseconds: 200),
//                                 transitionBuilder: (child, animation) =>
//                                     ScaleTransition(scale: animation, child: child),
//                                 child: _controller.text.trim().isEmpty
//                                     ? Icon(Icons.emoji_emotions_outlined,
//                                         key: const ValueKey("emoji"),
//                                         color: colorScheme.primary)
//                                     : Container(
//                                         key: const ValueKey("send"),
//                                         decoration: BoxDecoration(
//                                           color: Colors.deepPurple,
//                                           borderRadius: BorderRadius.circular(12),
//                                           boxShadow: [
//                                             BoxShadow(
//                                               color: Colors.deepPurple.withOpacity(0.5),
//                                               blurRadius: 6,
//                                               offset: const Offset(0, 2),
//                                             ),
//                                           ],
//                                         ),
//                                         padding: const EdgeInsets.all(8),
//                                         child: const Icon(
//                                           Icons.arrow_upward_rounded,
//                                           color: Colors.white,
//                                           size: 22,
//                                         ),
//                                       ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class _GlassNotification extends StatefulWidget {
//   final String message;
//   final bool isDark;
//   final VoidCallback onDismissed;

//   const _GlassNotification({
//     Key? key,
//     required this.message,
//     required this.isDark,
//     required this.onDismissed,
//   }) : super(key: key);

//   @override
//   State<_GlassNotification> createState() => _GlassNotificationState();
// }

// class _GlassNotificationState extends State<_GlassNotification> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _opacity;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

//     _controller.forward();

//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) {
//         _controller.reverse().then((_) {
//           widget.onDismissed();
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 100;

//     return Positioned(
//       bottom: bottomPadding,
//       left: 20,
//       right: 20,
//       child: FadeTransition(
//         opacity: _opacity,
//         child: Material(
//           color: Colors.transparent,
//           child: Center(
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//                   decoration: BoxDecoration(
//                     color: widget.isDark
//                         ? Colors.white.withOpacity(0.1)
//                         : Colors.grey.withOpacity(0.25),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.3),
//                       width: 1.2,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.15),
//                         blurRadius: 12,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Text(
//                     widget.message,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: widget.isDark ? Colors.white : Colors.black87,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                       letterSpacing: 0.3,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }






// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:social_media/Components/my_comment_tile.dart';
// import 'package:social_media/models/post.dart';
// import 'package:social_media/services/database/database_provider.dart';

// class PostPage extends StatefulWidget {
//   final Post post;

//   const PostPage({super.key, required this.post});

//   @override
//   State<PostPage> createState() => _PostPageState();
// }

// class _PostPageState extends State<PostPage> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     // Load comments on page open
//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     db.loadComments(widget.post.id);
//   }

//   void _submitComment() async {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     final db = Provider.of<DatabaseProvider>(context, listen: false);
//     await db.addComment(widget.post.id, text);
//     _controller.clear();
//     setState(() {});
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _focusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final db = Provider.of<DatabaseProvider>(context);
//     final allComments = db.getComments(widget.post.id);
//     final colorScheme = Theme.of(context).colorScheme;
//     final currentUserId = FirebaseAuth.instance.currentUser?.uid;

//     return GestureDetector(
//       onVerticalDragUpdate: (details) {
//         if (details.primaryDelta != null && details.primaryDelta! > 10) {
//           Navigator.of(context).pop(); // Dismiss on swipe down
//         }
//       },
//       child: DraggableScrollableSheet(
//         initialChildSize: 0.95,
//         minChildSize: 0.5,
//         maxChildSize: 0.95,
//         expand: false,
//         builder: (context, scrollController) {
//           return Container(
//             decoration: BoxDecoration(
//               color: Theme.of(context).scaffoldBackgroundColor,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black26,
//                   blurRadius: 12,
//                   spreadRadius: 2,
//                   offset: Offset(0, -4),
//                 ),
//               ],
//             ),
//             clipBehavior: Clip.antiAlias,
//             child: Material(
//               color: Colors.transparent,
//               child: Column(
//                 children: [
//                   // Grab handle
//                   Container(
//                     width: 48,
//                     height: 6,
//                     margin: const EdgeInsets.only(top: 16, bottom: 16),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[400],
//                       borderRadius: BorderRadius.circular(100),
//                     ),
//                   ),

//                   // Title
//                   Text(
//                     "Comments",
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                   ),
//                   const SizedBox(height: 6),

//                   // Divider
//                   Divider(
//                     thickness: 1,
//                     color: Colors.grey[300],
//                     indent: 100,
//                     endIndent: 100,
//                   ),
//                   const SizedBox(height: 12),

//                   // Comment list
//                   Expanded(
//                     child: NotificationListener<ScrollNotification>(
//                       onNotification: (scrollNotification) {
//                         if (scrollNotification.metrics.pixels <= 0 &&
//                             scrollNotification is OverscrollNotification &&
//                             scrollNotification.overscroll < 0) {
//                           Navigator.of(context).pop(); // Dismiss on top pull
//                           return true;
//                         }
//                         return false;
//                       },
//                       child: ScrollConfiguration(
//                         behavior: const _SmoothBounceScroll(),
//                         child: allComments.isEmpty
//                             ? Center(
//                                 child: Text(
//                                   "No comments yet...",
//                                   style: Theme.of(context)
//                                       .textTheme
//                                       .bodyMedium
//                                       ?.copyWith(color: Colors.grey[600]),
//                                 ),
//                               )
//                             : ListView.builder(
//                                 controller: scrollController,
//                                 physics: const BouncingScrollPhysics(),
//                                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                                 itemCount: allComments.length,
//                                 itemBuilder: (context, index) {
//                                   final comment = allComments[index];
//                                   final isOwnComment = comment.uid == currentUserId;

//                                   return Padding(
//                                     padding: const EdgeInsets.only(bottom: 12),
//                                     child: MyCommentTile(
//                                       username: comment.username,
//                                       comment: comment.message,
//                                       isOwnComment: isOwnComment,
//                                       onDelete: () async {
//                                         await db.deleteComment(comment.id, widget.post.id);
//                                       },
//                                     ),
//                                   );
//                                 },
//                               ),
//                       ),
//                     ),
//                   ),

//                   // ⬇️ COMMENT INPUT AREA
//                   Container(
//                     decoration: BoxDecoration(
//                       border: Border(
//                         top: BorderSide(
//                           color: colorScheme.outline.withOpacity(0.2),
//                           width: 0.8,
//                         ),
//                       ),
//                     ),
//                     padding: MediaQuery.of(context).viewInsets +
//                         const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         // Temporary Avatar
//                         const CircleAvatar(
//                           radius: 18,
//                           backgroundColor: Colors.grey,
//                           child: Icon(Icons.person, color: Colors.white, size: 18),
//                         ),
//                         const SizedBox(width: 12),

//                         // Input Field
//                         Expanded(
//                           child: TextField(
//                             controller: _controller,
//                             focusNode: _focusNode,
//                             minLines: 1,
//                             maxLines: 5,
//                             onChanged: (_) => setState(() {}),
//                             style: TextStyle(color: colorScheme.onSurface),
//                             decoration: InputDecoration(
//                               hintText: "Add a comment...",
//                               hintStyle:
//                                   TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
//                               filled: true,
//                               fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
//                               contentPadding: const EdgeInsets.symmetric(
//                                   vertical: 10, horizontal: 14),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                                 borderSide: BorderSide.none,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),

//                         // Emoji / Send button
//                         GestureDetector(
//                           onTap: () {
//                             if (_controller.text.trim().isEmpty) {
//                               FocusScope.of(context).requestFocus(_focusNode);
//                             } else {
//                               _submitComment();
//                             }
//                           },
//                           child: AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 200),
//                             transitionBuilder: (child, animation) =>
//                                 ScaleTransition(scale: animation, child: child),
//                             child: _controller.text.trim().isEmpty
//                                 ? Icon(Icons.emoji_emotions_outlined,
//                                     key: const ValueKey("emoji"),
//                                     color: colorScheme.primary)
//                                 : Icon(Icons.send_rounded,
//                                     key: const ValueKey("send"),
//                                     color: colorScheme.primary),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // Rubber-like scroll physics for iOS-style bounce
// class _SmoothBounceScroll extends ScrollBehavior {
//   const _SmoothBounceScroll();

//   @override
//   Widget buildViewportChrome(
//       BuildContext context, Widget child, AxisDirection axisDirection) {
//     return child;
//   }

//   @override
//   ScrollPhysics getScrollPhysics(BuildContext context) {
//     return const BouncingScrollPhysics();
//   }
// }






