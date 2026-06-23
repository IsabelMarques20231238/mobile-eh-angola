import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'report_models.dart';

const _reportRed = Color(0xFFD43B27);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportFilter _filter = ReportFilter.all;
  late List<Report> _reports;

  @override
  void initState() {
    super.initState();
    _reports = List.of(ReportData.initialReports);
  }

  List<Report> get _visibleReports =>
      _reports.where((r) => reportMatchesFilter(r, _filter)).toList();

  int get _pendingCount => _reports.length;

  void _applyFilter(ReportFilter filter) => setState(() => _filter = filter);

  void _ignore(Report report) {
    setState(() => _reports.removeWhere((r) => r.id == report.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Denúncia ignorada')),
    );
  }

  void _removeContent(Report report) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover conteúdo?'),
        content: const Text(
          'Esta acção remove o conteúdo denunciado da plataforma. Não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _reports.removeWhere((r) => r.id == report.id));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conteúdo removido')),
              );
            },
            child: const Text(
              'Remover',
              style: TextStyle(
                color: _reportRed,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewOriginal(Report report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('A abrir conteúdo original…')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleReports;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReportsHeader(pendingCount: _pendingCount),
                  const SizedBox(height: 14),
                  _FilterTabs(
                    selected: _filter,
                    onSelected: _applyFilter,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (visible.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyReports(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final report = visible[index];
                    return _ReportCard(
                      report: report,
                      onIgnore: () => _ignore(report),
                      onRemove: () => _removeContent(report),
                      onViewOriginal: () => _viewOriginal(report),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavMock(index: 4),
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  final int pendingCount;

  const _ReportsHeader({required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textMain, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Denúncias',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _reportRed,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$pendingCount pendentes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final ReportFilter selected;
  final ValueChanged<ReportFilter> onSelected;

  const _FilterTabs({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final filter in ReportFilter.values) ...[
            _FilterTab(
              label: filter.label,
              selected: selected == filter,
              onTap: () => onSelected(filter),
            ),
            if (filter != ReportFilter.values.last) const SizedBox(width: 18),
          ],
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return Material(
        color: AppColors.wine,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onIgnore;
  final VoidCallback onRemove;
  final VoidCallback onViewOriginal;

  const _ReportCard({
    required this.report,
    required this.onIgnore,
    required this.onRemove,
    required this.onViewOriginal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PriorityRow(report: report),
          const SizedBox(height: 12),
          ..._contentSection(),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          _ReportMetaRow(report: report),
          const SizedBox(height: 14),
          _ActionRow(onIgnore: onIgnore, onRemove: onRemove),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: onViewOriginal,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.wine,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Ver original',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _contentSection() {
    if (report.type == ReportType.comment) {
      return [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EFF3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '"${report.quote}"',
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        if (report.contextLine != null) ...[
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
              children: [
                TextSpan(text: report.contextLine),
                TextSpan(
                  text: report.contextHighlight ?? '',
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ];
    }

    return [
      Text(
        report.title,
        style: const TextStyle(
          color: AppColors.textMain,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      ),
      if (report.author != null && report.type == ReportType.article) ...[
        const SizedBox(height: 6),
        Text(
          'por ${report.author}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
      if (report.type == ReportType.quiz) ...[
        const SizedBox(height: 4),
        Text(
          report.author ?? '',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    ];
  }
}

class _PriorityRow extends StatelessWidget {
  final Report report;

  const _PriorityRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PriorityIcon(priority: report.priority),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            report.priority.text,
            style: const TextStyle(
              color: _reportRed,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Text(
          report.timeAgo,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _PriorityIcon extends StatelessWidget {
  final ReportPriorityLabel priority;

  const _PriorityIcon({required this.priority});

  @override
  Widget build(BuildContext context) {
    return switch (priority) {
      ReportPriorityLabel.highPriority => Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: _reportRed,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.priority_high, color: Colors.white, size: 12),
      ),
      ReportPriorityLabel.urgentModeration => const Icon(
        Icons.warning_amber_rounded,
        color: _reportRed,
        size: 18,
      ),
      ReportPriorityLabel.technicalReview => const Icon(
        Icons.flag,
        color: _reportRed,
        size: 16,
      ),
    };
  }
}

class _ReportMetaRow extends StatelessWidget {
  final Report report;

  const _ReportMetaRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.people_outline, color: _reportRed, size: 18),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${report.reportCount} ${report.reportCount == 1 ? 'denúncia' : 'denúncias'}',
            style: const TextStyle(
              color: _reportRed,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                report.reasonTag,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _reportRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onIgnore;
  final VoidCallback onRemove;

  const _ActionRow({
    required this.onIgnore,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextButton(
          onPressed: onIgnore,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Ignorar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onRemove,
              style: ElevatedButton.styleFrom(
                backgroundColor: _reportRed,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text(
                'Remover conteúdo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Não há denúncias neste filtro',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
