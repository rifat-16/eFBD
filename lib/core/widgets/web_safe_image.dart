import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;
import '../theme/app_theme.dart';

class WebSafeImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;
  final Widget? fallbackWidget;

  const WebSafeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.onTap,
    this.fallbackWidget,
  });

  @override
  State<WebSafeImage> createState() => _WebSafeImageState();
}

class _WebSafeImageState extends State<WebSafeImage> {
  bool _hasError = false;

  @override
  void didUpdateWidget(WebSafeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _hasError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl?.trim();
    final fallback = widget.fallbackWidget ??
        Icon(
          Icons.person,
          size: (widget.width != null && widget.height != null)
              ? (widget.width! < widget.height! ? widget.width! : widget.height!) * 0.6
              : 20,
          color: AppTheme.textGrey,
        );

    if (url == null || url.isEmpty || _hasError) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(child: fallback),
      );
    }

    if (!kIsWeb) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Image.network(
          url,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: widget.width,
              height: widget.height,
              child: Center(child: fallback),
            );
          },
        ),
      );
    }

    // Unique ID for each image URL
    final String viewId = 'img-${url.hashCode}';

    // Register the image element
    ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final img = html.ImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.cursor = 'pointer'
        ..style.objectFit = _getHtmlFit(widget.fit);

      img.onError.listen((event) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });

      if (widget.onTap != null) {
        img.onClick.listen((event) => widget.onTap!());
      }

      return img;
    });

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: IgnorePointer(
        ignoring: widget.onTap == null,
        child: HtmlElementView(key: ValueKey('$viewId-$_hasError'), viewType: viewId),
      ),
    );
  }

  String _getHtmlFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      default:
        return 'contain';
    }
  }
}
