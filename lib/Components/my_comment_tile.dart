import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:social_media/Components/brick/comment_like_animation.dart';
import 'package:social_media/models/comment.dart';

class MyCommentTile extends StatefulWidget {
  final String username;
  final String comment;
  final bool isOwnComment;
  final VoidCallback onLongPress;
  final bool isLiked;
  final int commentLikeCount;
  final VoidCallback onLikeToggle;

  final List<Comment> replies;
  final VoidCallback onReplyTap;
  final void Function(Comment reply) onDeleteReply;
  final void Function(Comment reply) onLikeReply;
  final String currentUserId;

  final String? replyingToUsername;
  final bool isPinned;
  final DateTime timestamp;

  final VoidCallback? onUserTap;

  const MyCommentTile({
    super.key,
    required this.username,
    required this.comment,
    required this.isOwnComment,
    required this.onLongPress,
    required this.isLiked,
    required this.commentLikeCount,
    required this.onLikeToggle,
    this.replies = const [],
    required this.onReplyTap,
    required this.onDeleteReply,
    required this.onLikeReply,
    required this.currentUserId,
    this.replyingToUsername,
    this.isPinned = false,
    required this.timestamp,
    this.onUserTap,
  });

  @override
  State<MyCommentTile> createState() => _MyCommentTileState();
}

