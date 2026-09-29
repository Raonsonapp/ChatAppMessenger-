import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/link_preview_service.dart';

/// Матн бо ҳаволаҳои пахшшаванда.
///
/// Пештар ҳаволаҳо матни оддӣ буданд — корбар онҳоро дида, вале кушода
/// наметавонист.
class LinkifiedText extends StatefulWidget {
  const LinkifiedText({
    super.key,
    required this.text,
    required this.style,
    required this.linkStyle,
  });

  final String text;
  final TextStyle style;
  final TextStyle linkStyle;

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  /// Ҳар `TapGestureRecognizer` бояд озод карда шавад, вагарна хотира
  /// мечакад.
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches =
        LinkPreviewService.urlPattern.allMatches(widget.text).toList();
    if (matches.isEmpty) {
      return Text(widget.text, style: widget.style);
    }

    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, match.start)));
      }

      final raw = match.group(0)!;
      // Аломатҳои охири ҷумла қисми ҳавола нестанд.
      final trailing = RegExp(r'[.,;:!?)\]]+$').firstMatch(raw)?.group(0) ?? '';
      final link = raw.substring(0, raw.length - trailing.length);
      final target = link.startsWith('http') ? link : 'https://$link';

      final recognizer = TapGestureRecognizer()
        ..onTap = () => launchUrl(
              Uri.parse(target),
              mode: LaunchMode.externalApplication,
            );
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: link,
        style: widget.linkStyle,
        recognizer: recognizer,
      ));
      if (trailing.isNotEmpty) spans.add(TextSpan(text: trailing));
      cursor = match.end;
    }

    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
