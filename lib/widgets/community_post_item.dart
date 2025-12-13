import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../utils/image_loader.dart';
import '../screens/post_detail_screen.dart';

class CommunityPostItem extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onTap;

  const CommunityPostItem({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(
                  postId: post.id,
                  previewPost: post,
                ),
              ),
            );
          },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  backgroundImage: post.senderAvatar.isNotEmpty
                      ? ImageLoader.networkImageProvider(post.senderAvatar)
                      : null,
                  child: post.senderAvatar.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.senderNickname,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        post.createTimeText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionIcon(
                  context,
                  Icons.thumb_up_outlined,
                  post.likeNum.toString(),
                ),
                const SizedBox(width: 24),
                _buildActionIcon(
                  context,
                  Icons.chat_bubble_outline,
                  post.commentNum.toString(),
                ),
                const SizedBox(width: 24),
                _buildActionIcon(
                  context,
                  Icons.star_outline,
                  post.collectNum.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
