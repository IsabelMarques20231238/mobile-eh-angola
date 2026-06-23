import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class CriarTopicoScreen extends StatefulWidget {
  const CriarTopicoScreen({super.key});

  @override
  State<CriarTopicoScreen> createState() => _CriarTopicoScreenState();
}

class _CriarTopicoScreenState extends State<CriarTopicoScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _keywordController = TextEditingController();

  bool _isPrivate = false;
  bool _readOnly = false;
  String _selectedCategory = 'Economia';
  final List<String> _hashTags = [];

  final _categories = const [
    'Economia',
    'História',
    'Política',
    'Petróleo',
    'Cidadania',
    'Sugestões',
  ];

  final _hashTagSuggestions = const [
    '#economia',
    '#historia',
    '#politica',
    '#petroleo',
    '#cidadania',
    '#kwanza',
    '#mercado',
    '#independencia',
  ];

  List<String> get _visibleHashTagSuggestions {
    final query = _keywordController.text.trim().toLowerCase();
    return _hashTagSuggestions.where((tag) {
      final notAdded = !_hashTags.contains(tag);
      if (query.isEmpty || query == '#') return notAdded;
      final normalized = query.startsWith('#') ? query : '#$query';
      return notAdded && tag.contains(normalized);
    }).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Criar Tópico'),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderLight),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
        children: [
          const _FieldLabel('Título'),
          TextField(
            controller: _titleController,
            maxLength: 120,
            decoration: const InputDecoration(
              hintText: 'O que queres discutir?',
              hintStyle: TextStyle(
                fontSize: 18,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    Text(
                      '$currentLength/$maxLength',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.muted,
                      ),
                    ),
          ),
          const Divider(height: 26, color: AppColors.borderLight),
          const Text(
            'Categoria',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.textSecondary,
            ),
            items: _categories
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedCategory = value ?? _selectedCategory),
            style: const TextStyle(fontSize: 13, color: AppColors.textMain),
          ),
          const SizedBox(height: 20),
          const Text(
            'Visibilidade',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _VisOption(
                  icon: Icons.public,
                  title: 'Público',
                  subtitle: 'Qualquer um pode ver e responder',
                  selected: !_isPrivate,
                  onTap: () => setState(() => _isPrivate = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _VisOption(
                  icon: Icons.lock_outline,
                  title: 'Privado',
                  subtitle: 'Só por convite + aprovação',
                  selected: _isPrivate,
                  onTap: () => setState(() => _isPrivate = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apenas leitura',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Membros só podem visualizar, sem responder',
                      style: TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              AppToggle(
                value: _readOnly,
                onChanged: (value) => setState(() => _readOnly = value),
              ),
            ],
          ),
          const Divider(height: 26, color: AppColors.borderLight),
          const _FieldLabel('Descrição (opcional)'),
          TextField(
            controller: _descController,
            minLines: 5,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Adiciona contexto ou detalhes...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _ToolbarIcon(Icons.format_bold),
              _ToolbarIcon(Icons.format_italic),
              _ToolbarIcon(Icons.format_list_bulleted),
              _ToolbarIcon(Icons.link),
            ],
          ),
          const Divider(height: 26, color: AppColors.borderLight),
          const _FieldLabel('Hash-tags'),
          TextField(
            controller: _keywordController,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _addHashTag(),
            decoration: const InputDecoration(
              hintText: 'Adiciona hash-tags separadas por Enter',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (_hashTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _hashTags
                  .map(
                    (tag) => _HashTagChip(
                      label: tag,
                      onRemove: () => setState(() => _hashTags.remove(tag)),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (_visibleHashTagSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _visibleHashTagSuggestions
                  .map(
                    (tag) => ActionChip(
                      label: Text(tag),
                      onPressed: () => _addHashTag(tag),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.wine,
                      ),
                      side: const BorderSide(color: AppColors.borderLight),
                      backgroundColor: AppColors.wineBg,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _createTopic,
            child: const Text('Criar tópico'),
          ),
        ),
      ),
    );
  }

  void _addHashTag([String? suggestion]) {
    final tag = _normalizeHashTag(suggestion ?? _keywordController.text);
    if (tag == null || _hashTags.contains(tag)) return;
    setState(() {
      _hashTags.add(tag);
      _keywordController.clear();
    });
  }

  String? _normalizeHashTag(String value) {
    final clean = value.trim().toLowerCase().replaceAll(' ', '');
    if (clean.isEmpty || clean == '#') return null;
    return clean.startsWith('#') ? clean : '#$clean';
  }

  void _createTopic() {
    if (_isPrivate) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _PrivateForumCreatedDialog(),
      );
      return;
    }

    showAppToast(context, 'Tópico criado!');
    Navigator.pop(context);
  }
}

class _HashTagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _HashTagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: AppColors.wineBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.wine,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: AppColors.muted,
    ),
  );
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  const _ToolbarIcon(this.icon);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Icon(icon, size: 14, color: AppColors.muted),
  );
}

class _VisOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _VisOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.wineBg : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? AppColors.wine : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? AppColors.wine : AppColors.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.wine : AppColors.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.muted,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PrivateForumCreatedDialog extends StatefulWidget {
  const _PrivateForumCreatedDialog();

  @override
  State<_PrivateForumCreatedDialog> createState() =>
      _PrivateForumCreatedDialogState();
}

class _PrivateForumCreatedDialogState
    extends State<_PrivateForumCreatedDialog> {
  final _memberController = TextEditingController();
  final List<String> _members = ['ana.paula@...'];

  @override
  void dispose() {
    _memberController.dispose();
    super.dispose();
  }

  void _addMember() {
    final value = _memberController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _members.add(value);
      _memberController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA9E6B4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: Color(0xFF137A35),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tópico privado criado!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMain,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Partilha o acesso com os membros.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              const Text(
                'CÓDIGO DE ACESSO',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 36,
                padding: const EdgeInsets.only(left: 10, right: 6),
                decoration: BoxDecoration(
                  color: AppColors.wineBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'EH-4F2K-9R',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.wine,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 22,
                      child: TextButton(
                        onPressed: () {
                          showAppToast(context, 'Código copiado!');
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.winePill,
                          foregroundColor: AppColors.wine,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Copiar',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              const Text(
                'CONVIDAR MEMBROS',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: _memberController,
                        decoration: const InputDecoration(
                          hintText: 'Email do membro...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                        ),
                        style: const TextStyle(fontSize: 11),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addMember(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 58,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _addMember,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _members
                    .map(
                      (member) => _InviteChip(
                        label: member,
                        onRemove: () => setState(() => _members.remove(member)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 37),
              SizedBox(
                height: 26,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  child: const Text(
                    'Enviar convites',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
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

class _InviteChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _InviteChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.fromLTRB(5, 2, 7, 2),
      decoration: BoxDecoration(
        color: AppColors.wineBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 7,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=64&h=64&fit=crop&crop=face',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
