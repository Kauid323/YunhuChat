import 'package:markdown/markdown.dart' as m;

class DetailsBlockSyntax extends m.BlockSyntax {
  const DetailsBlockSyntax();

  @override
  RegExp get pattern => RegExp(r'^\s*<details(\s+[^>]*)?>', caseSensitive: false);

  @override
  bool canParse(m.BlockParser parser) {
    return pattern.hasMatch(parser.current.content);
  }

  @override
  m.Node parse(m.BlockParser parser) {
    final buffer = StringBuffer();
    // consume <details ...>
    buffer.writeln(parser.current.content);

    // If the opening line already contains </details>, it's a single-line details block.
    if (RegExp(r'<\/details>\s*$', caseSensitive: false)
        .hasMatch(parser.current.content.trim())) {
      parser.advance();
    } else {
      parser.advance();

      while (!parser.isDone) {
        final line = parser.current;
        buffer.writeln(line.content);
        parser.advance();
        if (RegExp(r'<\/details>\s*$', caseSensitive: false)
            .hasMatch(line.content.trim())) {
          break;
        }
      }
    }

    final raw = buffer.toString();
    final summaryMatch = RegExp(
      r'<summary[^>]*>([\s\S]*?)<\/summary>',
      caseSensitive: false,
    ).firstMatch(raw);

    final summary = (summaryMatch?.group(1) ?? '').trim();

    String body = raw;
    // remove opening <details...>
    body = body.replaceFirst(RegExp(r'^\s*<details(\s+[^>]*)?>\s*\n?', caseSensitive: false), '');
    // remove closing </details>
    body = body.replaceFirst(RegExp(r'\n?\s*<\/details>\s*$', caseSensitive: false), '');
    // remove summary section
    body = body.replaceFirst(
      RegExp(r'<summary[^>]*>[\s\S]*?<\/summary>\s*\n?', caseSensitive: false),
      '',
    );
    body = body.trim();

    final el = m.Element('details', <m.Node>[]);
    el.attributes['summary'] = summary;
    el.attributes['body'] = body;
    return el;
  }
}
