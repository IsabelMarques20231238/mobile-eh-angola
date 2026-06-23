import 'package:flutter/material.dart';
import 'forum_listing_screen.dart';

class ForumScreen extends StatelessWidget {
  final bool isGuest;
  const ForumScreen({super.key, this.isGuest = false});

  @override
  Widget build(BuildContext context) {
    return const ForumListingScreen();
  }
}
