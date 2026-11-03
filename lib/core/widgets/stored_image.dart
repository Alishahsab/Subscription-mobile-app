import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tones.dart';
import '../../data/repositories/image_repository.dart';

class StoredImage extends ConsumerStatefulWidget {
  const StoredImage({super.key, required this.path, this.fit = BoxFit.cover, this.alignment = Alignment.topCenter});

  final String path;
  final BoxFit fit;
  final Alignment alignment;

  @override
  ConsumerState<StoredImage> createState() => _StoredImageState();
}

class _StoredImageState extends ConsumerState<StoredImage> {
  late Future<String?> _url;

  @override
  void initState() {
    super.initState();
    _url = ref.read(imageRepositoryProvider).urlFor(widget.path);
  }

  @override
  void didUpdateWidget(StoredImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _url = ref.read(imageRepositoryProvider).urlFor(widget.path);
  }

  Future<void> _openViewer() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final url = await ref.read(imageRepositoryProvider).urlFor(widget.path);
    navigator.push(
      MaterialPageRoute<void>(fullscreenDialog: true, builder: (context) => _ImageViewer(url: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _url,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) return ColoredBox(color: context.tones.softFill);

        return GestureDetector(
          onTap: _openViewer,
          child: Image.network(url, fit: widget.fit, alignment: widget.alignment),
        );
      },
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final link = url;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: const [CloseButton()],
      ),
      body: Center(
        child: link == null
            ? const _ImageProblem()
            : InteractiveViewer(
                maxScale: 5,
                child: Image.network(
                  link,
                  loadingBuilder: (context, child, progress) {
                    return progress == null ? child : const CircularProgressIndicator(color: Colors.white);
                  },
                  errorBuilder: (context, error, stack) => const _ImageProblem(),
                ),
              ),
      ),
    );
  }
}

class _ImageProblem extends StatelessWidget {
  const _ImageProblem();

  @override
  Widget build(BuildContext context) {
    return const Text('This picture could not be opened.', style: TextStyle(color: Colors.white70, fontSize: 14));
  }
}
