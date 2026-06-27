import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final name = TextEditingController(text: 'Carlos Abreu Mendes');
  final username = TextEditingController(text: '@carlosmendes');
  final bio = TextEditingController(
    text:
        'Investigador focado na economia colonial angolana e transições pós-independência.',
  );
  final institution = TextEditingController(text: 'ISPTEC');
  final department = TextEditingController(text: 'DCSA — Economia');
  final website = TextEditingController(text: 'https://');
  final interests = <String>{'Economia', 'História'};

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    bio.dispose();
    institution.dispose();
    department.dispose();
    website.dispose();
    super.dispose();
  }

  void _save() {
    showAppToast(context, 'Perfil actualizado', type: AppToastType.success);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        toolbarHeight: 58,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.wine, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppColors.wine,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: AppColors.wine,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 26),
        children: [
          _AvatarEditor(
            onTap: () => showAppToast(context, 'Seleccionar foto de perfil', type: AppToastType.info),
          ),
          const SizedBox(height: 30),
          _EditableField(label: 'Nome completo', controller: name),
          _EditableField(label: 'Nome de utilizador', controller: username),
          _EditableField(
            label: 'Bio',
            controller: bio,
            maxLength: 200,
            maxLines: 3,
          ),
          _EditableField(
            label: 'Instituição',
            controller: institution,
            trailing: Icons.chevron_right,
          ),
          _EditableField(label: 'Curso / Departamento', controller: department),
          _EditableField(
            label: 'Website',
            controller: website,
            prefix: Icons.link,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 28),
          const Text(
            'ÁREAS DE INTERESSE',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Economia', 'História', 'Petróleo', 'Política'].map((
              item,
            ) {
              final selected = interests.contains(item);
              return FilterChip(
                label: Text(item),
                selected: selected,
                onSelected: (value) => setState(
                  () => value ? interests.add(item) : interests.remove(item),
                ),
                selectedColor: AppColors.winePill,
                checkmarkColor: AppColors.wine,
                labelStyle: TextStyle(
                  color: selected ? AppColors.wine : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wine,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text('Guardar alterações'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  final VoidCallback onTap;
  const _AvatarEditor({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A160D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight, width: 3),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFFD8B58F),
                    size: 32,
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.wine,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Alterar foto de perfil',
          style: TextStyle(
            color: AppColors.wine,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? trailing;
  final IconData? prefix;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;

  const _EditableField({
    required this.label,
    required this.controller,
    this.trailing,
    this.prefix,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.textMain,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefix == null
              ? null
              : Icon(prefix, color: AppColors.muted, size: 16),
          suffixIcon: trailing == null
              ? null
              : Icon(trailing, color: AppColors.muted, size: 18),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterStyle: const TextStyle(color: AppColors.muted, fontSize: 9),
          labelStyle: const TextStyle(color: AppColors.muted, fontSize: 11),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
