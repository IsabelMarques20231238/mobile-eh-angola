import 'package:flutter/material.dart';

class ForumSugestoesScreen extends StatefulWidget {
  const ForumSugestoesScreen({super.key});

  @override
  State<ForumSugestoesScreen> createState() => _ForumSugestoesScreenState();
}

class _ForumSugestoesScreenState extends State<ForumSugestoesScreen> {
  static const Color primaryColor = Color(0xFF8B1A3A);
  static const Color bgLight = Color(0xFFFDF5F7);

  String _areaTematica = 'Economia';
  final List<String> _areas = ['Economia', 'História', 'Política', 'Cultura', 'Ciências'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sugestões',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner ───────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sugere um tema que gostarias de ver no fórum ou como conteúdo.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF555555), height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Fazer sugestão', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Título da sugestão ────────────────────────────────────────
            const _FormLabel(text: 'TÍTULO DA SUGESTÃO'),
            const SizedBox(height: 6),
            _StyledInput(hintText: 'Ex: A influência da moeda Colonial...'),
            const SizedBox(height: 14),

            // ── Descreve o tema ───────────────────────────────────────────
            const _FormLabel(text: 'DESCREVE O TEMA...'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: const Color(0xFFE5E5E5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Explica brevemente o contexto histórico ou económico...',
                  hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Área temática ─────────────────────────────────────────────
            const _FormLabel(text: 'ÁREA TEMÁTICA'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E5E5)),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _areaTematica,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF888888)),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                  onChanged: (v) => setState(() => _areaTematica = v!),
                  items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Botão enviar ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Enviar sugestão',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Sugestões da comunidade ───────────────────────────────────
            const Text(
              'SUGESTÕES DA COMUNIDADE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFAAAAAA),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Card
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('ECONOMIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32), letterSpacing: 0.3)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Aprovada', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Card title
                  const Text(
                    'Impacto das Reformas Agrárias de 1992',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 10),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: const Color(0xFF7B1FA2),
                            child: const Text('MJ', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 6),
                          const Text('por Maria Joana', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
                        ],
                      ),
                      Row(
                        children: const [
                          Icon(Icons.keyboard_arrow_up, color: Color(0xFFE53935), size: 16),
                          Text('- 24', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE53935))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(activeIndex: 1),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFFAAAAAA),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StyledInput extends StatelessWidget {
  final String hintText;
  const _StyledInput({required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

// ─── Shared Bottom Nav ───────────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  final int activeIndex;
  const _BottomNavBar({required this.activeIndex});

  static const Color primaryColor = Color(0xFF8B1A3A);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: activeIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xFFAAAAAA),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 22), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.forum_outlined, size: 22), label: 'Fórum'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined, size: 22), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined, size: 22), label: 'Subscrições'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 22), label: 'Perfil'),
        ],
        onTap: (_) {},
      ),
    );
  }
}
