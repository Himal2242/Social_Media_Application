/*
POST TILE

Displays each post with the following features:
- Shows username, post message, like count, and comment count.
- Allows liking/unliking a post with proper UI feedback.
- Shows options menu for deleting own posts or reporting/blocking others.
- Tapping post opens detailed PostPage with comments.
- Tapping username opens user profile page.

Requirements to use:
- Provide the Post object.
- Provide callbacks for onPostTap (navigate to post details).
- Provide callbacks for onUserTap (navigate to user profile).
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media/models/post.dart';
import 'package:social_media/pages/post_page.dart';
import 'package:social_media/services/auth/auth_service.dart';
import 'package:social_media/services/database/database_provider.dart';

class MyPostTile extends StatefulWidget {
  final Post post;
  final VoidCallback onUserTap;
  final VoidCallback onPostTap;

  const MyPostTile({
    Key? key,
    required this.post,
    required this.onUserTap,
    required this.onPostTap,
  }) : super(key: key);

  @override
  State<MyPostTile> createState() => _MyPostTileState();
}

class _MyPostTileState extends State<MyPostTile> {
  @override
  void initState() {
    super.initState();
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    db.listenToComments(widget.post.id);
  }

  void _toggleLikePost() async {
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    try {
      await db.toggleLike(widget.post.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like: $e')),
      );
    }
  }

  void _showOptions(BuildContext ctx) {
    final db = Provider.of<DatabaseProvider>(context, listen: false);
    final currentUid = AuthService().getCurrentUid();
    final isOwnPost = widget.post.uid == currentUid;

    showModalBottomSheet(
      context: ctx,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (isOwnPost)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text("Delete"),
                  onTap: () async {
                    Navigator.pop(context);
                    final success = await db.deletePost(widget.post.id);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to delete post')),
                      );
                    }
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text("Report"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text("Block User"),
                  onTap: () => Navigator.pop(context),
                ),
              ],
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPostCommentsSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostPage(post: widget.post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with username and options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: widget.onUserTap,
                  child: Row(
                    children: [
                      Icon(Icons.person, color: colorScheme.primary),
                      const SizedBox(width: 5),
                      Text(
                        '@${widget.post.username}',
                        style: TextStyle(
                          color: colorScheme.primary.withOpacity(0.7),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showOptions(context),
                  child: Icon(Icons.more_horiz, color: colorScheme.primary),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Post message
            Text(
              widget.post.message,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 12),

            // Likes and comments
            Consumer<DatabaseProvider>(
              builder: (context, db, _) {
                final likeCount = db.getLikeCount(widget.post.id);
                final isLiked = db.isPostLikedByCurrentUser(widget.post.id);
                final commentCount = db.getComments(widget.post.id)?.length ?? 0;

                return Row(
                  children: [
                    // LIKE
                    GestureDetector(
                      onTap: _toggleLikePost,
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 20,
                            child: Text(
                              likeCount > 0 ? likeCount.toString() : '',
                              style: TextStyle(color: colorScheme.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 0),

                    // COMMENT
                    GestureDetector(
                      onTap: _openPostCommentsSheet,
                      child: Row(
                        children: [
                          Icon(Icons.mode_comment_outlined, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 24,
                            child: Text(
                              commentCount > 0 ? commentCount.toString() : '',
                              style: TextStyle(color: colorScheme.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}










// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:social_media/services/auth/auth_service.dart';
// import 'package:social_media/services/database/database_provider.dart';
// import '../models/post.dart';

// class MyPostTile extends StatelessWidget {
//   final Post post;
//   final VoidCallback onUserTap;
//   final VoidCallback onPostTap;

//   const MyPostTile({
//     Key? key,
//     required this.post,
//     required this.onUserTap,
//     required this.onPostTap,
//   }) : super(key: key);


//   // BUILD UI
//   @override
//   Widget build(BuildContext context) {
    
//     // provider
//     final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
//     final listeningProvider = context.watch<DatabaseProvider>();

    
//     final bool likedByCurrentUser = listeningProvider.isPostLikedByCurrentUser(post.id);
//     // final bool likedByCurrentUser = listeningProvider.isPostLikedByCurrentUser(post.id);

//     // listen to like count
//     int likeCount = listeningProvider.getLikeCount(post.id);

//     // listen to comment count
//     int commentCount = listeningProvider.getComments(post.id).length;

//     // on startup
//     @override 
//     void initState() {
//       super.initState();

//       // load comments for 
//       _loadComments();
//     }

//     /*
    
//     LIKES
    
//      */
    
//     // user tapped like or unlike
//     void _toggleLikePost() async {
//       try {
//         await databaseProvider.toggleLike(post.id);
//       } catch (e) {
//         print("Error toggling like: $e");
//       }
//     }

