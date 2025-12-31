import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media/services/database/database_provider.dart';
import 'package:social_media/pages/home_page.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitPost(DatabaseProvider databaseProvider) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      await databaseProvider.postMessage(text);

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomePage(),
            transitionsBuilder: (_, animation, __, child) {
              final offsetAnimation = animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              );
              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
          (route) => false,
        );
      }
    } catch (_) {
      setState(() {
        _isPosting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      backgroundColor: color.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: color.surface,
        foregroundColor: color.primary,
        centerTitle: true,
        title: const Text('Create'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          children: [
            // Post Text Input
            TextField(
              controller: _messageController,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              enabled: !_isPosting,
              style: TextStyle(
                color: color.onSurface, // ← FIX: proper text color
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(
                  color: color.onSurface.withOpacity(0.5), // ← hint contrast
                ),
                filled: true,
                fillColor: color.surfaceVariant.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: color.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: color.outline.withOpacity(0.3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Post Button
SizedBox(
  width: double.infinity,
  height: 48,
  child: GestureDetector(
    onTap: _messageController.text.trim().isEmpty || _isPosting
        ? null
        : () => _submitPost(databaseProvider),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _messageController.text.trim().isEmpty
            ? color.surfaceVariant
            : color.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: _isPosting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color.fromARGB(255, 224, 224, 224),
                ),
              )
            : AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _messageController.text.trim().isEmpty
                      ? color.primary
                      : Colors.white.withOpacity(0.95),
                ),
                child: const Text('Post'),
              ),
      ),
    ),
  ),
),


          ],
        ),
      ),
    );
  }
}
