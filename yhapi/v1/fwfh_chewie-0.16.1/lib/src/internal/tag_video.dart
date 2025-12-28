import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../chewie_factory.dart';

const kAttributeVideoAutoplay = 'autoplay';
const kAttributeVideoControls = 'controls';
const kAttributeVideoHeight = 'height';
const kAttributeVideoLoop = 'loop';
const kAttributeVideoPoster = 'poster';
const kAttributeVideoSrc = 'src';
const kAttributeVideoWidth = 'width';

const kTagVideo = 'video';
const kTagVideoSource = 'source';

class TagVideo {
  final ChewieFactory wf;

  TagVideo(this.wf);

  BuildOp get buildOp => BuildOp(
        debugLabel: kTagVideo,
        onRenderBlock: (tree, placeholder) {
          debugPrint('[fwfh_chewie][video] onRenderBlock platform=$defaultTargetPlatform isWeb=$kIsWeb');
          if (defaultTargetPlatform != TargetPlatform.android &&
              defaultTargetPlatform != TargetPlatform.iOS &&
              defaultTargetPlatform != TargetPlatform.macOS &&
              defaultTargetPlatform != TargetPlatform.windows &&
              !kIsWeb) {
            // these are the player's supported platforms
            // https://pub.dev/packages/video_player/versions/2.8.1
            debugPrint('[fwfh_chewie][video] unsupported platform -> placeholder');
            return placeholder;
          }

          final attrs = tree.element.attributes;
          final url = wf.urlFull(attrs[kAttributeVideoSrc] ?? '');
          debugPrint('[fwfh_chewie][video] tag attrs=$attrs resolvedUrl=$url');
          if (url != null) {
            tree.videoData.urls.add(url);
          }

          final built = _buildPlayer(tree);
          debugPrint('[fwfh_chewie][video] collectedUrls=${tree.videoData.urls} built=${built != null}');
          return built ?? placeholder;
        },
        onVisitChild: (tree, subTree) {
          final e = subTree.element;
          if (e.localName != kTagVideoSource) {
            return;
          }
          if (e.parent != tree.element) {
            return;
          }

          final attrs = e.attributes;
          final url = wf.urlFull(attrs[kAttributeVideoSrc] ?? '');
          if (url == null) {
            return;
          }

          debugPrint('[fwfh_chewie][video] <source> attrs=$attrs resolvedUrl=$url');
          tree.videoData.urls.add(url);
        },
      );

  Widget? _buildPlayer(BuildTree tree) {
    final sourceUrls = tree.videoData.urls;
    if (sourceUrls.isEmpty) {
      return null;
    }

    final attrs = tree.element.attributes;
    return wf.buildVideoPlayer(
      tree,
      sourceUrls.first,
      autoplay: attrs.containsKey(kAttributeVideoAutoplay),
      controls: attrs.containsKey(kAttributeVideoControls),
      height: tryParseDoubleFromMap(attrs, kAttributeVideoHeight),
      loop: attrs.containsKey(kAttributeVideoLoop),
      posterUrl: wf.urlFull(attrs[kAttributeVideoPoster] ?? ''),
      width: tryParseDoubleFromMap(attrs, kAttributeVideoWidth),
    );
  }
}

extension on BuildTree {
  _TagVideoData get videoData =>
      getNonInherited<_TagVideoData>() ?? setNonInherited(_TagVideoData());
}

@immutable
class _TagVideoData {
  final urls = <String>[];
}
