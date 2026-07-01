import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/forum_models.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../services/forum_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_preview_field.dart';
import '../../widgets/shared_widgets.dart';

class CriarTopicoScreen extends StatefulWidget {
  /// When provided, the screen opens in edit mode.
  final ForumTopic? editTopic;
  final String? editBody;
  final List<String> editTags;

  const CriarTopicoScreen({
    super.key,
    this.editTopic,
    this.editBody,
    this.editTags = const [],
  });

  @override
  State<CriarTopicoScreen> createState() => _CriarTopicoScreenState();
}

class _CriarTopicoScreenState extends State<CriarTopicoScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _keywordController = TextEditingController();

  bool _isPrivate = false;
  bool _readOnly = false;
  ForumCategory? _selectedCategory;
  List<String> _hashTags = [];
  // Maps normalized tag label (e.g. '#petróleo') → tag ID for tags picked from API suggestions
  final Map<String, int> _tagIdMap = {};
  XFile? _selectedImage;
  String? _validatedImageUrl;
  bool _isPublishing = false;
  String? _titleError;
  String? _bodyError;

  bool get _isEditing => widget.editTopic != null;

  bool get _canSetPrivate {
    final roles = AuthState.instance.user?.roles ?? [];
    return roles.any((r) => r == 'AUTHOR' || r == 'ADMIN' || r == 'SUPER_ADMIN');
  }

  List<ForumCategory> _categories = const [];
  List<ForumTag> _tagSuggestions = [];
  bool _tagsLoading = false;
  Timer? _tagDebounce;

  static const _fallbackCategories = [
    ForumCategory(id: 0, name: 'Economia'),
    ForumCategory(id: 0, name: 'História'),
    ForumCategory(id: 0, name: 'Política'),
    ForumCategory(id: 0, name: 'Petróleo'),
    ForumCategory(id: 0, name: 'Cidadania'),
  ];

  List<ForumTag> get _visibleSuggestions => _tagSuggestions
      .where((t) => !_hashTags.contains('#${t.name.toLowerCase()}'))
      .take(10)
      .toList();


  Future<void> _fetchTags(String query) async {
    setState(() => _tagsLoading = true);
    try {
      final results = await ForumService.instance.getTags(query);
      if (mounted) setState(() => _tagSuggestions = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _tagsLoading = false);
    }
  }

  void _onTagQueryChanged(String value) {
    _tagDebounce?.cancel();
    final q = value.trim().replaceAll('#', '');
    if (q.isEmpty) {
      setState(() => _tagSuggestions = []);
      return;
    }
    _tagDebounce = Timer(const Duration(milliseconds: 350), () => _fetchTags(q));
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    final t = widget.editTopic;
    if (t != null) {
      _titleController.text = t.title;
      _descController.text = widget.editBody ?? t.excerpt;
      _imageUrlController.text = t.imageUrl ?? '';
      _validatedImageUrl = t.imageUrl?.isNotEmpty == true ? t.imageUrl : null;
      _isPrivate = t.visibility == TopicVisibility.privado;
      _readOnly = t.isReadOnly;
      _hashTags = List<String>.from(
        widget.editTags.map((tag) => tag.startsWith('#') ? tag : '#$tag'),
      );
    }
    _titleController.addListener(() {
      if (_titleError != null && _titleController.text.trim().isNotEmpty) {
        setState(() => _titleError = null);
      }
    });
    _descController.addListener(() {
      if (_bodyError != null && _descController.text.trim().isNotEmpty) {
        setState(() => _bodyError = null);
      }
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await ForumService.instance.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats.isNotEmpty ? cats : _fallbackCategories;
      final editId = widget.editTopic?.categoryId ?? 0;
      if (editId > 0) {
        _selectedCategory = _categories.firstWhere(
          (c) => c.id == editId,
          orElse: () => _categories.first,
        );
      } else {
        _selectedCategory = _categories.first;
      }
    });
  }

  @override
  void dispose() {
    _tagDebounce?.cancel();
    _titleController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Navigator.pop(context),
              onCancel: () => Navigator.pop(context),
              onPublish: _isPublishing ? null : _createTopic,
              isPublishing: _isPublishing,
              isEditing: _isEditing,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
                children: [
                  // ── Título ──────────────────────────────────────
                  _label('Título'),
                  const SizedBox(height: 8),
                  _TitleField(
                    controller: _titleController,
                    errorText: _titleError,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // ── Categoria ───────────────────────────────────
                  _label('Categoria'),
                  const SizedBox(height: 8),
                  _CategoryDropdown(
                    categories: _categories,
                    selected: _selectedCategory,
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: 20),

                  // ── Visibilidade ─────────────────────────────────
                  _label('Visibilidade'),
                  const SizedBox(height: 8),
                  _VisCard(
                    icon: Icons.language_rounded,
                    title: 'Público',
                    subtitle: 'Todos podem ver (Publicação Pública)',
                    selected: !_isPrivate,
                    onTap: () => setState(() => _isPrivate = false),
                  ),
                  if (_canSetPrivate) ...[
                    const SizedBox(height: 8),
                    _VisCard(
                      icon: Icons.lock_outline_rounded,
                      title: 'Privado',
                      subtitle: 'Só por convite + aprovação',
                      selected: _isPrivate,
                      onTap: () => setState(() => _isPrivate = true),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Apenas leitura ───────────────────────────────
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
                            SizedBox(height: 2),
                            Text(
                              'Impedir novos comentários nesta discussão.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppToggle(
                        value: _readOnly,
                        onChanged: (v) => setState(() => _readOnly = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Descrição ────────────────────────────────────
                  Text.rich(
                    TextSpan(
                      text: 'Descrição ',
                      children: [
                        TextSpan(
                          text: '* (obrigatório)',
                          style: TextStyle(
                            color: AppColors.wine,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _bodyError != null
                            ? AppColors.error
                            : AppColors.borderLight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _descController,
                      minLines: 5,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: 'Adiciona contexto ou detalhes académicos...',
                        hintStyle: TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  if (_bodyError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5, left: 4),
                      child: Text(
                        _bodyError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Imagem do Tópico ─────────────────────────────
                  Text.rich(
                    TextSpan(
                      text: 'Imagem do Tópico ',
                      children: [
                        TextSpan(
                          text: '(opcional)',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedImage != null)
                    _SelectedImageTile(
                      name: _selectedImage!.name,
                      onRemove: () => setState(() => _selectedImage = null),
                    )
                  else if (_validatedImageUrl != null)
                    _UrlImagePreview(
                      url: _validatedImageUrl!,
                      onRemove: () => setState(() {
                        _validatedImageUrl = null;
                        _imageUrlController.clear();
                      }),
                    )
                  else
                    _ImageUploadBox(onTap: () => _pickImage(context)),
                  if (_validatedImageUrl == null && _selectedImage == null) ...[
                    const SizedBox(height: 10),
                    ImagePreviewField(
                      controller: _imageUrlController,
                      showInlinePreview: false,
                      onValidUrl: (url) => setState(() => _validatedImageUrl = url),
                      onInvalidUrl: () => setState(() => _validatedImageUrl = null),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Hashtags ─────────────────────────────────────
                  _label('Hashtags'),
                  const SizedBox(height: 8),
                  // Campo + botão +
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.label_outline_rounded,
                            color: AppColors.muted, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _keywordController,
                            textInputAction: TextInputAction.done,
                            onChanged: _onTagQueryChanged,
                            onSubmitted: (_) => _addHashTag(),
                            decoration: const InputDecoration(
                              hintText: 'Escreve uma hashtag...',
                              hintStyle: TextStyle(
                                  color: AppColors.muted, fontSize: 13),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                            ),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMain),
                          ),
                        ),
                        GestureDetector(
                          onTap: _addHashTag,
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.wine,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tags já adicionadas
                  if (_hashTags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _hashTags
                          .map((tag) => _HashTagChip(
                                label: tag,
                                onRemove: () => setState(() {
                                  _hashTags.remove(tag);
                                  _tagIdMap.remove(tag);
                                }),
                              ))
                          .toList(),
                    ),
                  ],
                  // Sugestões
                  if (_tagsLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator(
                          color: AppColors.wine, minHeight: 2),
                    )
                  else if (_visibleSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SUGESTÕES DE HASHTAGS:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _visibleSuggestions
                                  .map((tag) => GestureDetector(
                                        onTap: () =>
                                            _addHashTag('#${tag.name}', tag),
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 18),
                                          child: Text(
                                            '#${tag.name}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // ── Footer de segurança ──────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'A tua informação está segura. Apenas o moderador poderá ver o teu pedido.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textMain,
    ),
  );

  void _addHashTag([String? suggestion, ForumTag? tagObj]) {
    final tag = _normalizeHashTag(suggestion ?? _keywordController.text);
    if (tag == null || _hashTags.contains(tag)) return;
    setState(() {
      _hashTags.add(tag);
      if (tagObj != null) _tagIdMap[tag] = tagObj.id;
      _keywordController.clear();
    });
  }

  String? _normalizeHashTag(String value) {
    final clean = value.trim().toLowerCase().replaceAll(' ', '');
    if (clean.isEmpty || clean == '#') return null;
    return clean.startsWith('#') ? clean : '#$clean';
  }

  void _pickImage(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.wine),
              title: const Text('Câmara'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (file != null && mounted) {
                  setState(() => _selectedImage = file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.wine),
              title: const Text('Galeria'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (file != null && mounted) {
                  setState(() => _selectedImage = file);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Diálogo quando o utilizador escreveu uma URL mas ela não passou a validação.
  void _showNoImageWarningDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone centrado com fundo rosa
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAEA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.wine,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              // Título
              const Text(
                'Publicar sem Imagem?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              // Corpo
              const Text(
                'O URL da imagem de capa que introduziu é inválido. Se continuar, o seu tópico será publicado sem qualquer imagem de capa associada.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tem a certeza de que deseja publicar ainda assim?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.5),
              ),
              const SizedBox(height: 24),
              // Botões lado a lado
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: Color(0xFFCCCCCC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wine,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _imageUrlController.clear();
                          _validatedImageUrl = null;
                        });
                        _publishTopic();
                      },
                      child: const Text(
                        'Sim, Publicar',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createTopic() async {
    final title = _titleController.text.trim();
    final body = _descController.text.trim();

    // Validação inline — mostra erros directamente nos campos
    final titleErr = title.isEmpty ? 'O título é obrigatório.' : null;
    final bodyErr  = body.isEmpty  ? 'A descrição é obrigatória.' : null;
    if (titleErr != null || bodyErr != null) {
      setState(() { _titleError = titleErr; _bodyError = bodyErr; });
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.id <= 0) {
      showAppToast(context, 'Seleciona uma categoria válida.');
      return;
    }

    // URL escrita mas não validada com sucesso → avisa antes de publicar sem imagem
    final urlTyped = _imageUrlController.text.trim().isNotEmpty;
    if (urlTyped && _validatedImageUrl == null && _selectedImage == null) {
      _showNoImageWarningDialog();
      return;
    }

    _publishTopic();
  }

  Future<void> _publishTopic() async {
    final title = _titleController.text.trim();
    final body = _descController.text.trim();

    setState(() => _isPublishing = true);
    try {
      // Ficheiro local tem prioridade; caso contrário usa a URL já validada.
      String? coverImageUrl = _validatedImageUrl;
      if (_selectedImage != null) {
        coverImageUrl = await ApiClient.instance.uploadImage(_selectedImage!.path);
      }

      // Split tags: existing (from API suggestions, have ID) vs new (typed manually)
      final selectedTags = _hashTags
          .where((t) => _tagIdMap.containsKey(t))
          .map((t) => ForumTag(id: _tagIdMap[t]!, name: t.replaceFirst('#', '')))
          .toList();
      final newTagNames = _hashTags
          .where((t) => !_tagIdMap.containsKey(t))
          .toList();

      if (_isEditing) {
        await ForumService.instance.updateTopic(
          id: widget.editTopic!.id,
          title: title,
          body: body,
          categoryId: _selectedCategory!.id,
          isPrivate: _isPrivate,
          isReadOnly: _readOnly,
          coverImageUrl: coverImageUrl,
          selectedTags: selectedTags,
          newTagNames: newTagNames,
        );
        if (!mounted) return;
        showAppToast(context, 'Tópico actualizado!');
        Navigator.pop(context, true);
      } else {
        final result = await ForumService.instance.createTopic(
          title: title,
          body: body,
          categoryId: _selectedCategory!.id,
          isPrivate: _isPrivate,
          isReadOnly: _readOnly,
          coverImageUrl: coverImageUrl,
          selectedTags: selectedTags,
          newTagNames: newTagNames,
        );
        if (!mounted) return;
        if (_isPrivate) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _PrivateForumCreatedDialog(
              topicId: result.id,
              joinCode: result.joinCode,
            ),
          );
        } else {
          showAppToast(context, 'Tópico criado!');
          Navigator.pop(context);
        }
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final VoidCallback? onPublish;
  final bool isPublishing;
  final bool isEditing;

  const _Header({
    required this.onBack,
    required this.onCancel,
    required this.onPublish,
    this.isPublishing = false,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.wine, size: 20),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          Text(
            isEditing ? 'Editar\nTópico' : 'Criar\nTópico',
            style: const TextStyle(
              color: AppColors.wine,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onPublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wine,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Publicar',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Título field ────────────────────────────────────────────────────────────

class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final String? errorText;

  const _TitleField({
    required this.controller,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: 120,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    hintText: 'O que queres discutir?',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${controller.text.length}/120',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Categoria dropdown ──────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final List<ForumCategory> categories;
  final ForumCategory? selected;
  final ValueChanged<ForumCategory> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  static Widget _categoryIcon(String name) {
    final l = name.toLowerCase();
    if (l.contains('agricultur') || l.contains('agro'))                                           return const FaIcon(FontAwesomeIcons.tractor,       size: 15, color: AppColors.textSecondary);
    if (l.contains('comér') || l.contains('comer') || l.contains('mercad'))                       return const FaIcon(FontAwesomeIcons.store,         size: 15, color: AppColors.textSecondary);
    if (l.contains('finanç') || l.contains('financ') || l.contains('econ'))                       return const FaIcon(FontAwesomeIcons.chartLine,     size: 15, color: AppColors.textSecondary);
    if (l.contains('hist') || l.contains('cultur') || l.contains('tradição'))                     return const FaIcon(FontAwesomeIcons.book,          size: 15, color: AppColors.textSecondary);
    if (l.contains('petr') || l.contains('energ') || l.contains('gás') || l.contains('gas'))      return const FaIcon(FontAwesomeIcons.gasPump,       size: 15, color: AppColors.textSecondary);
    if (l.contains('polít') || l.contains('polit') || l.contains('govern') || l.contains('estado')) return const FaIcon(FontAwesomeIcons.landmark,    size: 15, color: AppColors.textSecondary);
    if (l.contains('tecnol') || l.contains('digital') || l.contains('inovat'))                    return const FaIcon(FontAwesomeIcons.laptop,        size: 15, color: AppColors.textSecondary);
    if (l.contains('saúde') || l.contains('saude') || l.contains('médic') || l.contains('medic')) return const FaIcon(FontAwesomeIcons.stethoscope,   size: 15, color: AppColors.textSecondary);
    if (l.contains('educ') || l.contains('ensino') || l.contains('escol'))                        return const FaIcon(FontAwesomeIcons.graduationCap, size: 15, color: AppColors.textSecondary);
    if (l.contains('desport') || l.contains('futebol') || l.contains('sport'))                    return const FaIcon(FontAwesomeIcons.futbol,        size: 15, color: AppColors.textSecondary);
    if (l.contains('social') || l.contains('socie') || l.contains('comuni'))                      return const FaIcon(FontAwesomeIcons.users,         size: 15, color: AppColors.textSecondary);
    if (l.contains('ambient') || l.contains('natur') || l.contains('ecolog'))                     return const FaIcon(FontAwesomeIcons.leaf,          size: 15, color: AppColors.textSecondary);
    if (l.contains('arte') || l.contains('músic') || l.contains('music') || l.contains('cine'))   return const FaIcon(FontAwesomeIcons.music,         size: 15, color: AppColors.textSecondary);
    if (l.contains('negóci') || l.contains('negoci') || l.contains('empresa'))                    return const FaIcon(FontAwesomeIcons.briefcase,     size: 15, color: AppColors.textSecondary);
    return const FaIcon(FontAwesomeIcons.tag, size: 15, color: AppColors.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    final items = categories.isEmpty
        ? [DropdownMenuItem<ForumCategory>(
            value: selected,
            child: const Text('A carregar categorias…',
                style: TextStyle(fontSize: 14, color: AppColors.muted)),
          )]
        : categories.map((cat) => DropdownMenuItem<ForumCategory>(
            value: cat,
            child: Row(children: [
              _categoryIcon(cat.name),
              const SizedBox(width: 10),
              Text(cat.name, style: const TextStyle(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w500)),
            ]),
          )).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ForumCategory>(
          value: selected,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 20),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Visibilidade card ───────────────────────────────────────────────────────

class _VisCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _VisCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.wineBg : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.wine : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.winePill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.wine, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: selected ? AppColors.wine : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.wine : AppColors.muted,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.wine,
                ),
              ),
            )
          : null,
    );
  }
}

// ── Selected image tile ─────────────────────────────────────────────────────

class _SelectedImageTile extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const _SelectedImageTile({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.wineBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.wine.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_outlined, color: AppColors.wine, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.wine,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 18, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ── URL image preview (replaces upload box when URL is valid) ──────────────

class _UrlImagePreview extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _UrlImagePreview({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: double.infinity,
            height: 180,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.wineBg,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.muted,
                  size: 36,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xCC000000),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Image upload box (dashed border) ───────────────────────────────────────

class _ImageUploadBox extends StatelessWidget {
  final VoidCallback onTap;
  const _ImageUploadBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(
                  Icons.upload_rounded,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Adicionar imagem',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'PNG, JPG, GIF até 5MB',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFFCBD5E1);
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const radius = 12.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius),
        ),
      );

    double distance = 0;
    bool drawing = true;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final segLen = drawing ? dashWidth : dashSpace;
        if (drawing) {
          canvas.drawPath(
            metric.extractPath(distance, distance + segLen),
            paint,
          );
        }
        distance += segLen;
        drawing = !drawing;
      }
      distance = 0;
      drawing = true;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── HashTag chip ────────────────────────────────────────────────────────────

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

// ── Diálogo tópico privado ──────────────────────────────────────────────────

class _PrivateForumCreatedDialog extends StatefulWidget {
  final int topicId;
  final String? joinCode;

  const _PrivateForumCreatedDialog({
    required this.topicId,
    this.joinCode,
  });

  @override
  State<_PrivateForumCreatedDialog> createState() =>
      _PrivateForumCreatedDialogState();
}

class _PrivateForumCreatedDialogState
    extends State<_PrivateForumCreatedDialog> {
  final _searchController = TextEditingController();
  final List<UserSearchResult> _invitees = [];
  List<UserSearchResult> _suggestions = [];
  bool _loadingSuggestions = false;
  bool _isSending = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _fetchSuggestions(query),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _loadingSuggestions = true);
    try {
      final results = await ForumService.instance.searchUsers(
        query,
        topicId: widget.topicId,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = results
            .where((u) => !_invitees.any((inv) => inv.id == u.id))
            .toList();
      });
    } on ApiException {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  void _addUser(UserSearchResult user) {
    setState(() {
      _invitees.add(user);
      _suggestions = [];
      _searchController.clear();
    });
  }

  void _addFirstSuggestion() {
    if (_suggestions.isNotEmpty) {
      _addUser(_suggestions.first);
    } else if (_searchController.text.trim().isNotEmpty) {
      _fetchSuggestions(_searchController.text.trim());
    }
  }

  Future<void> _sendInvites() async {
    if (_invitees.isEmpty) {
      Navigator.pop(context);
      Navigator.pop(context);
      return;
    }
    setState(() => _isSending = true);
    try {
      await ForumService.instance
          .inviteUsers(widget.topicId, _invitees.map((u) => u.id).toList());
      if (!mounted) return;
      showAppToast(context, 'Convites enviados com sucesso!');
      Navigator.pop(context);
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        showAppToast(context, e.message, type: AppToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.joinCode ?? '—';
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
              // ── Cabeçalho ────────────────────────────────────────
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
                    child: const Icon(Icons.check, size: 18, color: Color(0xFF137A35)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tópico privado criado!',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMain),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Partilha o acesso com os membros.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              // ── Código de acesso ─────────────────────────────────
              const Text(
                'CÓDIGO DE ACESSO',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4),
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
                    Expanded(
                      child: Text(
                        code,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.wine, letterSpacing: 0.6),
                      ),
                    ),
                    SizedBox(
                      height: 22,
                      child: TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          showAppToast(context, 'Código copiado!');
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.winePill,
                          foregroundColor: AppColors.wine,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Copiar', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              // ── Convidar membros ─────────────────────────────────
              const Text(
                'CONVIDAR MEMBROS',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: _searchController,
                        enabled: !_isSending,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          hintText: 'Nome ou email do membro...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        ),
                        style: const TextStyle(fontSize: 11),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addFirstSuggestion(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 58,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _addFirstSuggestion,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.wine,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Adicionar', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              // Sugestões
              if (_loadingSuggestions)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(color: AppColors.wine, minHeight: 2),
                )
              else if (_suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (_, i) {
                      final u = _suggestions[i];
                      return InkWell(
                        onTap: () => _addUser(u),
                        borderRadius: i == 0
                            ? const BorderRadius.vertical(top: Radius.circular(8))
                            : i == _suggestions.length - 1
                                ? const BorderRadius.vertical(bottom: Radius.circular(8))
                                : BorderRadius.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                                backgroundColor: AppColors.winePill,
                                child: u.avatarUrl == null
                                    ? Text(
                                        u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 10, color: AppColors.wine, fontWeight: FontWeight.w800),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                                    Text(u.email, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const Icon(Icons.add_circle_outline, size: 16, color: AppColors.wine),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (_invitees.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _invitees
                      .map((u) => _InviteChip(
                            user: u,
                            onRemove: () => setState(() => _invitees.remove(u)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              // ── Botão enviar ─────────────────────────────────────
              SizedBox(
                height: 26,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendInvites,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _invitees.isEmpty ? 'Saltar' : 'Enviar convites',
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
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
  final UserSearchResult user;
  final VoidCallback onRemove;

  const _InviteChip({required this.user, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final label = user.email.length > 15
        ? '${user.email.substring(0, 12)}..'
        : user.email;
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
          CircleAvatar(
            radius: 7,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            backgroundColor: AppColors.winePill,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 7, color: AppColors.wine, fontWeight: FontWeight.w800),
                  )
                : null,
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
