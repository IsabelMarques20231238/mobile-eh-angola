import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _pages = const [
    ('assets/images/onboarding1.jpg', 'Economia com História\nAngola', 'Aprender, debater e transformar\nrealidades', 'Artigos, vídeos e podcasts contextualizados\npara a realidade angolana.'),
    ('', 'Quiz interactivo com\nfeedback imediato', 'Responde, aprende com os erros e sobe no\nranking da tua instituição.', ''),
    ('', 'Debate, comenta e sugere\ntemas', 'Junta-te a outros estudantes e professores\nnuma comunidade académica activa.', ''),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.feed);
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _explore() {
    Navigator.pushReplacementNamed(context, AppRoutes.feed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: 3,
                onPageChanged: (v) => setState(() => _page = v),
                itemBuilder: (_, i) => _Page(data: _pages[i], index: i),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 24 : 5,
                    height: 5,
                    decoration: BoxDecoration(color: i == _page ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(4)),
                  )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
              child: SizedBox(width: double.infinity, height: 40, child: ElevatedButton(onPressed: _next, child: Text(_page == 0 ? 'Começar' : _page == 1 ? 'Continuar' : 'Explorar sem login'))),
            ),
            TextButton(onPressed: _explore, child: const Text('Saltar e explorar', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
            TextButton(onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login), child: const Text('Entrar ou criar conta', style: TextStyle(fontSize: 11, color: AppColors.primary))),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  final (String, String, String, String) data;
  final int index;
  const _Page({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 0),
      child: Column(
        children: [
          SizedBox(
            height: 210,
            width: double.infinity,
            child: index == 0 ? _cityImage() : index == 1 ? _quizMock() : _communityMock(),
          ),
          const SizedBox(height: 30),
          Text(data.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, height: 1.12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(data.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.45, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
          if (data.$4.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(data.$4, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.45, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  Widget _cityImage() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: 6,
          left: 18,
          right: 18,
          child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(data.$1, fit: BoxFit.cover)),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Transform.rotate(
            angle: -0.09,
            child: Container(width: 76, height: 76, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.school_outlined, color: Colors.white, size: 34)),
          ),
        ),
      ],
    );
  }

  Widget _quizMock() {
    return Container(
      color: AppColors.accent,
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 0),
      child: Column(
        children: [
          Align(alignment: Alignment.centerRight, child: _score()),
          _line(100, AppColors.accentMid),
          const SizedBox(height: 8),
          _box(36),
          const SizedBox(height: 8),
          _box(28, fill: AppColors.primary),
          const SizedBox(height: 8),
          _box(28),
          const SizedBox(height: 8),
          _box(28),
        ],
      ),
    );
  }

  Widget _communityMock() {
    return Container(
      color: const Color(0xFFE6F6EA),
      padding: const EdgeInsets.all(26),
      child: Stack(
        children: [
          Align(alignment: Alignment.topLeft, child: _bubble(150, 48, Icons.person_outline, true)),
          Align(alignment: Alignment.centerRight, child: _bubble(160, 52, Icons.chat_bubble_outline, false)),
          const Positioned(left: 34, bottom: 40, child: Icon(Icons.favorite, color: AppColors.primary, size: 14)),
          const Positioned(right: 26, top: 88, child: Icon(Icons.forum_outlined, color: AppColors.success, size: 20)),
        ],
      ),
    );
  }

  Widget _line(double w, Color c) => Container(width: w, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)));
  Widget _box(double h, {Color fill = Colors.white}) => Container(height: h, decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(3), border: Border.all(color: AppColors.borderLight)));
  Widget _score() => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Text('7/10', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)));
  Widget _bubble(double w, double h, IconData icon, bool pink) => Container(width: w, height: h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: pink ? AppColors.primary : AppColors.success, size: 18));
}
