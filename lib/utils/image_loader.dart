import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 带Referer的图片加载器
class ImageLoader {
  static const String referer = 'https://myapp.jwznb.com';

  static bool _needReferer(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      if (host.isEmpty) return false;
      return host == 'jwznb.com' || host.endsWith('.jwznb.com');
    } catch (_) {
      return false;
    }
  }

  /// 加载网络图片（带Referer）
  static Widget networkImage({
    required String url,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      httpHeaders: _needReferer(url)
          ? {
              'Referer': referer,
            }
          : const {},
      placeholder: (context, url) => placeholder ?? const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => errorWidget ?? Icon(
        Icons.error,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// 创建带Referer的NetworkImage
  static ImageProvider networkImageProvider(String url) {
    return CachedNetworkImageProvider(
      url,
      headers: _needReferer(url)
          ? {
              'Referer': referer,
            }
          : const {},
    );
  }
}

