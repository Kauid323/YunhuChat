import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 带Referer的图片加载器
class ImageLoader {
  static const String referer = 'http://myapp.jwznb.com';

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
      httpHeaders: {
        'Referer': referer,
      },
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
      headers: {
        'Referer': referer,
      },
    );
  }
}

