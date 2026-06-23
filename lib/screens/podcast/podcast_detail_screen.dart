import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PodcastDetailScreen extends StatefulWidget {
  final PodcastEpisode episode;

  const PodcastDetailScreen({super.key, required this.episode});

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  late double _progress;
  late int _elapsedSeconds;
  late int _totalSeconds;
  bool _isPlaying = false;
  bool _saved = false;
  int _speedIndex = 0;

  static const _speeds = ['1× velocidade', '1,25× velocidade', '1,5× velocidade', '2× velocidade'];

  @override
  void initState() {
    super.initState();
    _progress = widget.episode.progress;
    _totalSeconds = _parseTime(widget.episode.total);
    _elapsedSeconds = (_totalSeconds * _progress).round();
  }

  int _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatTime(int seconds) {
    final clamped = seconds.clamp(0, _totalSeconds);
    final m = clamped ~/ 60;
    final s = clamped % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isPlaying ? 'A reproduzir…' : 'Reprodução em pausa'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _skip(int deltaSeconds) {
    setState(() {
      _elapsedSeconds = (_elapsedSeconds + deltaSeconds).clamp(0, _totalSeconds);
      _progress = _totalSeconds == 0 ? 0 : _elapsedSeconds / _totalSeconds;
    });
  }

  void _seek(double value) {
    setState(() {
      _progress = value.clamp(0.0, 1.0);
      _elapsedSeconds = (_totalSeconds * _progress).round();
    });
  }

  void _cycleSpeed() {
    setState(() => _speedIndex = (_speedIndex + 1) % _speeds.length);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_speeds[_speedIndex])),
    );
  }

  void _toggleSaved() {
    setState(() => _saved = !_saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _saved ? 'Episódio guardado' : 'Removido dos guardados',
        ),
      ),
    );
  }

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link do episódio copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;

    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        toolbarHeight: 62,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.wine, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isPlaying ? 'A reproduzir…' : 'Agora Tocando...',
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 42, 20, 26),
        children: [
          Text(
            episode.show,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _togglePlay,
            child: _CoverArt(color: episode.accent, isPlaying: _isPlaying),
          ),
          const SizedBox(height: 20),
          Text(
            'Ep. ${episode.number} · ${episode.duration}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              episode.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            episode.host,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 34),
          _ProgressBar(
            progress: _progress,
            elapsed: _formatTime(_elapsedSeconds),
            total: _formatTime(_totalSeconds),
            accent: episode.accent,
            onSeek: _seek,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                onTap: _cycleSpeed,
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _speeds[_speedIndex],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          _Controls(
            color: episode.accent,
            isPlaying: _isPlaying,
            onPlayPause: _togglePlay,
            onSkipBack: () => _skip(-10),
            onSkipForward: () => _skip(10),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _saved ? Icons.bookmark : Icons.bookmark_border,
                  color: _saved ? AppColors.wine : AppColors.muted,
                  size: 22,
                ),
                onPressed: _toggleSaved,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.share_outlined,
                  color: AppColors.muted,
                  size: 22,
                ),
                onPressed: _share,
              ),
            ],
          ),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 18),
          const Text(
            'SOBRE ESTE EPISÓDIO',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            episode.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverArt extends StatelessWidget {
  final Color color;
  final bool isPlaying;

  const _CoverArt({required this.color, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(13),
          border: isPlaying
              ? Border.all(color: color.withValues(alpha: .5), width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (final height in const [26.0, 42.0, 56.0, 38.0, 48.0])
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 6,
                      height: isPlaying ? height : height * .6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
            ),
            if (!isPlaying)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final String elapsed;
  final String total;
  final Color accent;
  final ValueChanged<double> onSeek;

  const _ProgressBar({
    required this.progress,
    required this.elapsed,
    required this.total,
    required this.accent,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 24,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final knobLeft = (constraints.maxWidth * progress - 5.5)
                  .clamp(0.0, constraints.maxWidth - 11);
              return GestureDetector(
                onTapDown: (details) {
                  onSeek(details.localPosition.dx / constraints.maxWidth);
                },
                onHorizontalDragUpdate: (details) {
                  onSeek(details.localPosition.dx / constraints.maxWidth);
                },
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned(
                      left: knobLeft,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              elapsed,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              total,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  final Color color;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBack;
  final VoidCallback onSkipForward;

  const _Controls({
    required this.color,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onSkipBack,
    required this.onSkipForward,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SkipButton(icon: Icons.replay_10, onPressed: onSkipBack),
        const SizedBox(width: 34),
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 4,
          shadowColor: color.withValues(alpha: .22),
          child: InkWell(
            onTap: onPlayPause,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(width: 34),
        _SkipButton(icon: Icons.forward_10, onPressed: onSkipForward),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SkipButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.textSecondary, size: 24),
    );
  }
}

class PodcastEpisode {
  final String show;
  final int number;
  final String duration;
  final String title;
  final String host;
  final String elapsed;
  final String total;
  final double progress;
  final String description;
  final Color accent;

  const PodcastEpisode({
    required this.show,
    required this.number,
    required this.duration,
    required this.title,
    required this.host,
    required this.elapsed,
    required this.total,
    required this.progress,
    required this.description,
    required this.accent,
  });
}

const featuredPodcast = PodcastEpisode(
  show: 'Economia em Foco',
  number: 3,
  duration: '22 min',
  title: 'Mulheres nos negócios angolanos',
  host: 'Prof. Ana Silva',
  elapsed: '05:30',
  total: '22:00',
  progress: .32,
  accent: AppColors.wine,
  description:
      'A participação feminina no empresariado em Angola tem crescido significativamente. Neste episódio, exploramos os desafios e as vitórias das empreendedoras nacionais...',
);
