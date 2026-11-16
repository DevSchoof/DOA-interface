import 'package:flutter/material.dart';

/// Imagem de rede com carregamento e falha tratados (sem quebrar o layout).
class NetworkPhoto extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const NetworkPhoto(this.url, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      errorBuilder: (context, error, stack) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined, color: scheme.outline),
      ),
    );
  }
}

/// Capa do card (estilo post/feed): a primeira foto em 16:9, com contador se houver mais.
class DonationPhotoCover extends StatelessWidget {
  final List<String> urls;
  const DonationPhotoCover(this.urls, {super.key});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkPhoto(urls.first),
          if (urls.length > 1)
            Positioned(
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('${urls.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Galeria da tela de detalhe: páginas deslizáveis com indicador.
class DonationPhotoGallery extends StatefulWidget {
  final List<String> urls;
  const DonationPhotoGallery(this.urls, {super.key});

  @override
  State<DonationPhotoGallery> createState() => _DonationPhotoGalleryState();
}

class _DonationPhotoGalleryState extends State<DonationPhotoGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => NetworkPhoto(widget.urls[i]),
            ),
            if (widget.urls.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.urls.length; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _page ? Colors.white : Colors.white54,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
