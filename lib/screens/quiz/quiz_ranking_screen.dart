import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/api_models.dart';
import '../../services/content_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'quiz_models.dart';

class QuizRankingScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizRankingScreen({super.key, required this.quiz});

  @override
  State<QuizRankingScreen> createState() => _QuizRankingScreenState();
}

class _QuizRankingScreenState extends State<QuizRankingScreen> {
  String _period = 'ALL_TIME';
  late Future<List<RankingItem>> _futureRanking;

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  void _loadRanking() {
    _futureRanking = ContentService(ApiClient.instance).ranking(period: _period);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
        title: const Text('Ranking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(_loadRanking))],
      ),
      body: Column(
        children: [
          _buildPeriodTabs(),
          Expanded(
            child: FutureBuilder<List<RankingItem>>(
              future: _futureRanking,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _StateMessage(title: 'Nao foi possivel carregar o ranking', onRetry: () => setState(_loadRanking));
                }
                final ranking = snapshot.data ?? const [];
                if (ranking.isEmpty) return const _StateMessage(title: 'Ainda nao ha dados de ranking');
                return RefreshIndicator(
                  onRefresh: () async => setState(_loadRanking),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: ranking.length,
                    itemBuilder: (context, i) => _buildRankingRow(ranking[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavMock(index: 2),
    );
  }

  Widget _buildPeriodTabs() {
    final periods = const {'ALL_TIME': 'Global', 'MONTHLY': 'Mensal', 'WEEKLY': 'Semanal'};
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final entry = periods.entries.elementAt(i);
          final isSelected = _period == entry.key;
          return GestureDetector(
            onTap: () => setState(() {
              _period = entry.key;
              _loadRanking();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Text(entry.value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankingRow(RankingItem entry) {
    final isTop3 = entry.position <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: isTop3 ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))] : null,
      ),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#${entry.position}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          CircleAvatar(radius: 18, backgroundColor: isTop3 ? AppColors.primary : AppColors.accentMid, child: Text(_initials(entry.name), style: TextStyle(color: isTop3 ? Colors.white : AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('${entry.quizzesCompleted} quizzes concluidos', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text('${entry.totalScore}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isTop3 ? AppColors.primary : AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0]).take(2).join().toUpperCase();
  }
}

class _StateMessage extends StatelessWidget {
  final String title;
  final VoidCallback? onRetry;

  const _StateMessage({required this.title, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.leaderboard_outlined, color: AppColors.textMuted, size: 34),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
          ],
        ),
      ),
    );
  }
}
