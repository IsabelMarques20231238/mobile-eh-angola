import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../services/quiz_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'quiz_models.dart';

// Unified display entry for both quiz-specific and global rankings
class _Entry {
  final int position;
  final String name;
  final String institution;
  final String mainValue;
  final String subValue;
  final String subLabel;
  final bool isCurrentUser;
  final String initials;
  final int? timeSpentSeconds;

  const _Entry({
    required this.position,
    required this.name,
    required this.institution,
    required this.mainValue,
    required this.subValue,
    required this.subLabel,
    required this.isCurrentUser,
    required this.initials,
    this.timeSpentSeconds,
  });
}

class QuizRankingScreen extends StatefulWidget {
  // if null → show global ranking; if set → show quiz-specific ranking
  final QuizModel? quiz;

  const QuizRankingScreen({super.key, this.quiz});

  @override
  State<QuizRankingScreen> createState() => _QuizRankingScreenState();
}

class _QuizRankingScreenState extends State<QuizRankingScreen>
    with SingleTickerProviderStateMixin {
  final _service = QuizService(ApiClient.instance);

  // Quiz-ranking state
  final _quizTabs = ['Todos', 'Excelente', 'Bom', 'Suficiente'];
  final _quizPerf = [null, 'excellent', 'good', 'sufficient'];
  int _quizTabIndex = 0;
  List<_Entry> _quizEntries = [];
  Map<String, dynamic>? _myQuizPos;
  bool _quizLoading = true;
  String? _quizError;

  // Global-ranking state
  List<_Entry> _globalEntries = [];
  Map<String, dynamic>? _myGlobalPos;
  String? _globalUpdatedAt;
  bool _globalLoading = false;
  String? _globalError;

  late TabController _tabCtrl;
  bool get _isGlobalOnly => widget.quiz == null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 1, vsync: this);
    if (_isGlobalOnly) {
      _globalLoading = true;
      _loadGlobal();
    } else {
      _loadQuizRanking();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuizRanking() async {
    if (!mounted) return;
    final perf = _quizPerf[_quizTabIndex];
    setState(() { _quizLoading = true; _quizError = null; });
    try {
      final result = await _service.getQuizRanking(widget.quiz!.id, performance: perf);
      if (!mounted) return;
      final myId = AuthState.instance.user?.id;
      setState(() {
        _quizEntries = result.ranking.map((r) {
          final userId = r.user?['id'];
          return _Entry(
            position: r.position,
            name: r.userName,
            institution: r.institution,
            mainValue: '${r.score}/${r.totalQuestions}',
            subValue: r.timeSpentSeconds != null
                ? formatSeconds(r.timeSpentSeconds)
                : '${r.percentage.round()}%',
            subLabel: r.timeSpentSeconds != null ? 'Tempo' : 'Acerto',
            isCurrentUser: myId != null && userId == myId,
            initials: r.initials,
            timeSpentSeconds: r.timeSpentSeconds,
          );
        }).toList();
        _myQuizPos = result.myPosition;
        _quizLoading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _quizError = e.message; _quizLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _quizError = e.toString(); _quizLoading = false; });
    }
  }

  Future<void> _loadGlobal() async {
    if (!mounted) return;
    setState(() { _globalLoading = true; _globalError = null; });
    try {
      final result = await _service.getGlobalRanking();
      if (!mounted) return;
      final myId = AuthState.instance.user?.id;
      setState(() {
        _globalEntries = result.ranking.map((r) {
          final userId = r.user?['id'];
          return _Entry(
            position: r.position,
            name: r.userName,
            institution: r.institution,
            mainValue: _fmtPts(r.totalPoints),
            subValue: '${r.avgAccuracy.round()}% acerto',
            subLabel: 'Acerto médio',
            isCurrentUser: myId != null && userId == myId,
            initials: r.initials,
          );
        }).toList();
        _myGlobalPos = result.myPosition;
        _globalUpdatedAt = result.updatedAtHuman;
        _globalLoading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _globalError = e.message; _globalLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _globalError = e.toString(); _globalLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, size: 16, color: c.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.quiz != null ? 'Ranking do Quiz' : 'Ranking Global',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.wine),
        ),
      ),
      body: _isGlobalOnly ? _buildGlobalBody(c) : _buildQuizBody(c),
      bottomNavigationBar: const BottomNavMock(index: 2),
    );
  }

  Widget _buildTabError(AppAdaptiveColors c, String msg, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.circleExclamation, color: c.muted, size: 28),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }

  Widget _buildQuizBody(AppAdaptiveColors c) {
    if (_quizLoading) return const Center(child: CircularProgressIndicator());
    if (_quizError != null) {
      return _buildTabError(c, _quizError!, _loadQuizRanking);
    }
    return Column(
      children: [
        // Performance filter chips
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            scrollDirection: Axis.horizontal,
            itemCount: _quizTabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final active = _quizTabIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _quizTabIndex = i);
                  _loadQuizRanking();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.wine : c.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? AppColors.wine : c.border),
                  ),
                  child: Text(
                    _quizTabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : c.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _quizEntries.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadQuizRanking,
                  child: ListView(children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        FaIcon(FontAwesomeIcons.rankingStar, color: c.muted, size: 28),
                        const SizedBox(height: 10),
                        Text('Sem dados de ranking',
                            style: TextStyle(color: c.textSecondary, fontSize: 14)),
                      ]),
                    ),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadQuizRanking,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      // My position card at the TOP
                      if (_myQuizPos != null) ...[
                        _MyPositionCard(myPos: _myQuizPos!, entries: _quizEntries),
                        const SizedBox(height: 16),
                      ],
                      // Full table — no podium, all positions
                      _RankingTable(entries: _quizEntries),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildGlobalBody(AppAdaptiveColors c) {
    if (_globalLoading) return const Center(child: CircularProgressIndicator());
    if (_globalError != null) {
      return _buildTabError(c, _globalError!, _loadGlobal);
    }
    return Column(
      children: [
        if (_globalUpdatedAt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Icon(Icons.update_rounded, size: 13, color: c.muted),
                const SizedBox(width: 5),
                Text(
                  'Actualizado $_globalUpdatedAt',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ),
          ),
        Expanded(
          child: _buildRankingList(c, _globalEntries, _myGlobalPos, 'GLOBAL',
              onRefresh: _loadGlobal),
        ),
      ],
    );
  }

  Widget _buildRankingList(
    AppAdaptiveColors c,
    List<_Entry> entries,
    Map<String, dynamic>? myPos,
    String label, {
    required Future<void> Function() onRefresh,
  }) {
    if (entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(FontAwesomeIcons.rankingStar, color: c.muted, size: 28),
                  const SizedBox(height: 10),
                  Text('Sem dados de ranking',
                      style: TextStyle(color: c.textSecondary, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    final myPosNum = myPos?['position'] as int?;
    final myInPodium = myPosNum != null && myPosNum <= 3;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _Podium(top3: top3, label: label),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 16),
            _RankingTable(entries: rest),
          ],
          // Only show card if user is NOT already highlighted in the podium
          if (myPos != null && !myInPodium) ...[
            const SizedBox(height: 16),
            _MyPositionCard(myPos: myPos),
          ],
        ],
      ),
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<_Entry> top3;
  final String label;
  const _Podium({required this.top3, required this.label});

  @override
  Widget build(BuildContext context) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.trophy, size: 13, color: AppColors.wine),
            const SizedBox(width: 5),
            Text(
              'TOP 3 $label',
              style: const TextStyle(
                color: AppColors.wine,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (second != null) Expanded(child: _PodiumSlot(entry: second, rank: 2)),
            if (first != null) Expanded(child: _PodiumSlot(entry: first, rank: 1)),
            if (third != null) Expanded(child: _PodiumSlot(entry: third, rank: 3)),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final _Entry entry;
  final int rank;
  const _PodiumSlot({required this.entry, required this.rank});

  Color get _avatarBg => switch (rank) {
        1 => const Color(0xFF3D1220),
        2 => const Color(0xFF2F4569),
        _ => const Color(0xFF3D5A3E),
      };

  Color get _badgeBg => switch (rank) {
        1 => AppColors.wine,
        2 => const Color(0xFF64748B),
        _ => const Color(0xFF6B7280),
      };

  double get _radius => rank == 1 ? 34.0 : 26.0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isMe = entry.isCurrentUser;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isMe)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.wine,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'VOCÊ',
              style: TextStyle(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
            ),
          )
        else if (rank == 1)
          const FaIcon(FontAwesomeIcons.trophy, color: Color(0xFFEAB308), size: 24),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: _radius,
              backgroundColor: isMe ? AppColors.wine : _avatarBg,
              child: Text(
                entry.initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: rank == 1 ? 18 : 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 2, bottom: 2),
              decoration: BoxDecoration(
                color: _badgeBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isMe ? 'Você' : entry.name,
          style: TextStyle(
            color: isMe ? c.wine : c.textMain,
            fontSize: rank == 1 ? 14 : 13,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.institution.isNotEmpty ? '${entry.institution} · ' : ''}${entry.mainValue}',
          style: TextStyle(
            color: isMe ? AppColors.wine : (rank == 1 ? AppColors.wine : c.muted),
            fontSize: 11,
            fontWeight: (isMe || rank == 1) ? FontWeight.w700 : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Ranking table ─────────────────────────────────────────────────────────────

class _RankingTable extends StatefulWidget {
  final List<_Entry> entries;
  const _RankingTable({required this.entries});

  @override
  State<_RankingTable> createState() => _RankingTableState();
}

class _RankingTableState extends State<_RankingTable> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text('#',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.muted,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('UTILIZADOR',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.muted,
                          letterSpacing: 0.5)),
                ),
                Text('RESULTADO',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.muted,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          for (int i = 0; i < widget.entries.length; i++) ...[
            GestureDetector(
              onTap: () => setState(
                  () => _expandedIndex = _expandedIndex == i ? null : i),
              behavior: HitTestBehavior.opaque,
              child: _expandedIndex == i
                  ? _ExpandedCard(entry: widget.entries[i])
                  : _TableRow(entry: widget.entries[i]),
            ),
            if (i < widget.entries.length - 1) Divider(height: 1, color: c.border),
          ],
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final _Entry entry;
  const _TableRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isMe = entry.isCurrentUser;
    return Container(
      decoration: BoxDecoration(
        color: isMe ? AppColors.wineBg : Colors.transparent,
        border: isMe
            ? const Border(left: BorderSide(color: AppColors.wine, width: 3))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              entry.position.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isMe ? AppColors.wine : c.muted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe ? AppColors.wine : c.border,
            child: Text(
              entry.initials,
              style: TextStyle(
                color: isMe ? Colors.white : c.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMe ? 'Você (${entry.name.split(' ').first})' : entry.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isMe ? FontWeight.w800 : FontWeight.w500,
                    color: isMe ? AppColors.wine : c.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.timeSpentSeconds == null && entry.institution.isNotEmpty)
                  Text(
                    entry.institution,
                    style: TextStyle(fontSize: 11, color: c.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (entry.timeSpentSeconds != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined,
                    size: 12,
                    color: isMe ? AppColors.wine : c.muted),
                const SizedBox(width: 3),
                Text(
                  formatSeconds(entry.timeSpentSeconds),
                  style: TextStyle(
                      fontSize: 12,
                      color: isMe ? AppColors.wine : c.muted),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.mainValue,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppColors.wine : c.textMain,
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.mainValue,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppColors.wine : c.textMain,
                  ),
                ),
                if (entry.subValue.isNotEmpty)
                  Text(
                    entry.subValue,
                    style: TextStyle(fontSize: 11, color: c.muted),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ExpandedCard extends StatelessWidget {
  final _Entry entry;
  const _ExpandedCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;
    final label = isMe ? 'A SUA POSIÇÃO' : entry.name.toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppColors.wine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isMe && entry.institution.isNotEmpty)
                      Text(
                        entry.institution,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
              if (isMe)
                const FaIcon(FontAwesomeIcons.arrowTrendUp,
                    color: Colors.white70, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '#${entry.position}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                height: 1.1),
          ),
          const SizedBox(height: 14),
          _StatRow(label: 'Resultado', value: entry.mainValue),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          _StatRow(label: entry.subLabel, value: entry.subValue),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MyPositionCard extends StatelessWidget {
  final Map<String, dynamic> myPos;
  // When provided, renders the rich quiz design with name + percentile message
  final List<_Entry>? entries;

  const _MyPositionCard({required this.myPos, this.entries});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final position = myPos['position'];
    final posNum =
        position is int ? position : int.tryParse(position?.toString() ?? '');
    final score = myPos['score'];
    final total = myPos['total_questions'];
    final pts = myPos['total_points'];

    String value = '';
    if (score != null && total != null) {
      value = '$score/$total';
    } else if (pts != null) {
      value = _fmtPts(pts as int);
    }

    // ── Rich design for quiz ranking ──────────────────────────────────────────
    if (entries != null) {
      final myEntry = entries!.where((e) => e.isCurrentUser).firstOrNull;
      final displayName = myEntry != null ? 'Tu · ${myEntry.name}' : 'Tu';
      final institution = myEntry?.institution ?? '';

      String? perfMsg;
      if (posNum != null && entries!.isNotEmpty) {
        final topPct = ((posNum / entries!.length) * 100).round();
        perfMsg = 'Estás no top $topPct% da tua turma';
      }

      return Container(
        decoration: BoxDecoration(
          color: AppColors.wineBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.wine.withValues(alpha: 0.25)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 5,
                decoration: const BoxDecoration(
                  color: AppColors.wine,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              posNum != null ? '#$posNum' : '#—',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppColors.wine,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: c.textMain,
                              ),
                            ),
                            if (institution.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                institution,
                                style: TextStyle(
                                    fontSize: 12, color: c.textSecondary),
                              ),
                            ],
                            if (perfMsg != null) ...[
                              const SizedBox(height: 5),
                              Text(
                                perfMsg,
                                style: TextStyle(fontSize: 12, color: c.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (value.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.wine,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Compact design for global ranking (user not in podium) ────────────────
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.wineBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.wine.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A SUA POSIÇÃO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.wine,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                posNum != null ? '#$posNum' : '#—',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: c.wine,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.wine,
              ),
            ),
        ],
      ),
    );
  }
}

// ── helpers ───────────────────────────────────────────────────────────────────

String _fmtPts(int pts) {
  if (pts == 0) return '0 pts';
  final s = pts.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  return '$s pts';
}
