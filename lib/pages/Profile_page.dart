// ===================
// PROFILE PAGE
// ===================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media/Components/my_post_tile.dart';
import 'package:social_media/helper/navigate_page.dart';
import 'package:social_media/models/user.dart';
import 'package:social_media/pages/create_post_page.dart';  // Import for post creation page
import 'package:social_media/pages/edit_profile_page.dart';
import 'package:social_media/pages/settings_page.dart';
import 'package:social_media/services/auth/auth_service.dart';
import 'package:social_media/services/database/database_provider.dart';

class ProfilePage extends StatefulWidget {
  final String uid;

  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final DatabaseProvider _databaseProvider;
  final String currentUserId = AuthService().getCurrentUid();

  UserProfile? user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final fetchedUser = await _databaseProvider.userProfile(widget.uid);
      setState(() {
        user = fetchedUser;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditProfile() async {
    final didUpdate = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(user: user!)),
    );

    if (didUpdate == true) {
      await _loadUser(); // Refresh user data after edit
    }
  }

  void _showCreateOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Create',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const Divider(height: 0.02),
              ListTile(
                leading: Icon(Icons.post_add, color: Theme.of(context).colorScheme.primary),
                title: const Text('Post'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePostPage()),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  void _showProfileOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _openEditProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final allUserPosts = context.watch<DatabaseProvider>().filterUserPosts(widget.uid);

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.surface,
        foregroundColor: theme.primary,
        centerTitle: false,
        title: Text(
          '@${user?.username ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create',
            onPressed: _showCreateOptionsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showProfileOptionsSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadUser,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          MediaQuery.of(context).padding.top,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------- Header Section ----------
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: theme.primary.withOpacity(0.15),
                                child: Icon(Icons.person, size: 50, color: theme.primary),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user?.name ?? '',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              // Username in body removed as requested
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ---------- Bio ----------
                        if (user?.bio?.isNotEmpty == true)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.secondary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              user!.bio!,
                              style: TextStyle(fontSize: 14, color: theme.primary),
                            ),
                          )
                        else
                          Text(
                            "No bio provided.",
                            style: TextStyle(
                              color: theme.secondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 24),

                        // ---------- Posts ----------
                        Text(
                          "Posts",
                          style: TextStyle(
                            color: theme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        allUserPosts.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    "No posts yet.",
                                    style: TextStyle(color: theme.secondary),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: allUserPosts.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final post = allUserPosts[index];
                                   return MyPostTile(
                                           post: post,
                                           onUserTap: () {},
                                           onPostTap: () => goPostPage(context, post),
                                         );

                                  
                                  // return MyPostTile(
                                  //   post: post,
                                  //   onUserTap: () {},
                                  //   onPostTap: () => goPostPage(context, post),
                                  // );
                                },
                              ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}




// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:social_media/Components/my_bottom_bar.dart';
// import 'package:social_media/Components/my_post_tile.dart';
// import 'package:social_media/helper/navigate_page.dart';
// import 'package:social_media/models/user.dart';
// import 'package:social_media/pages/edit_profile_page.dart';
// import 'package:social_media/pages/settings_page.dart';
// import 'package:social_media/services/auth/auth_service.dart';
// import 'package:social_media/services/database/database_provider.dart';

// class ProfilePage extends StatefulWidget {
//   final String uid;

//   const ProfilePage({super.key, required this.uid});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   late final DatabaseProvider _databaseProvider;
//   final String currentUserId = AuthService().getCurrentUid();

//   UserProfile? user;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
//     _loadUser();
//   }

//   // Load user data
//   Future<void> _loadUser() async {
//     try {
//       final fetchedUser = await _databaseProvider.userProfile(widget.uid);
//       setState(() {
//         user = fetchedUser;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//     }
//   }

//   // Show edit + settings options
//   void _showProfileOptionsSheet() {
//     MyBottomBar.show(
//       context: context,
//       items: [
//         BottomBarItem(
//           icon: Icons.edit,
//           label: 'Edit Profile',
//           onTap: () async {
//             Navigator.pop(context); // Close sheet
//             final didUpdate = await Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => EditProfilePage(user: user!),
//               ),
//             );
//             if (didUpdate == true) {
//               await _loadUser(); // Reload after edit
//             }
//           },
//         ),
//         BottomBarItem(
//           icon: Icons.settings,
//           label: 'Settings',
//           onTap: () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const SettingsPage()),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context).colorScheme;
//     final allUserPosts = context.watch<DatabaseProvider>().filterUserPosts(widget.uid);

//     return Scaffold(
//       backgroundColor: theme.surface,

//       // ------------------- APP BAR -------------------
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: theme.surface,
//         foregroundColor: theme.primary,
//         centerTitle: true,
//         title: _isLoading
//             ? const CupertinoActivityIndicator()
//             : Text(
//                 '@${user?.username ?? ''}',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () {
//               // TODO: Add post logic
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.menu),
//             onPressed: _showProfileOptionsSheet,
//           ),
//         ],
//       ),

//       // ------------------- BODY -------------------
//       body: _isLoading
//           ? const Center(child: CupertinoActivityIndicator())
//           : SafeArea(
//               child: RefreshIndicator(
//                 onRefresh: _loadUser,
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     return SingleChildScrollView(
//                       physics: const AlwaysScrollableScrollPhysics(),
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//                       child: ConstrainedBox(
//                         constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                         child: IntrinsicHeight(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [

//                               // ---------- PROFILE HEADER ----------
//                               Center(
//                                 child: Column(
//                                   children: [
//                                     CircleAvatar(
//                                       radius: 45,
//                                       backgroundColor: theme.primary.withOpacity(0.15),
//                                       child: Icon(Icons.person, size: 50, color: theme.primary),
//                                     ),
//                                     const SizedBox(height: 12),
//                                     Text(
//                                       user?.name ?? '',
//                                       style: const TextStyle(
//                                           fontSize: 20, fontWeight: FontWeight.bold),
//                                     ),
//                                     const SizedBox(height: 6),
//                                     Text(
//                                       '@${user?.username ?? ''}',
//                                       style: TextStyle(fontSize: 14, color: theme.secondary),
//                                     ),
//                                   ],
//                                 ),
//                               ),

//                               const SizedBox(height: 24),

//                               // ---------- BIO ----------
//                               if (user?.bio?.isNotEmpty == true)
//                                 Container(
//                                   width: double.infinity,
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: theme.secondary.withOpacity(0.05),
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   child: Text(
//                                     user!.bio!,
//                                     style: TextStyle(fontSize: 14, color: theme.primary),
//                                   ),
//                                 )
//                               else
//                                 Text(
//                                   "No bio provided.",
//                                   style: TextStyle(
//                                     color: theme.secondary,
//                                     fontStyle: FontStyle.italic,
//                                   ),
//                                 ),

//                               const SizedBox(height: 24),

//                               // ---------- POSTS ----------
//                               Text(
//                                 "Posts",
//                                 style: TextStyle(
//                                   color: theme.primary,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 10),

//                               allUserPosts.isEmpty
//                                   ? Padding(
//                                       padding: const EdgeInsets.symmetric(vertical: 12),
//                                       child: Center(
//                                         child: Text(
//                                           "No posts yet.",
//                                           style: TextStyle(color: theme.secondary),
//                                         ),
//                                       ),
//                                     )
//                                   : ListView.separated(
//                                       shrinkWrap: true,
//                                       physics: const NeverScrollableScrollPhysics(),
//                                       itemCount: allUserPosts.length,
//                                       separatorBuilder: (_, __) => const SizedBox(height: 10),
//                                       itemBuilder: (context, index) {
//                                         final post = allUserPosts[index];
//                                         return MyPostTile(
//                                           post: post,
//                                           onUserTap: () {},
//                                           onPostTap: () => goPostPage(context, post),
//                                         );
//                                       },
//                                     ),

//                               const SizedBox(height: 32),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//     );
//   }
// }
