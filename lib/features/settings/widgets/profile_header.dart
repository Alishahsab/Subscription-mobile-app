import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tones.dart';
import '../../../core/utils/picked_image.dart';
import '../../../data/repositories/profile_repository.dart';

const _maxPhotoBytes = 2 * 1024 * 1024;
const _photoTypes = ['jpg', 'jpeg', 'png', 'webp'];

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(adminProfileProvider);
    final tones = context.tones;
    final path = profile?.avatarPath;
    final url = path == null ? null : ref.read(profileRepositoryProvider).avatarUrl(path);
    final surface = Theme.of(context).colorScheme.surface;

    return Column(
      children: [
        SizedBox(
          width: 128,
          height: 128,
          child: Stack(
            children: [
              Container(
                width: 128,
                height: 128,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: surface, width: 4),
                  gradient: const LinearGradient(colors: [Color(0xFF1B3A85), AppColors.navy]),
                ),
                child: url == null ? const Icon(Icons.person_rounded, size: 64, color: AppColors.gold) : Image.network(url, fit: BoxFit.cover),
              ),
              Positioned(
                right: 2,
                bottom: 6,
                child: GestureDetector(
                  onTap: profile == null ? null : () => showDialog<void>(context: context, builder: (context) => _PhotoDialog(profile: profile)),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle, border: Border.all(color: surface, width: 3)),
                    child: const Icon(Icons.photo_camera_outlined, size: 17, color: AppColors.navy),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: profile == null ? null : () => showDialog<void>(context: context, builder: (context) => _NameDialog(profile: profile)),
          child: Column(
            children: [
              Text(profile?.name ?? ' ', style: TextStyle(color: tones.title, fontSize: 26, fontWeight: FontWeight.w700)),
              Text(profile?.email ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _NameDialog extends ConsumerStatefulWidget {
  const _NameDialog({required this.profile});

  final AdminProfile profile;

  @override
  ConsumerState<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends ConsumerState<_NameDialog> {
  late String _name = widget.profile.name == 'Admin' ? '' : widget.profile.name;
  bool _busy = false;
  String _error = '';

  Future<void> _save() async {
    final clean = _name.trim();
    setState(() {
      _busy = true;
      _error = '';
    });

    try {
      await ref.read(profileRepositoryProvider).saveName(widget.profile.userId, clean);
      ref.read(adminProfileProvider.notifier).set(widget.profile.copyWith(name: clean));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'The name could not be saved. Check your internet and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shown on your profile'),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _name,
            autofocus: true,
            maxLength: 40,
            onChanged: (value) => setState(() => _name = value),
            decoration: const InputDecoration(hintText: 'Your name', border: OutlineInputBorder(), isDense: true),
          ),
          if (_error.isNotEmpty) Text(_error, style: TextStyle(color: context.tones.redText, fontSize: 12.5)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _name.trim().isEmpty || _busy ? null : _save, child: const Text('Save')),
      ],
    );
  }
}

class _PhotoDialog extends ConsumerStatefulWidget {
  const _PhotoDialog({required this.profile});

  final AdminProfile profile;

  @override
  ConsumerState<_PhotoDialog> createState() => _PhotoDialogState();
}

class _PhotoDialogState extends ConsumerState<_PhotoDialog> {
  bool _busy = false;
  String _error = '';

  Future<void> _pick(ImageSource source) async {
    final repository = ref.read(profileRepositoryProvider);

    try {
      final photo = await pickProfilePhoto(source);
      if (photo == null) return;

      if (!_photoTypes.contains(photo.extension)) {
        setState(() => _error = 'Please choose a JPG, PNG or WebP photo.');
        return;
      }
      if (photo.bytes.length > _maxPhotoBytes) {
        setState(() => _error = 'This photo is bigger than 2 MB. Please choose a smaller one.');
        return;
      }

      setState(() {
        _busy = true;
        _error = '';
      });
      final extension = photo.extension == 'jpeg' ? 'jpg' : photo.extension;
      final path = await repository.uploadAvatar(widget.profile, photo.bytes, extension);
      _finish(path);
    } catch (_) {
      _fail();
    }
  }

  Future<void> _remove() async {
    setState(() {
      _busy = true;
      _error = '';
    });

    try {
      await ref.read(profileRepositoryProvider).setAvatarPath(widget.profile, null);
      _finish(null);
    } catch (_) {
      _fail();
    }
  }

  void _finish(String? path) {
    ref.read(adminProfileProvider.notifier).set(widget.profile.withAvatar(path));
    if (mounted) Navigator.pop(context);
  }

  void _fail() {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = 'The photo could not be saved. Check your internet and try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return AlertDialog(
      title: const Text('Profile photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('JPG, PNG or WebP · up to 2 MB'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _PhotoOption(icon: Icons.photo_camera_outlined, label: 'Camera', onTap: _busy ? null : () => _pick(ImageSource.camera))),
              Expanded(child: _PhotoOption(icon: Icons.image_outlined, label: 'Gallery', onTap: _busy ? null : () => _pick(ImageSource.gallery))),
              Expanded(
                child: _PhotoOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove',
                  danger: true,
                  onTap: _busy || widget.profile.avatarPath == null ? null : _remove,
                ),
              ),
            ],
          ),
          if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: Text('Saving photo…', style: TextStyle(fontSize: 12.5))),
          if (_error.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: tones.amberFill, borderRadius: BorderRadius.circular(12)),
              child: Text(_error, style: TextStyle(color: tones.amberText, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({required this.icon, required this.label, required this.onTap, this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: danger ? tones.redFill : tones.softFill, borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, size: 22, color: danger ? tones.redText : tones.softText),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