//     /*
    
//     COMMENTS

//     */

//     // comment text controller
//     final _commentController = TextEditingController();

//     // user tapped post to add comments
//   Future<void> _addComment() async {

//     // does nothin if theres nothin in the textfield
//     if (_commentController.text.trim().isEmpty) return;

//     // attemp to post the comment
//     try {
//       await databaseProvider.addComment(
//         post.id,
//         _commentController.text.trim(),
//       );
//     } catch (e) {
//       print('Failed to add comment: $e');
//     }
//   }

//   // load the comments
//   Future<void> _loadComments() async {
//     await databaseProvider.loadComments(post.id);
//   }

//   // open comment box --> user wants to type new comment
//   void _openNewCommentBox() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text("New Comment"),
//           content: TextField(
//             controller: _commentController,
//             decoration: const InputDecoration(hintText: "Type a comment..."),
//             autofocus: true,
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 await _addComment();
//                 Navigator.of(context).pop();
//                 _commentController.clear();
//               },
//               child: const Text("Post"),
//             ),
//           ],
//         );
//       },
//     );
//   }


  
//     // Show Options for post
//     void _showOptions(BuildContext ctx) {
//       String currentUid = AuthService().getCurrentUid();
//       final bool isOwnPost = post.uid == currentUid;

//       showModalBottomSheet(
//         context: ctx,
//         builder: (context) {
//           return SafeArea(
//             child: Wrap(
//               children: [
//                 if (isOwnPost)
//                   ListTile(
//                     leading: Icon(Icons.delete),
//                     title: Text("Delete"),
//                     onTap: () async {
//                       Navigator.pop(context);
//                       await databaseProvider.deletePost(post.id);
//                     },
//                   )
//                 else ...[
//                   ListTile(
//                     leading: const Icon(Icons.flag),
//                     title: const Text("Report"),
//                     onTap: () {
//                       Navigator.pop(context);
//                       // Add report logic
//                     },
//                   ),
//                   ListTile(
//                     leading: const Icon(Icons.block),
//                     title: const Text("Block User"),
//                     onTap: () {
//                       Navigator.pop(context);
//                       // Add block logic
//                     },
//                   ),
//                 ],
//                 ListTile(
//                   leading: const Icon(Icons.cancel),
//                   title: const Text("Cancel"),
//                   onTap: () => Navigator.pop(context),
//                 )
//               ],
//             ),
//           );
//         },
//       );
//     }

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
//       child: GestureDetector(
//         onTap: onPostTap,
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.secondary,
//             border: Border.all(color: const Color.fromARGB(255, 233, 233, 233)),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Top row with profile + more options
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   GestureDetector(
//                     onTap: onUserTap,
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.person,
//                           color: Theme.of(context).colorScheme.primary,
//                         ),
//                         const SizedBox(width: 5),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               '@${post.username}',
//                               style: TextStyle(
//                                 color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () => _showOptions(context),
//                     child: Icon(
//                       Icons.more_horiz,
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 12),

//               // Post content
//               Text(
//                 post.message,
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.onSurface,
//                   fontSize: 14,
//                 ),
//               ),

//               const SizedBox(height: 12),

//               // Like + Comment Row (Only Like shown now)
//               Row(
//                 children: [
          
//                   // LIKE SECTION
//                   SizedBox(
//                     width: 50,
//                     child: Row(
//                       children: [
//                         // like button 
//                           GestureDetector(
//                             onTap: _toggleLikePost,
//                             child: likedByCurrentUser
//                               ? const Icon(Icons.favorite,
//                               color: Colors.red,
//                               )
//                               : Icon(
//                                 Icons.favorite_border,
//                                 color: Theme.of(context).colorScheme.primary,
//                               )
//                             ,
//                           ),
                    
//                       const SizedBox(width: 5,),
                    
//                           // like count
//                           Text(
//                               (likeCount > 0 || likedByCurrentUser) ? likeCount.toString() : '',
//                               style: TextStyle(color: Theme.of(context).colorScheme.primary),
//                             ),
//                         ],
//                     ),
//                   ),

//                   // COMMENT SECTION
//                   Row(
//                     children: [
                      
//                       // Comment button
//                       GestureDetector(
//                         onTap: _openNewCommentBox,
//                         child: Icon(Icons.comment,
//                         color: Theme.of(context).colorScheme.primary
//                         ),
//                       ),

//                     const SizedBox(width: 5,),

//                       // comment count
//                       Text(
//                         commentCount != 0 ?
//                         commentCount.toString() : '',
//                               style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      
//                       )
//                   ],
//                   )
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