class _MyCommentTileState extends State<MyCommentTile> with SingleTickerProviderStateMixin {
  bool _showReplies = false;
  late final AnimationController _animationController;
  late final Animation<double> _repliesHeightFactor;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _repliesHeightFactor = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleReplies() {
    HapticFeedback.selectionClick(); // Haptic on toggle replies (7)
    setState(() => _showReplies = !_showReplies);
    if (_showReplies) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
    return '${(diff.inDays / 365).floor()}y';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    final timeAgo = _timeAgo(widget.timestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onLongPress: () {
            HapticFeedback.vibrate(); // Haptic feedback on long press (7)
            widget.onLongPress();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isPinned
                    ? color.primary.withOpacity(0.15)  // Pin highlight (6)
                    : color.surfaceVariant.withOpacity(0.45),
                borderRadius: BorderRadius.circular(10),
                border: widget.isPinned
                    ? Border.all(color: color.primary, width: 1.2)
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.onUserTap,
                    child: Semantics(
                      label: 'User avatar of ${widget.username}',
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: widget.onUserTap,
                              child: Semantics(
                                button: true,
                                label: 'View profile of ${widget.username}',
                                child: Text(
                                  widget.username,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: color.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeAgo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (widget.isPinned) ...[
                              const SizedBox(width: 10),
                              Transform.rotate(
                                angle: 0.785398, // 45 degrees
                                child: Icon(
                                  Icons.push_pin,
                                  color: color.onSurfaceVariant,
                                  size: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (widget.replyingToUsername != null)
                          GestureDetector(
                            onTap: widget.onUserTap,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '@${widget.replyingToUsername} ',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color.fromARGB(255, 139, 90, 226),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: widget.comment,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            widget.comment,
                            style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                          ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: widget.onReplyTap,
                          child: Semantics(
                            button: true,
                            label: 'Reply to comment by ${widget.username}',
                            child: Text(
                              "Reply",
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: color.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      CommentLikeAnimation(
                        isLiked: widget.isLiked,
                        onTap: widget.onLikeToggle,
                        size: 20,
                        // semanticLabel:
                        //     widget.isLiked ? 'Unlike comment' : 'Like comment', // Accessibility (1)
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.commentLikeCount.toString(),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: color.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // View replies button (10)
          if (widget.replies.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 38, top: 4, bottom: 4),
                child: Semantics(
                  button: true,
                  label: _showReplies
                      ? "Hide replies"
                      : "View replies (${widget.replies.length})",
                  child: GestureDetector(
                    onTap: _toggleReplies,
                    child: Text(
                      _showReplies
                          ? "Hide replies"
                          : "View replies (${widget.replies.length})",
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: color.primary.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ),
            ),

          // Animated replies list (3)
          SizeTransition(
            sizeFactor: _repliesHeightFactor,
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                children: widget.replies
                    .map(
                      (reply) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _buildCommentRow(
                          context,
                          username: reply.username,
                          message: reply.message,
                          isOwn: reply.uid == widget.currentUserId,
                          isLiked: reply.likedBy.contains(widget.currentUserId),
                          likeCount: reply.commentLikeCount,
                          onLike: () => widget.onLikeReply(reply),
                          onReplyTap: widget.onReplyTap,
                          onLongPress: () => widget.onDeleteReply(reply),
                          replyingToUsername: widget.username,
                          isPinned: false,
                          timestamp: reply.timestamp.toDate(),
                          onUserTap: widget.onUserTap,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildCommentRow(
      BuildContext context, {
      required String username,
      required String message,
      required bool isOwn,
      required bool isLiked,
      required int likeCount,
      required VoidCallback onLike,
      required VoidCallback onReplyTap,
      required VoidCallback onLongPress,
      String? replyingToUsername,
      required bool isPinned,
      required DateTime timestamp,
      VoidCallback? onUserTap,
    }) {
      final theme = Theme.of(context);
      final color = theme.colorScheme;

      final timeAgo = _timeAgo(timestamp);

      return InkWell(
        onLongPress: () {
          HapticFeedback.vibrate(); // Haptic on long press (7)
          onLongPress();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isPinned
                ? color.primary.withOpacity(0.15) // Pin highlight (6)
                : color.surfaceVariant.withOpacity(0.45),
            borderRadius: BorderRadius.circular(10),
            border: isPinned ? Border.all(color: color.primary, width: 1.2) : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onUserTap,
                child: Semantics(
                  label: 'User avatar of $username',
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onUserTap,
                          child: Semantics(
                            button: true,
                            label: 'View profile of $username',
                            child: Text(
                              username,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: color.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: color.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (isPinned) ...[
                          const SizedBox(width: 10),
                          Transform.rotate(
                            angle: 0.785398,
                            child: Icon(
                              Icons.push_pin,
                              color: color.onSurfaceVariant,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (replyingToUsername != null)
                      GestureDetector(
                        onTap: onUserTap,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '@$replyingToUsername ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color.fromARGB(255, 139, 90, 226),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: message,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                      ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onReplyTap,
                      child: Semantics(
                        button: true,
                        label: 'Reply to comment by $username',
                        child: Text(
                          "Reply",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: color.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  CommentLikeAnimation(
                    isLiked: isLiked,
                    onTap: onLike,
                    size: 20,
                    // semanticLabel:
                    //     isLiked ? 'Unlike comment' : 'Like comment', // Accessibility (1)
                  ),
                  const SizedBox(height: 2),
                  Text(
                    likeCount.toString(),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: color.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }













// import 'package:flutter/material.dart';
// import 'package:social_media/Components/brick/comment_like_animation.dart';
// import 'package:social_media/models/comment.dart';

// class MyCommentTile extends StatefulWidget {
//   final String username;
//   final String comment;
//   final bool isOwnComment;
//   final VoidCallback onLongPress;
//   final bool isLiked;
//   final int commentLikeCount;
//   final VoidCallback onLikeToggle;

//   final List<Comment> replies;
//   final VoidCallback onReplyTap;
//   final void Function(Comment reply) onDeleteReply;
//   final void Function(Comment reply) onLikeReply;
//   final String currentUserId;

//   const MyCommentTile({
//     super.key,
//     required this.username,
//     required this.comment,
//     required this.isOwnComment,
//     required this.onLongPress,
//     required this.isLiked,
//     required this.commentLikeCount,
//     required this.onLikeToggle,
//     this.replies = const [],
//     required this.onReplyTap,
//     required this.onDeleteReply,
//     required this.onLikeReply,
//     required this.currentUserId,
//   });

//   @override
//   State<MyCommentTile> createState() => _MyCommentTileState();
// }

// class _MyCommentTileState extends State<MyCommentTile> {
//   bool _showReplies = false;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         _buildCommentRow(
//           context,
//           username: widget.username,
//           message: widget.comment,
//           isOwn: widget.isOwnComment,
//           isLiked: widget.isLiked,
//           likeCount: widget.commentLikeCount,
//           onLike: widget.onLikeToggle,
//           onReplyTap: widget.onReplyTap,
//           onLongPress: widget.onLongPress,
//         ),

//         // Toggle "View/Hide replies"
//         if (widget.replies.isNotEmpty)
//           GestureDetector(
//             onTap: () => setState(() => _showReplies = !_showReplies),
//             child: Padding(
//               padding: const EdgeInsets.only(left: 54, top: 4, bottom: 4),
//               child: Text(
//                 _showReplies
//                     ? "Hide replies"
//                     : "View replies (${widget.replies.length})",
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.8),
//                     ),
//               ),
//             ),
//           ),

//         // Replies list
//         if (_showReplies)
//           Padding(
//             padding: const EdgeInsets.only(left: 40),
//             child: Column(
//               children: widget.replies
//                   .map(
//                     (reply) => Padding(
//                       padding: const EdgeInsets.only(top: 6),
//                       child: _buildCommentRow(
//                         context,
//                         username: reply.username,
//                         message: reply.message,
//                         isOwn: reply.uid == widget.currentUserId,
//                         isLiked: reply.likedBy.contains(widget.currentUserId),
//                         likeCount: reply.commentLikeCount,
//                         onLike: () => widget.onLikeReply(reply),
//                         onReplyTap: widget.onReplyTap,
//                         onLongPress: () => widget.onLongPress(),
//                       ),
//                     ),
//                   )
//                   .toList(),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildCommentRow(
//     BuildContext context, {
//     required String username,
//     required String message,
//     required bool isOwn,
//     required bool isLiked,
//     required int likeCount,
//     required VoidCallback onLike,
//     required VoidCallback onReplyTap,
//     required VoidCallback onLongPress,
//   }) {
//     final theme = Theme.of(context);
//     final color = theme.colorScheme;

//     return InkWell(
//       onLongPress: onLongPress,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
//         decoration: BoxDecoration(
//           color: color.surfaceVariant.withOpacity(0.45),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const CircleAvatar(
//               radius: 20,
//               backgroundColor: Colors.grey,
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       // Navigate to user's profile page:
//                       // Replace with your own navigation code
//                       Navigator.pushNamed(context, '/profile', arguments: username);
//                     },
//                     child: Text(username,
//                         style: theme.textTheme.labelLarge
//                             ?.copyWith(fontWeight: FontWeight.w500, color: color.primary)),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(message,
//                       style:
//                           theme.textTheme.bodyMedium?.copyWith(height: 1.3)),
//                   const SizedBox(height: 4),
//                   GestureDetector(
//                     onTap: onReplyTap,
//                     child: Text(
//                       "Reply",
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         fontWeight: FontWeight.w500,
//                         color: color.primary,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Column(
//               children: [
//                 CommentLikeAnimation(
//                   isLiked: isLiked,
//                   onTap: onLike,
//                   size: 20,
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   likeCount.toString(),
//                   style: theme.textTheme.bodySmall
//                       ?.copyWith(color: color.onSurfaceVariant),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:social_media/Components/brick/comment_like_animation.dart';
// import 'package:social_media/models/comment.dart';

// class MyCommentTile extends StatefulWidget {
//   final String username;
//   final String comment;
//   final bool isOwnComment;
//   final VoidCallback onLongPress; // 🔹 Will trigger PostPage logic
//   final bool isLiked;
//   final int commentLikeCount;
//   final VoidCallback onLikeToggle;

//   final List<Comment> replies;
//   final VoidCallback onReplyTap;
//   final void Function(Comment reply) onDeleteReply;
//   final void Function(Comment reply) onLikeReply;
//   final String currentUserId;

//   const MyCommentTile({
//     super.key,
//     required this.username,
//     required this.comment,
//     required this.isOwnComment,
//     required this.onLongPress,
//     required this.isLiked,
//     required this.commentLikeCount,
//     required this.onLikeToggle,
//     this.replies = const [],
//     required this.onReplyTap,
//     required this.onDeleteReply,
//     required this.onLikeReply,
//     required this.currentUserId,
//   });

//   @override
//   State<MyCommentTile> createState() => _MyCommentTileState();
// }

// class _MyCommentTileState extends State<MyCommentTile> {
//   bool _showReplies = false;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         _buildCommentRow(
//           context,
//           username: widget.username,
//           message: widget.comment,
//           isOwn: widget.isOwnComment,
//           isLiked: widget.isLiked,
//           likeCount: widget.commentLikeCount,
//           onLike: widget.onLikeToggle,
//           onReplyTap: widget.onReplyTap,
//           onLongPress: widget.onLongPress, // 🔹 Forward to PostPage
//         ),

//         // Toggle "View/Hide replies"
//         if (widget.replies.isNotEmpty)
//           GestureDetector(
//             onTap: () => setState(() => _showReplies = !_showReplies),
//             child: Padding(
//               padding: const EdgeInsets.only(left: 54, top: 4, bottom: 4),
//               child: Text(
//                 _showReplies
//                     ? "Hide replies"
//                     : "View replies (${widget.replies.length})",
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.8),
//                     ),
//               ),
//             ),
//           ),

//         // Replies list
//         if (_showReplies)
//           Padding(
//             padding: const EdgeInsets.only(left: 40),
//             child: Column(
//               children: widget.replies
//                   .map(
//                     (reply) => Padding(
//                       padding: const EdgeInsets.only(top: 6),
//                       child: _buildCommentRow(
//                         context,
//                         username: reply.username,
//                         message: reply.message,
//                         isOwn: reply.uid == widget.currentUserId,
//                         isLiked: reply.likedBy.contains(widget.currentUserId),
//                         likeCount: reply.commentLikeCount,
//                         onLike: () => widget.onLikeReply(reply),
//                         onReplyTap: widget.onReplyTap,
//                         onLongPress: () => widget.onLongPress(), // 🔹 Still triggers PostPage
//                       ),
//                     ),
//                   )
//                   .toList(),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildCommentRow(
//     BuildContext context, {
//     required String username,
//     required String message,
//     required bool isOwn,
//     required bool isLiked,
//     required int likeCount,
//     required VoidCallback onLike,
//     required VoidCallback onReplyTap,
//     required VoidCallback onLongPress,
//   }) {
//     final theme = Theme.of(context);
//     final color = theme.colorScheme;

//     return InkWell(
//       onLongPress: onLongPress, // 🔹 Always trigger
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
//         decoration: BoxDecoration(
//           color: color.surfaceVariant.withOpacity(0.45),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const CircleAvatar(
//               radius: 20,
//               backgroundColor: Colors.grey,
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       // TODO: Navigate to user's profile page here
//                       // e.g. Navigator.pushNamed(context, '/profile', arguments: username);
//                     },
//                     child: Text(username,
//                         style: theme.textTheme.labelLarge
//                             ?.copyWith(fontWeight: FontWeight.w500, color: color.primary)),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(message,
//                       style:
//                           theme.textTheme.bodyMedium?.copyWith(height: 1.3)),
//                   const SizedBox(height: 4),
//                   GestureDetector(
//                     onTap: onReplyTap,
//                     child: Text(
//                       "Reply",
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         fontWeight: FontWeight.w500,
//                         color: color.primary,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Column(
//               children: [
//                 CommentLikeAnimation(
//                   isLiked: isLiked,
//                   onTap: onLike,
//                   size: 20,
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   likeCount.toString(),
//                   style: theme.textTheme.bodySmall
//                       ?.copyWith(color: color.onSurfaceVariant),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:social_media/Components/brick/comment_like_animation.dart';
// import 'package:social_media/models/comment.dart';

// class MyCommentTile extends StatefulWidget {
//   final String username;
//   final String comment;
//   final bool isOwnComment;
//   final VoidCallback onLongPress; // For comment long press
//   final bool isLiked;
//   final int commentLikeCount;
//   final VoidCallback onLikeToggle;

//   final List<Comment> replies;
//   final VoidCallback onReplyTap;
//   final void Function(Comment reply) onDeleteReply; // For reply long press
//   final void Function(Comment reply) onLikeReply;
//   final String currentUserId;

//   const MyCommentTile({
//     super.key,
//     required this.username,
//     required this.comment,
//     required this.isOwnComment,
//     required this.onLongPress,
//     required this.isLiked,
//     required this.commentLikeCount,
//     required this.onLikeToggle,
//     this.replies = const [],
//     required this.onReplyTap,
//     required this.onDeleteReply,
//     required this.onLikeReply,
//     required this.currentUserId,
//   });

//   @override
//   State<MyCommentTile> createState() => _MyCommentTileState();
// }

// class _MyCommentTileState extends State<MyCommentTile> {
//   bool _showReplies = false;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         _buildCommentRow(
//           username: widget.username,
//           message: widget.comment,
//           isOwn: widget.isOwnComment,
//           isLiked: widget.isLiked,
//           likeCount: widget.commentLikeCount,
//           onLike: widget.onLikeToggle,
//           onReplyTap: widget.onReplyTap,
//           onLongPress: widget.onLongPress, // comment long press
//         ),

//         if (widget.replies.isNotEmpty)
//           GestureDetector(
//             onTap: () => setState(() => _showReplies = !_showReplies),
//             child: Padding(
//               padding: const EdgeInsets.only(left: 54, top: 4, bottom: 4),
//               child: Text(
//                 _showReplies
//                     ? "Hide replies"
//                     : "View replies (${widget.replies.length})",
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.8),
//                     ),
//               ),
//             ),
//           ),

//         if (_showReplies)
//           Padding(
//             padding: const EdgeInsets.only(left: 40),
//             child: Column(
//               children: widget.replies
//                   .map(
//                     (reply) => Padding(
//                       padding: const EdgeInsets.only(top: 6),
//                       child: _buildCommentRow(
//                         username: reply.username,
//                         message: reply.message,
//                         isOwn: reply.uid == widget.currentUserId,
//                         isLiked: reply.likedBy.contains(widget.currentUserId),
//                         likeCount: reply.commentLikeCount,
//                         onLike: () => widget.onLikeReply(reply),
//                         onReplyTap: widget.onReplyTap,
//                         onLongPress: () => widget.onDeleteReply(reply),  // <--- FIXED here
//                       ),
//                     ),
//                   )
//                   .toList(),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildCommentRow({
//     required String username,
//     required String message,
//     required bool isOwn,
//     required bool isLiked,
//     required int likeCount,
//     required VoidCallback onLike,
//     required VoidCallback onReplyTap,
//     required VoidCallback onLongPress,
//   }) {
//     final theme = Theme.of(context);
//     final color = theme.colorScheme;

//     return InkWell(
//       onLongPress: onLongPress,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
//         decoration: BoxDecoration(
//           color: color.surfaceVariant.withOpacity(0.45),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const CircleAvatar(
//               radius: 20,
//               backgroundColor: Colors.grey,
//               child: Icon(Icons.person, color: Colors.white),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(username,
//                       style: theme.textTheme.labelLarge
//                           ?.copyWith(fontWeight: FontWeight.w500)),
//                   const SizedBox(height: 2),
//                   Text(message,
//                       style:
//                           theme.textTheme.bodyMedium?.copyWith(height: 1.3)),
//                   const SizedBox(height: 4),
//                   GestureDetector(
//                     onTap: onReplyTap,
//                     child: Text(
//                       "Reply",
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         fontWeight: FontWeight.w500,
//                         color: color.primary,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Column(
//               children: [
//                 CommentLikeAnimation(
//                   isLiked: isLiked,
//                   onTap: onLike,
//                   size: 20,
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   likeCount.toString(),
//                   style: theme.textTheme.bodySmall
//                       ?.copyWith(color: color.onSurfaceVariant),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';

// class MyCommentTile extends StatefulWidget {
//   final String username;          // Commenter's username
//   final String comment;           // Comment text
//   final bool isOwnComment;        // If comment belongs to current user
//   final VoidCallback onDelete;    // Delete callback
//   final bool isLiked;             // Has current user liked this comment?
//   final int commentLikeCount;     // Number of likes on comment
//   final VoidCallback onLikeToggle; // Callback when like button is pressed

//   const MyCommentTile({
//     super.key,
//     required this.username,
//     required this.comment,
//     required this.isOwnComment,
//     required this.onDelete,
//     required this.isLiked,
//     required this.commentLikeCount,
//     required this.onLikeToggle,
//   });

//   @override
//   State<MyCommentTile> createState() => _MyCommentTileState();
// }

// class _MyCommentTileState extends State<MyCommentTile> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _rotationAnimation;
//   late Animation<Color?> _colorAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     );

//     _scaleAnimation = TweenSequence<double>([
//       TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
//       TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
//     ]).animate(_controller);

//     _rotationAnimation = TweenSequence<double>([
//       TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
//       TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1).chain(CurveTween(curve: Curves.easeInOut)), weight: 50),
//       TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
//     ]).animate(_controller);

//     _colorAnimation = ColorTween(
//       begin: Colors.grey[600],
//       end: Colors.redAccent,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

//     // Set initial animation state
//     if (widget.isLiked) {
//       _controller.value = 1.0;
//     }
//   }

//   @override
//   void didUpdateWidget(covariant MyCommentTile oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (oldWidget.isLiked != widget.isLiked) {
//       if (widget.isLiked) {
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final color = theme.colorScheme;

//     return Dismissible(
//       key: ValueKey(widget.comment + widget.username),
//       direction: widget.isOwnComment ? DismissDirection.endToStart : DismissDirection.none,
//       background: Container(
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 10),
//         decoration: BoxDecoration(
//           color: Colors.red.shade700,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: const Icon(Icons.delete, color: Colors.white, size: 28),
//       ),
//       confirmDismiss: (_) async {
//         widget.onDelete();
//         return true;
//       },
//       child: InkWell(
//         onLongPress: () {
//           if (widget.isOwnComment) {
//             showModalBottomSheet(
//               context: context,
//               shape: const RoundedRectangleBorder(
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               builder: (_) => SafeArea(
//                 child: ListTile(
//                   leading: Icon(Icons.delete_outline, color: color.primary),
//                   title: const Text('Delete Comment'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     widget.onDelete();
//                   },
//                 ),
//               ),
//             );
//           }
//         },
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 5),
//           padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
//           decoration: BoxDecoration(
//             color: color.surfaceVariant.withOpacity(0.45),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const CircleAvatar(
//                 radius: 22,
//                 backgroundColor: Colors.grey,
//                 child: Icon(Icons.person, color: Colors.white, size: 24),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.username,
//                       style: theme.textTheme.labelLarge?.copyWith(
//                         fontWeight: FontWeight.w500,
//                         color: color.onSurfaceVariant,
//                         letterSpacing: 0.2,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     AnimatedSize(
//                       duration: const Duration(milliseconds: 300),
//                       child: Text(
//                         widget.comment,
//                         style: theme.textTheme.bodyLarge?.copyWith(
//                           color: color.onSurface,
//                           height: 1.3,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Like button + count on right side
//               Padding(
//                 padding: const EdgeInsets.only(left: 8, right: 4),
//                 child: Column(
//                   children: [
//                     GestureDetector(
//                       behavior: HitTestBehavior.translucent,
//                       onTap: () {
//                         widget.onLikeToggle();
//                       },
//                       child: AnimatedBuilder(
//                         animation: _controller,
//                         builder: (context, child) {
//                           return Transform.rotate(
//                             angle: _rotationAnimation.value,
//                             child: Transform.scale(
//                               scale: _scaleAnimation.value,
//                               child: Icon(
//                                 widget.isLiked ? Icons.favorite : Icons.favorite_border,
//                                 color: _colorAnimation.value,
//                                 size: 25,
//                                 shadows: widget.isLiked
//                                     ? [
//                                         Shadow(
//                                           blurRadius: 10,
//                                           color: Colors.redAccent.withOpacity(0.6),
//                                           offset: Offset(0, 0),
//                                         )
//                                       ]
//                                     : [],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       widget.commentLikeCount.toString(),
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: color.onSurfaceVariant,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }








// import 'package:flutter/material.dart';

// class MyCommentTile extends StatelessWidget {
//   final String username;
//   final String comment;
//   final bool isOwnComment;
//   final VoidCallback onDelete;

//   const MyCommentTile({
//     super.key,
//     required this.username,
//     required this.comment,
//     required this.isOwnComment,
//     required this.onDelete,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final color = theme.colorScheme;

//     return Dismissible(
//       key: ValueKey(comment + username),
//       direction: isOwnComment ? DismissDirection.endToStart : DismissDirection.none,
//       background: Container(
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         color: Colors.red,
//         child: const Icon(Icons.delete, color: Colors.white),
//       ),
//       confirmDismiss: (_) async {
//         onDelete();
//         return true;
//       },
//       child: InkWell(
//         onLongPress: () {
//           if (isOwnComment) {
//             showModalBottomSheet(
//               context: context,
//               shape: const RoundedRectangleBorder(
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//               ),
//               builder: (_) => SafeArea(
//                 child: ListTile(
//                   leading: Icon(Icons.delete_outline, color: color.primary),
//                   title: const Text('Delete Comment'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     onDelete();
//                   },
//                 ),
//               ),
//             );
//           }
//         },
//         child: Container(
//           margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.surfaceVariant.withOpacity(0.35),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const CircleAvatar(
//                 radius: 20,
//                 backgroundColor: Colors.grey,
//                 child: Icon(Icons.person, color: Colors.white),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(username,
//                         style: theme.textTheme.labelMedium?.copyWith(
//                           fontWeight: FontWeight.w600,
//                           color: color.onSurface,
//                         )),
//                     const SizedBox(height: 2),
//                     AnimatedSize(
//                       duration: const Duration(milliseconds: 300),
//                       child: Text(comment,
//                           style: theme.textTheme.bodyMedium?.copyWith(
//                             color: color.onSurface,
//                           )),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



