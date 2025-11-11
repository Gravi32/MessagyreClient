import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final FontWeight? boldWeight;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxLines;
  final List<InlineSpan>? extraSpans;
  final TextAlign textAlign;

  const CustomText(
    this.text, {
    super.key,
    this.style,
    this.boldWeight,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.extraSpans,
    this.textAlign = TextAlign.start
  });

  static List<InlineSpan> parseSpans(String text, {TextStyle? style, FontWeight? boldWeight}) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*(.*?)\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: style));
      }

      spans.add(
        TextSpan(
          text: match.group(1),
          style: style?.merge(TextStyle(fontWeight: boldWeight ?? FontWeight.bold))
              ?? TextStyle(fontWeight: boldWeight ?? FontWeight.bold),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final spans = parseSpans(text, style: style, boldWeight: boldWeight);
    if (extraSpans != null) {
      spans.addAll(extraSpans!);
    }

    return RichText(
      text: TextSpan(children: spans, style: style),
      overflow: overflow,
      softWrap: softWrap,
      maxLines: maxLines,
      textAlign: textAlign,
    );
  }
}
