import 'package:flutter/material.dart';

class MyBottomBar {
  static void show({
    required BuildContext context,
    required List<BottomBarItem> items, required String title,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: items.map((item) {
          return ListTile(
            leading: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
            title: Text(item.label),
            onTap: () {
              Navigator.pop(context);
              item.onTap?.call();
            },
          );
        }).toList(),
      ),
    );
  }
}

class BottomBarItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  BottomBarItem({
    required this.icon,
    required this.label,
    this.onTap,
  });
}
