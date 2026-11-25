import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tones.dart';
import '../../data/repositories/image_repository.dart';

typedef PictureProblem = Widget Function(String? reason, VoidCallback retry);

void openImageViewer(BuildContext context, String path) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(fullscreenDialog: true, builder: (context) => _ImageViewer(path: path)),
  );
}

class StoredImage extends StatelessWidget {
  const StoredImage({super.key, required this.path, this.fit = BoxFit.cover, this.alignment = Alignment.topCenter});

  final String path;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final fill = ColoredBox(color: context.tones.softFill);

    return GestureDetector(
      onTap: () => openImageViewer(context, path),
      child: _Picture(
        path: path,
        fit: fit,
        alignment: alignment,
        loading: fill,
        problem: (reason, retry) => GestureDetector(
          onTap: retry,
          child: ColoredBox(
            color: context.tones.softFill,
            child: Center(child: Icon(Icons.refresh_rounded, color: context.tones.faint)),
          ),
        ),
      ),
    );
  }
}

class _Picture extends ConsumerStatefulWidget {
  const _Picture({required this.path, required this.loading, required this.problem, this.fit, this.alignment = Alignment.center});

  final String path;
  final BoxFit? fit;
  final Alignment alignment;
  final Widget loading;
  final PictureProblem problem;

  @override
  ConsumerState<_Picture> createState() => _PictureState();
}

class _PictureState extends ConsumerState<_Picture> {
  late Future<ImageProvider?> _image = _load();
  bool _download = false;

  ImageRepository get _images => ref.read(imageRepositoryProvider);

  Future<ImageProvider?> _load() async {
    final ready = _images.downloaded(widget.path);
    if (ready != null) return MemoryImage(ready);
    if (!_download) {
      final url = await _images.urlFor(widget.path);
      if (url != null) return NetworkImage(url);
    }
    final bytes = await _images.download(widget.path);
    return bytes == null ? null : MemoryImage(bytes);
  }

  void _retry({bool download = false}) {
    if (!mounted) return;
    setState(() {
      _download = download;
      _image = _load();
    });
  }

  @override
  void didUpdateWidget(_Picture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _retry();
  }

  Widget _onBroken(ImageProvider image) {
    if (image is NetworkImage && !_download) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _retry(download: true));
      return widget.loading;
    }
    return widget.problem('The picture file is damaged', _retry);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider?>(
      future: _image,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return widget.loading;

        final image = snapshot.data;
        if (image == null) return widget.problem(_images.problemOf(widget.path), _retry);

        return Image(
          image: image,
          fit: widget.fit,
          alignment: widget.alignment,
          errorBuilder: (context, error, stack) => _onBroken(image),
        );
      },
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: const [CloseButton()],
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: _Picture(
            path: path,
            loading: const CircularProgressIndicator(color: Colors.white),
            problem: (reason, retry) => _ImageProblem(reason: reason, onRetry: retry),
          ),
        ),
      ),
    );
  }
}

class _ImageProblem extends StatelessWidget {
  const _ImageProblem({required this.reason, required this.onRetry});

  final String? reason;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final why = reason;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('This picture could not be opened.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        if (why != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 6, 32, 0),
            child: Text(why, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
          ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)),
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
