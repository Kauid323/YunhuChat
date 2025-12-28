import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as m;

import '../../../config/configs.dart';
import '../../../config/markdown_generator.dart';
import '../../markdown.dart';
import '../../span_node.dart';
import '../../widget_visitor.dart';

class DetailsBlockNode extends SpanNode {
  final String summary;
  final String body;
  final MarkdownConfig config;
  final MarkdownGenerator generator;

  DetailsBlockNode({
    required this.summary,
    required this.body,
    required this.config,
    required this.generator,
  });

  factory DetailsBlockNode.fromElement(
    m.Element element,
    MarkdownConfig config,
    WidgetVisitor visitor,
  ) {
    final summary = element.attributes['summary'] ?? '';
    final body = element.attributes['body'] ?? '';

    return DetailsBlockNode(
      summary: summary,
      body: body,
      config: config,
      generator: visitor.generator,
    );
  }

  @override
  InlineSpan build() {
    return WidgetSpan(
      child: _DetailsBlockWidget(
        summary: summary,
        body: body,
        config: config,
        generator: generator,
      ),
    );
  }
}

class _DetailsBlockWidget extends StatefulWidget {
  final String summary;
  final String body;
  final MarkdownConfig config;
  final MarkdownGenerator generator;

  const _DetailsBlockWidget({
    required this.summary,
    required this.body,
    required this.config,
    required this.generator,
  });

  @override
  State<_DetailsBlockWidget> createState() => _DetailsBlockWidgetState();
}

class _DetailsBlockWidgetState extends State<_DetailsBlockWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.summary.isEmpty ? '详情' : widget.summary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: MarkdownWidget(
                data: widget.body,
                config: widget.config,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                markdownGenerator: widget.generator,
              ),
            ),
        ],
      ),
    );
  }
}
