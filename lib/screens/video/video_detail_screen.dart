import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class VideoDetailScreen extends StatefulWidget {
  final VideoLesson video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late double _progress;
  late int _elapsedSeconds;
  late int _totalSeconds;
  bool _isPlaying = false;
  bool _saved = false;
  bool _liked = false;
  bool _descriptionExpanded = false;
  late int _likeCount;
  late int _commentCount;
  final _commentController = TextEditingController();
  final List<_VideoComment> _comments = [
    const _VideoComment(
      author: 'Maria K.',
      text: 'Explicação muito clara sobre a inflação!',
      timeAgo: 'Há 1h',
      likes: 4,
    ),
    const _VideoComment(
      author: 'João F.',
      text: 'Seria útil um episódio sobre o período 1999–2002.',
      timeAgo: 'Ontem',
      likes: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progress = widget.video.progress;
    _totalSeconds = _parseTime(widget.video.total);
    _elapsedSeconds = (_totalSeconds * _progress).round();
    _likeCount = widget.video.likes;
    _commentCount = widget.video.commentCount;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
  }

  void _seek(double value) {
    setState(() {
      _progress = value.clamp(0.0, 1.0);
      _elapsedSeconds = (_totalSeconds * _progress).round();
    });
  }

  void _toggleSaved() {
    setState(() => _saved = !_saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_saved ? 'Vídeo guardado' : 'Removido dos guardados'),
      ),
    );
  }

  void _share() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link do vídeo copiado')),
    );
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .55,
        minChildSize: .4,
        maxChildSize: .9,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$_commentCount comentários',
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _comments.length,
                  separatorBuilder: (_, _) => const Divider(height: 20),
                  itemBuilder: (context, index) => _VideoCommentCard(
                    key: ValueKey(index),
                    comment: _comments[index],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(
        0,
        _VideoComment(author: 'Tu', text: text, timeAgo: 'Agora'),
      );
      _commentCount++;
      _commentController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comentário publicado')),
    );
  }

  void _openRelated(RelatedVideo item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('A abrir: ${item.title}')),
    );
  }

  Future<void> _enterFullscreen() async {
    final result = await Navigator.of(context).push<_FullscreenPlaybackResult>(
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (_, _, _) => _VideoFullscreenPage(
          title: widget.video.title,
          isPlaying: _isPlaying,
          progress: _progress,
          elapsed: _formatTime(_elapsedSeconds),
          total: _formatTime(_totalSeconds),
        ),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _isPlaying = result.isPlaying;
        _progress = result.progress;
        _elapsedSeconds = result.elapsedSeconds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final description = _descriptionExpanded
        ? video.description
        : _truncate(video.description, 120);

    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        toolbarHeight: 62,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.wine, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: Icon(
              _saved ? Icons.bookmark : Icons.bookmark_border,
              color: AppColors.wine,
              size: 21,
            ),
            onPressed: _toggleSaved,
          ),
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.wine,
              size: 22,
            ),
            onPressed: _share,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 78),
        children: [
          _VideoPlayer(
            isPlaying: _isPlaying,
            progress: _progress,
            elapsed: _formatTime(_elapsedSeconds),
            total: _formatTime(_totalSeconds),
            onTogglePlay: _togglePlay,
            onSeek: _seek,
            onFullscreen: _enterFullscreen,
            isFullscreen: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 34, 15, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _VideoBadge(label: 'Vídeo'),
                    const SizedBox(width: 16),
                    Text(
                      video.durationLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  video.title,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.winePill,
                      child: Text(
                        video.authorInitials,
                        style: const TextStyle(
                          color: AppColors.wine,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.author,
                          style: const TextStyle(
                            color: AppColors.wine,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          video.date,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                if (video.description.length > 120)
                  TextButton(
                    onPressed: () =>
                        setState(() => _descriptionExpanded = !_descriptionExpanded),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.wine,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(64, 30),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      _descriptionExpanded ? 'Ver menos' : 'Ver mais',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 32, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                InkWell(
                  onTap: _toggleLike,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        Icon(
                          _liked ? Icons.favorite : Icons.favorite_border,
                          color: _liked ? AppColors.wine : AppColors.textSecondary,
                          size: 19,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$_likeCount',
                          style: TextStyle(
                            color: _liked ? AppColors.wine : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: _showComments,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$_commentCount comentários',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CONTEÚDO RELACIONADO',
                  style: TextStyle(
                    color: AppColors.wine,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 152,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: video.related.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) => _RelatedVideoCard(
                      item: video.related[index],
                      onTap: () => _openRelated(video.related[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _VideoCommentBar(
        controller: _commentController,
        onSend: _sendComment,
      ),
    );
  }

  String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }
}

class _VideoComment {
  final String author;
  final String text;
  final String timeAgo;
  final int likes;

  const _VideoComment({
    required this.author,
    required this.text,
    required this.timeAgo,
    this.likes = 0,
  });
}

class _VideoCommentCard extends StatefulWidget {
  final _VideoComment comment;
  const _VideoCommentCard({super.key, required this.comment});

  @override
  State<_VideoCommentCard> createState() => _VideoCommentCardState();
}

class _VideoCommentCardState extends State<_VideoCommentCard> {
  late int _likes;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.comment.likes;
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.muted),
              title: const Text('Reportar'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: AppColors.muted),
              title: const Text('Copiar texto'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppColors.muted),
              title: const Text('Partilhar'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.comment.author
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    const indent = 46.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.winePill,
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.wine,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.comment.author,
                      style: const TextStyle(
                        color: AppColors.textMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' • ${widget.comment.timeAgo}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: indent),
          child: Text(
            widget.comment.text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: indent - 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Row(
                  children: [
                    Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      color: _liked ? AppColors.wine : AppColors.muted,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_likes',
                      style: TextStyle(
                        color: _liked ? AppColors.wine : AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Responder',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showOptions,
                child: const Icon(
                  Icons.more_horiz,
                  color: AppColors.muted,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FullscreenPlaybackResult {
  final bool isPlaying;
  final double progress;
  final int elapsedSeconds;

  const _FullscreenPlaybackResult({
    required this.isPlaying,
    required this.progress,
    required this.elapsedSeconds,
  });
}

class _VideoFullscreenPage extends StatefulWidget {
  final String title;
  final bool isPlaying;
  final double progress;
  final String elapsed;
  final String total;

  const _VideoFullscreenPage({
    required this.title,
    required this.isPlaying,
    required this.progress,
    required this.elapsed,
    required this.total,
  });

  @override
  State<_VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<_VideoFullscreenPage> {
  late bool _isPlaying;
  late double _progress;
  late String _elapsed;
  late String _total;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
    _progress = widget.progress;
    _elapsed = widget.elapsed;
    _total = widget.total;
    _enableFullscreenMode();
  }

  Future<void> _enableFullscreenMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _restoreSystemUi();
    super.dispose();
  }

  void _exit() {
    final parts = _elapsed.split(':');
    final elapsedSeconds = parts.length == 2
        ? int.parse(parts[0]) * 60 + int.parse(parts[1])
        : 0;
    Navigator.pop(
      context,
      _FullscreenPlaybackResult(
        isPlaying: _isPlaying,
        progress: _progress,
        elapsedSeconds: elapsedSeconds,
      ),
    );
  }

  void _togglePlay() => setState(() => _isPlaying = !_isPlaying);

  void _seek(double value) {
    setState(() {
      _progress = value.clamp(0.0, 1.0);
      final parts = _total.split(':');
      if (parts.length == 2) {
        final totalSeconds = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        final elapsedSeconds = (totalSeconds * _progress).round();
        _elapsed = _formatSeconds(elapsedSeconds);
      }
    });
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoPlayerSurface(
                isPlaying: _isPlaying,
                onTogglePlay: _togglePlay,
                showCenterButton: true,
              ),
              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 56,
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: _exit,
                          icon: const Icon(
                            Icons.fullscreen_exit,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: _VideoPlayerControls(
                          elapsed: _elapsed,
                          total: _total,
                          progress: _progress,
                          onSeek: _seek,
                          onFullscreen: _exit,
                          isFullscreen: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPlayer extends StatelessWidget {
  final bool isPlaying;
  final double progress;
  final String elapsed;
  final String total;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onSeek;
  final VoidCallback onFullscreen;
  final bool isFullscreen;

  const _VideoPlayer({
    required this.isPlaying,
    required this.progress,
    required this.elapsed,
    required this.total,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onFullscreen,
    required this.isFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: const Color(0xFF111417),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _VideoPlayerSurface(
              isPlaying: isPlaying,
              onTogglePlay: onTogglePlay,
              showCenterButton: true,
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: _VideoPlayerControls(
                elapsed: elapsed,
                total: total,
                progress: progress,
                onSeek: onSeek,
                onFullscreen: onFullscreen,
                isFullscreen: isFullscreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerSurface extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final bool showCenterButton;

  const _VideoPlayerSurface({
    required this.isPlaying,
    required this.onTogglePlay,
    required this.showCenterButton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: .86,
              colors: [
                Color(0xFF1B6972),
                Color(0xFF17343A),
                Color(0xFF111417),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: .18,
            child: GridPaper(
              color: Colors.white,
              divisions: 2,
              subdivisions: 2,
              interval: 38,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        GestureDetector(
          onTap: onTogglePlay,
          behavior: HitTestBehavior.opaque,
          child: showCenterButton
              ? Center(
                  child: AnimatedOpacity(
                    opacity: isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .38),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .52),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.expand(),
        ),
      ],
    );
  }
}

class _VideoPlayerControls extends StatelessWidget {
  final String elapsed;
  final String total;
  final double progress;
  final ValueChanged<double> onSeek;
  final VoidCallback onFullscreen;
  final bool isFullscreen;

  const _VideoPlayerControls({
    required this.elapsed,
    required this.total,
    required this.progress,
    required this.onSeek,
    required this.onFullscreen,
    required this.isFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$elapsed / $total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (d) =>
                    onSeek(d.localPosition.dx / constraints.maxWidth),
                onHorizontalDragUpdate: (d) =>
                    onSeek(d.localPosition.dx / constraints.maxWidth),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: progress,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation(AppColors.wine),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: onFullscreen,
          icon: Icon(
            isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            color: Colors.white,
            size: 22,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }
}

class _VideoBadge extends StatelessWidget {
  final String label;

  const _VideoBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.winePill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.wine,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RelatedVideoCard extends StatelessWidget {
  final RelatedVideo item;
  final VoidCallback onTap;

  const _RelatedVideoCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 222,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: item.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      left: -34,
                      top: -8,
                      bottom: -8,
                      child: Icon(
                        Icons.map,
                        size: 164,
                        color: Colors.black.withValues(alpha: .46),
                      ),
                    ),
                    Positioned(
                      right: 24,
                      top: 24,
                      child: Icon(
                        item.icon,
                        color: Colors.white.withValues(alpha: .88),
                        size: 48,
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white70,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCommentBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _VideoCommentBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 9),
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Adicionar comentário...',
                  hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF7F5F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.wine),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton.filled(
                onPressed: onSend,
                style: IconButton.styleFrom(backgroundColor: AppColors.wine),
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoLesson {
  final String title;
  final String author;
  final String authorInitials;
  final String date;
  final String durationLabel;
  final String elapsed;
  final String total;
  final double progress;
  final String description;
  final int likes;
  final int commentCount;
  final List<RelatedVideo> related;

  const VideoLesson({
    required this.title,
    required this.author,
    required this.authorInitials,
    required this.date,
    required this.durationLabel,
    required this.elapsed,
    required this.total,
    required this.progress,
    required this.description,
    required this.likes,
    required this.commentCount,
    required this.related,
  });
}

class RelatedVideo {
  final String title;
  final Color accent;
  final IconData icon;

  const RelatedVideo({
    required this.title,
    required this.accent,
    required this.icon,
  });
}

const featuredVideo = VideoLesson(
  title: 'Inflação em Angola: causas históricas e impacto actual',
  author: 'Prof. Carlos Manuel',
  authorInitials: 'MJ',
  date: 'Ontem',
  durationLabel: '13 MIN',
  elapsed: '03:24',
  total: '12:47',
  progress: .27,
  likes: 12,
  commentCount: 8,
  description:
      'Uma análise profunda sobre a evolução dos preços em Angola, desde o período pós-independência até aos desafios contemporâneos da diversificação económica e o papel do Banco Nacional de Angola na estabilização monetária.',
  related: [
    RelatedVideo(
      title: 'O Milagre do Petróleo: Desafios e Oportunidades',
      accent: Color(0xFFD3232F),
      icon: Icons.local_fire_department,
    ),
    RelatedVideo(
      title: 'A Estrutura Económica no séc. XIX',
      accent: Color(0xFF2F4E55),
      icon: Icons.account_balance,
    ),
  ],
);
