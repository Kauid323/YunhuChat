import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';

/// 图片预览工具类
class ImagePreviewUtil {
  /// 显示图片预览
  static void showImagePreview(
    BuildContext context, {
    required String imageUrl,
    String? title,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ImagePreviewPage(
            imageUrl: imageUrl,
            title: title,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  /// 获取请求头
  static Map<String, String>? _getHeaders(String imageUrl) {
    // 检查是否包含 jwznb.com 域名
    if (imageUrl.contains('.jwznb.com')) {
      return {
        'Referer': 'http://myapp.jwznb.com',
      };
    }
    return null;
  }
}

/// 图片预览页面
class _ImagePreviewPage extends StatelessWidget {
  final String imageUrl;
  final String? title;

  const _ImagePreviewPage({
    required this.imageUrl,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片视图
          Center(
            child: ExtendedImage.network(
              imageUrl,
              fit: BoxFit.contain,
              mode: ExtendedImageMode.gesture,
              enableLoadState: true,
              headers: ImagePreviewUtil._getHeaders(imageUrl),
              loadStateChanged: (state) {
                if (state.extendedImageLoadState == LoadState.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }
                if (state.extendedImageLoadState == LoadState.failed) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '图片加载失败',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return null;
              },
              initGestureConfigHandler: (state) {
                return GestureConfig(
                  minScale: 0.9,
                  maxScale: 3.0,
                  animationMaxScale: 3.5,
                  initialScale: 1.0,
                  cacheGesture: false,
                );
              },
            ),
          ),
          
          // 顶部栏
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // 返回按钮
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // 标题
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                const Spacer(),
                
                // 下载按钮（可选功能）
                IconButton(
                  onPressed: () {
                    // TODO: 实现下载功能
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('下载功能开发中...'),
                        backgroundColor: Colors.black87,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          
          // 底部提示
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}