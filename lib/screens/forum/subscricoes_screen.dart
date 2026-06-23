import 'package:flutter/material.dart';
import '../../models/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/shared_widgets.dart';
import '../profile/public_creator_profile_screen.dart';

class SubscricoesScreen extends StatelessWidget {
  const SubscricoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Subscrições'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── A SEGUIR ────────────────────────────────────────────────────────
          _SectionHeader(label: 'A SEGUIR'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: mockSubscriptions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicCreatorProfileScreen(
                            name: s.name.replaceAll('\n', ' '),
                            initials: s.initials,
                            role: s.role,
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        children: [
                          AppAvatar(
                            initials: s.initials,
                            size: 52,
                            bg: s.avatarBg,
                            fg: s.avatarFg,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(),

          // ── RECENTES ───────────────────────────────────────────────────────
          _SectionHeader(label: 'RECENTES'),
          ...mockRecent.map((r) => _RecentItem(pub: r)),

          const SizedBox(height: 16),

          // ── SUGERIDOS PARA TI ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sugeridos para ti',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...mockSuggested.map((s) => _SuggestedItem(author: s)),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: const BottomNavMock(index: 3),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Recent Publication Item ──────────────────────────────────────────────────
class _RecentItem extends StatelessWidget {
  final dynamic pub;
  const _RecentItem({required this.pub});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              initials: pub.authorInitials,
              size: 36,
              bg: pub.avatarBg,
              fg: pub.avatarFg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pub.publishedText,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pub.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _TypeChip(label: pub.type),
                      const SizedBox(width: 6),
                      Text(
                        '· ${pub.duration} · ${pub.timeAgo}',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Thumbnail placeholder
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.image_outlined, size: 22, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  const _TypeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isVideo = label.toLowerCase() == 'vídeo' || label.toLowerCase() == 'video';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isVideo ? const Color(0xFFE8F5EE) : AppColors.winePill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isVideo ? AppColors.green : AppColors.wine,
        ),
      ),
    );
  }
}

// ─── Suggested Author Item ────────────────────────────────────────────────────
class _SuggestedItem extends StatefulWidget {
  final dynamic author;
  const _SuggestedItem({required this.author});

  @override
  State<_SuggestedItem> createState() => _SuggestedItemState();
}

class _SuggestedItemState extends State<_SuggestedItem> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicCreatorProfileScreen(
                    name: widget.author.name.replaceAll('\n', ' '),
                    initials: widget.author.initials,
                    role: widget.author.role,
                  ),
                ),
              );
            },
            child: AppAvatar(initials: widget.author.initials, size: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicCreatorProfileScreen(
                      name: widget.author.name.replaceAll('\n', ' '),
                      initials: widget.author.initials,
                      role: widget.author.role,
                    ),
                  ),
                );
              },
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.author.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  widget.author.role,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _following = !_following),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _following ? AppColors.wine : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _following ? AppColors.wine : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Text(
                _following ? 'A seguir' : 'Seguir',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _following ? Colors.white : AppColors.wine,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
