import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CreateContentScreen extends StatefulWidget {
  const CreateContentScreen({super.key});

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  final title = TextEditingController();
  final body = TextEditingController();
  int type = 0;
  String category = 'Economia Colonial';
  bool coverAdded = false;
  final categories = const [
    'Economia Colonial',
    'História',
    'Petróleo',
    'Política',
  ];

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  void _publish() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_types[type].label} enviado para publicação')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.wine, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Novo ${_types[type].title}',
          style: const TextStyle(
            color: AppColors.wine,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _publish,
            child: const Text(
              'Publicar',
              style: TextStyle(
                color: AppColors.wine,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
        children: [
          Row(
            children: [
              for (var i = 0; i < _types.length; i++) ...[
                Expanded(
                  child: _TypeButton(
                    data: _types[i],
                    selected: type == i,
                    onTap: () => setState(() => type = i),
                  ),
                ),
                if (i != _types.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 46),
          TextField(
            controller: title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(
              hintText: 'Título do conteúdo...',
              hintStyle: TextStyle(
                color: AppColors.muted,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
              filled: false,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.wine),
              ),
              contentPadding: EdgeInsets.only(bottom: 16),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _chooseCategory(),
            child: Container(
              height: 58,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Categoria',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category,
                    style: const TextStyle(
                      color: AppColors.wine,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 34),
          _CoverPicker(
            selected: coverAdded,
            onTap: () => setState(() => coverAdded = !coverAdded),
          ),
          const SizedBox(height: 28),
          const _EditorToolbar(),
          TextField(
            controller: body,
            minLines: 8,
            maxLines: 16,
            style: const TextStyle(fontSize: 18, height: 1.45),
            decoration: const InputDecoration(
              hintText: 'Começa a escrever...',
              hintStyle: TextStyle(color: AppColors.muted, fontSize: 18),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _chooseCategory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories
              .map(
                (item) => ListTile(
                  title: Text(item),
                  trailing: category == item
                      ? const Icon(Icons.check, color: AppColors.wine)
                      : null,
                  onTap: () {
                    setState(() => category = item);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ContentTypeData {
  final String label;
  final String title;
  final IconData icon;
  const _ContentTypeData(this.label, this.title, this.icon);
}

const _types = [
  _ContentTypeData('Article', 'artigo', Icons.article_outlined),
  _ContentTypeData('Video', 'vídeo', Icons.video_library_outlined),
  _ContentTypeData('Podcast', 'podcast', Icons.podcasts_outlined),
];

class _TypeButton extends StatelessWidget {
  final _ContentTypeData data;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.wineBg : AppColors.card,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: selected ? AppColors.wine : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              color: selected ? AppColors.wine : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              data.label,
              style: TextStyle(
                color: selected ? AppColors.textMain : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPicker extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CoverPicker({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 185,
        decoration: BoxDecoration(
          color: selected ? AppColors.wineBg : AppColors.card,
          border: Border.all(
            color: selected ? AppColors.wine : AppColors.textSecondary,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: selected ? AppColors.wine : AppColors.textSecondary,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.winePill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    selected ? Icons.check : Icons.add_a_photo_outlined,
                    color: AppColors.wine,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  selected ? 'Capa adicionada' : 'Adicionar capa',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Recomendado: 1200 × 675px',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 6.0;
    const gap = 5.0;
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.textSecondary)),
      ),
      child: Row(
        children: const [
          Icon(Icons.format_bold, color: AppColors.textSecondary, size: 18),
          SizedBox(width: 22),
          Icon(Icons.format_italic, color: AppColors.textSecondary, size: 18),
          SizedBox(width: 22),
          Icon(Icons.format_quote, color: AppColors.textSecondary, size: 18),
          SizedBox(width: 22),
          Icon(
            Icons.format_list_bulleted,
            color: AppColors.textSecondary,
            size: 18,
          ),
          SizedBox(width: 22),
          Icon(Icons.link, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }
}
