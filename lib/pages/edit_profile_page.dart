import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media/models/user.dart';
import 'package:social_media/services/database/database_provider.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _bioController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final newBio = _bioController.text.trim();

    if (newBio == widget.user.bio) {
      Navigator.pop(context, false); // No changes made
      return;
    }

    setState(() => _isSaving = true);

    try {
      await Provider.of<DatabaseProvider>(context, listen: false).updateBio(newBio);
      Navigator.pop(context, true); // Changes saved successfully
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update bio. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.surface,
        foregroundColor: theme.primary,
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_rounded),
            onPressed: _isSaving ? null : _saveChanges,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar (non-editable for now)
              CircleAvatar(
                radius: 45,
                backgroundColor: theme.primary.withOpacity(0.15),
                child: Icon(Icons.person, size: 50, color: theme.primary),
              ),
              const SizedBox(height: 24),

              // Username (non-editable)
              _profileField(
                label: "Username",
                value: '@${widget.user.username}',
                theme: theme,
              ),
              const SizedBox(height: 14),

              // Name (non-editable)
              _profileField(
                label: "Name",
                value: widget.user.name,
                theme: theme,
              ),
              const SizedBox(height: 14),

              // Bio (editable)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Bio",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _bioController,
                maxLines: null,
                maxLength: 140,
                style: TextStyle(color: theme.primary),
                decoration: InputDecoration(
                  hintText: "Tell something about yourself...",
                  filled: true,
                  fillColor: theme.secondary.withOpacity(0.05),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: theme.secondary.withOpacity(0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileField({
    required String label,
    required String value,
    required ColorScheme theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: theme.secondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.isNotEmpty ? value : "Not set",
            style: TextStyle(fontSize: 15, color: theme.primary),
          ),
        ),
      ],
    );
  }
}
