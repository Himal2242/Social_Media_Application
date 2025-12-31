import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media/Components/my_settings_tile.dart';
import 'package:social_media/Theme/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: const Text("S E T T I N G S"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // <-- this is all you need
          },
        ),
        foregroundColor: theme.primary,
      ),
      body: Column(
        children: [
          MySettingsTile(
            title: "Dark Mode",
            action: CupertinoSwitch(
              onChanged: (value) {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
              value: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
            ), onTap: () {  },
          ),
        ],
      ),
    );
  }
}




// class SettingsPage extends StatelessWidget {
//   const SettingsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).colorScheme.surface,
      
      
//       // APPBAR
//       appBar: AppBar(
//         title: Text("S E T T I N G S"),
//         centerTitle: true,
//         foregroundColor: Theme.of(context).colorScheme.primary,
//       ),

//       //BODY
//       body: Column(
//         children: [
          
//           // Dark mode tile
//           MySettingsTile(title: "Dark Mode", action: CupertinoSwitch(
//                onChanged: (value) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
//                value: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
//                ),)
          
//           // Block User tile

        
//           // Block User tile
//         ],
//       ),

//     );
//   }
// }
