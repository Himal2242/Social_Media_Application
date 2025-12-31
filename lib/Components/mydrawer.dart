// left drawer

// OPTIONS
// HOME
// SEARCH
// SETTINGS
// LOGOUT


import 'package:flutter/material.dart';
import 'package:social_media/Components/mydrawer_tile.dart';
import 'package:social_media/pages/Profile_page.dart';
import 'package:social_media/pages/settings_page.dart';
import 'package:social_media/services/auth/auth_service.dart';

class MyDrawer extends StatelessWidget {
   MyDrawer({super.key,});

  // accesss auth service
  final _auth = AuthService();

  // logout service
  void logout(){
    _auth.logout();
  } 

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            
            //logoo
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 50.0),
              child: Icon(Icons.person,size: 72, 
              color: Theme.of(context).colorScheme.primary),
            ),
        
            //divider
            Divider(
              color: Theme.of(context).colorScheme.secondary,
            ),
          

            const SizedBox(height: 10,),


            //home list
            MydrawerTile(
              icon: Icons.home, 
              onTap: (){
                // pop menu as we are alredy on the homepage
                Navigator.pop(context);
              }, 
              title: "H O M E"),
        
            // P R O F I L E
            MydrawerTile(
              icon: Icons.person, 
              onTap: (){
                // pop menu as we are alredy on the homepage
                Navigator.pop(context);
        
                // go to profile page
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(uid: _auth.getCurrentUid()
                   ),
                  ),
                );
              }, 
              title: "P R O F I L E"),

        
            //settings list
            // MydrawerTile(
            //   icon: Icons.settings, 
            //   onTap: (){
            //     // pop menu as we are alredy on the homepage
            //     Navigator.pop(context);
        
            //     // go to settings page
            //     Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(),));
            //   }, 
            //   title: "S E T T I N G S"),

              const Spacer(),

              // logout list 
              MydrawerTile(
                icon: Icons.logout, onTap: logout, title: "L Ò G O U T")
        
          ],
        ),
      ),
    );
  }
}