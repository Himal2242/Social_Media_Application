import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media/Components/my_post_tile.dart';
import 'package:social_media/Components/mydrawer.dart';
import 'package:social_media/helper/navigate_page.dart';
import 'package:social_media/pages/create_post_page.dart';
import 'package:social_media/services/auth/auth_service.dart';
import 'package:social_media/services/database/database_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  Future<void> _initLoad() async {
    await loadAllPosts();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> loadAllPosts() async {
    final provider = Provider.of<DatabaseProvider>(context, listen: false);
    await provider.loadAllPosts();
  }

  void _openPostMessagePage() async {
    final message = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreatePostPage(),
        transitionsBuilder: (_, animation, __, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: Curves.ease));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
    if (message != null && message is String) {
      await loadAllPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listeningProvider = Provider.of<DatabaseProvider>(context);
    final posts = listeningProvider.allPosts;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: MyDrawer(),
      appBar: AppBar(
        title: const Text("H O M E"),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : RefreshIndicator(
              onRefresh: () async => await loadAllPosts(),
              displacement: 80,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverSafeArea(
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 6.0),
                            child: MyPostTile(
                        post: post, 
                        onUserTap: () => goUserPage(context, post.uid),
                        onPostTap: () => goPostPage(context, post),
                        ),
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}







// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:social_media/Components/my_post_tile.dart';
// import 'package:social_media/Components/mydrawer.dart';
// import 'package:social_media/helper/navigate_page.dart';
// import 'package:social_media/pages/create_post_page.dart';
// import 'package:social_media/services/database/database_provider.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _initLoad();
//   }

//   Future<void> _initLoad() async {
//     await loadAllPosts();
//     setState(() {
//       _isLoading = false;
//     });
//   }

//   Future<void> loadAllPosts() async {
//     final provider = Provider.of<DatabaseProvider>(context, listen: false);
//     await provider.loadAllPosts();
//   }

//   void _openPostMessagePage() async {
//     final message = await Navigator.push(
//       context,
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => const CreatePostPage(),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           const begin = Offset(1.0, 0.0);
//           const end = Offset.zero;
//           const curve = Curves.ease;
//           final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
//           final offsetAnimation = animation.drive(tween);
//           return SlideTransition(position: offsetAnimation, child: child);
//         },
//       ),
//     );

//     if (message != null && message is String) {
//       await loadAllPosts();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final listeningProvider = Provider.of<DatabaseProvider>(context);
//     final posts = listeningProvider.allPosts;

//     return Scaffold(
//       backgroundColor: Theme.of(context).colorScheme.surface,
//       drawer: MyDrawer(),
//       appBar: AppBar(
//         title: const Text("H O M E"),
//         centerTitle: true,
//         foregroundColor: Theme.of(context).colorScheme.primary,
//       ),
//       // floatingActionButton: FloatingActionButton(
//       //   onPressed: _openPostMessagePage,
//       //   child: const Icon(Icons.add),
//       // ),
//       body: _isLoading
//     ? const Center(child: CupertinoActivityIndicator(radius: 15))
//     : RefreshIndicator(
//         onRefresh: () async {
//           await loadAllPosts();
//         },
//         displacement: 80,
//         color: Theme.of(context).colorScheme.primary,
//         backgroundColor: Theme.of(context).colorScheme.surface,
//         child: CustomScrollView(
//           physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
//           slivers: [
//             // Removed CupertinoSliverRefreshControl
//             SliverSafeArea(
//               sliver: SliverList(
//                 delegate: SliverChildBuilderDelegate(
//                   (context, index) {
//                     final post = posts[index];
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
//                       child: 
                      
//                       // return post tile ui
//                       MyPostTile(
//                         post: post, 
//                         onUserTap: () => goUserPage(context, post.uid),
//                         onPostTap: () => goPostPage(context, post),
//                         ),                        
//                     );
//                   },
//                   childCount: posts.length,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
