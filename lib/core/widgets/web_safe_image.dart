import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;

class WebSafeImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;

  const WebSafeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return GestureDetector(
        onTap: onTap,
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }

    // Unique ID for each image
    final String viewId = 'img-${imageUrl.hashCode}';

    // Register the image element
    ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final img = html.ImageElement()
        ..src = imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.cursor = 'pointer'
        ..style.objectFit = _getHtmlFit(fit);
      
      // Handle click at browser level
      if (onTap != null) {
        img.onClick.listen((event) => onTap!());
      }
      
      return img;
    });

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      child: IgnorePointer(
        ignoring: onTap == null, // Ignore Flutter's pointer system if we handle it in HTML
        child: HtmlElementView(key: ValueKey(viewId), viewType: viewId),
      ),
    );
  }

  String _getHtmlFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover: return 'cover';
      case BoxFit.contain: return 'contain';
      case BoxFit.fill: return 'fill';
      default: return 'contain';
    }
  }
}
