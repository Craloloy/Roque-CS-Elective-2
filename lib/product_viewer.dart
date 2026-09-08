import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'reference_model.dart';
import 'store.dart';
import 'theme.dart';

/// Offline photo-guided 3D models. Geometry and source-photo gallery stay independent.
class ProductViewer360 extends StatefulWidget {
  final Product product;
  const ProductViewer360({super.key, required this.product});

  @override
  State<ProductViewer360> createState() => _ProductViewer360State();
}

class _ProductViewer360State extends State<ProductViewer360> {
  double angle = -.28, tilt = -.1, zoom = 1, initialZoom = 1;
  bool gallery = false, hint = true;
  int galleryIndex = 0;
  static ui.Image? _cachedSeal;
  ui.Image? seal;

  @override
  void initState() {
    super.initState();
    if (_cachedSeal != null) {
      seal = _cachedSeal;
    } else {
      _loadSeal();
    }
  }

  @override
  void didUpdateWidget(covariant ProductViewer360 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (seal == null && _cachedSeal != null) {
      setState(() => seal = _cachedSeal);
    }
    if (galleryIndex == 2 &&
        (widget.product.category != 'PE Uniforms' ||
            widget.product.references.isEmpty)) {
      galleryIndex = 0;
    }
  }

  Future<void> _loadSeal() async {
    if (_cachedSeal != null) {
      if (mounted) setState(() => seal = _cachedSeal);
      return;
    }
    // Attempt 1: rootBundle + instantiateImageCodec with exact byte offset & length
    try {
      final data = await rootBundle.load('assets/branding/addu-seal.jpg');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      _cachedSeal = frame.image;
      if (mounted) {
        setState(() => seal = frame.image);
      }
      return;
    } catch (_) {}

    // Attempt 2: AssetImage pipeline (bulletproof on Flutter Web)
    try {
      final stream = const AssetImage(
        'assets/branding/addu-seal.jpg',
      ).resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          _cachedSeal = info.image;
          if (mounted) {
            setState(() => seal = info.image);
          }
          stream.removeListener(listener);
        },
        onError: (_, _) {
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_cachedSeal == null) {
      seal?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasOnModel = widget.product.category == 'PE Uniforms' &&
        widget.product.references.isNotEmpty;
    final activeGalleryIndex =
        (galleryIndex == 2 && !hasOnModel) ? 0 : galleryIndex;

    return Container(
      height: 470,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: RadialGradient(
          colors: isDark
              ? const [Color(0xFF22354A), Color(0xFF132130)]
              : const [Brand.white, Brand.productBg],
          radius: .85,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 65,
            child: gallery
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Image.asset(
                      activeGalleryIndex == 0
                          ? widget.product.image
                          : (activeGalleryIndex == 1
                              ? widget.product.backImage
                              : (hasOnModel
                                  ? widget.product.references.first
                                  : widget.product.image)),
                      fit: BoxFit.contain,
                    ),
                  )
                : Semantics(
                    label:
                        'Interactive 3D model of ${widget.product.name}. Drag to rotate, pinch or use buttons to zoom.',
                    child: GestureDetector(
                      onScaleStart: (_) {
                        initialZoom = zoom;
                        hint = false;
                      },
                      onScaleUpdate: (d) => setState(() {
                        if (d.scale != 1) {
                          zoom = (initialZoom * d.scale).clamp(.8, 1.8);
                        } else {
                          angle += d.focalPointDelta.dx * .01;
                          tilt = (tilt - d.focalPointDelta.dy * .01).clamp(
                            -.5,
                            .5,
                          );
                        }
                      }),
                      child: CustomPaint(
                        painter: MeshPainter(
                          widget.product,
                          angle,
                          tilt,
                          zoom,
                          seal: seal,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: Column(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Reset view',
                  onPressed: () => setState(() {
                    angle = -.28;
                    tilt = -.1;
                    zoom = 1;
                  }),
                  icon: const Icon(Icons.refresh, size: 18),
                ),
                const SizedBox(height: 6),
                IconButton.filledTonal(
                  tooltip: 'Zoom in',
                  onPressed: () =>
                      setState(() => zoom = (zoom + .15).clamp(.8, 1.8)),
                  icon: const Icon(Icons.zoom_in, size: 18),
                ),
                const SizedBox(height: 6),
                IconButton.filledTonal(
                  tooltip: 'Zoom out',
                  onPressed: () =>
                      setState(() => zoom = (zoom - .15).clamp(.8, 1.8)),
                  icon: const Icon(Icons.zoom_out, size: 18),
                ),
              ],
            ),
          ),
          if (hint && !gallery)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Brand.navy.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 14,
                      color: Brand.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Drag to rotate · 360°',
                      style: TextStyle(
                        color: Brand.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (gallery)
            Positioned(
              bottom: 74,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SegmentedButton<int>(
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          isDark ? const Color(0xFF182839) : Brand.white,
                      foregroundColor:
                          isDark ? const Color(0xFFD4E3F3) : Brand.navy,
                      selectedBackgroundColor: isDark
                          ? const Color(0xFF254366)
                          : Brand.blue.withValues(alpha: .14),
                      selectedForegroundColor:
                          isDark ? Brand.white : Brand.blue,
                    ),
                    segments: [
                      const ButtonSegment(value: 0, label: Text('Front')),
                      const ButtonSegment(value: 1, label: Text('Back')),
                      if (hasOnModel)
                        const ButtonSegment(
                          value: 2,
                          label: Text('On Model'),
                          icon: Icon(Icons.accessibility_new_rounded, size: 14),
                        ),
                    ],
                    selected: {activeGalleryIndex},
                    onSelectionChanged: (v) =>
                        setState(() => galleryIndex = v.first),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Center(
              child: SegmentedButton<bool>(
                style: SegmentedButton.styleFrom(
                  backgroundColor:
                      isDark ? const Color(0xFF182839) : Brand.white,
                  foregroundColor:
                      isDark ? const Color(0xFF9DCBFA) : Brand.blue,
                  selectedBackgroundColor:
                      isDark ? const Color(0xFF254366) : Brand.blue,
                  selectedForegroundColor: Brand.white,
                ),
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('3D View'),
                    icon: Icon(Icons.view_in_ar_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Gallery'),
                    icon: Icon(Icons.photo_library_outlined, size: 16),
                  ),
                ],
                selected: {gallery},
                onSelectionChanged: (v) => setState(() => gallery = v.first),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
