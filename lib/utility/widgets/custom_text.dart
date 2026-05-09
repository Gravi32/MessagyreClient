import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final FontWeight? boldWeight;
  final bool softWrap;
  final TextOverflow overflow;
  final int? maxLines;
  final List<InlineSpan>? prefixSpans;
  final List<InlineSpan>? suffixSpans;
  final EdgeInsetsGeometry? padding;
  final TextAlign textAlign;
  final TextScaler? textScaler;

  const CustomText(
    this.text, {
    super.key,
    this.style,
    this.boldWeight,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.prefixSpans,
    this.suffixSpans,
    this.padding,
    this.textAlign = .start,
    this.textScaler,
  });

  static List<InlineSpan> parseSpans(String text, {TextStyle? style, FontWeight? boldWeight}) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*(.*?)\*');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: style));
      }

      spans.add(
        TextSpan(
          text: match.group(1),
          style: style?.merge(TextStyle(fontWeight: boldWeight ?? .bold)) ?? TextStyle(fontWeight: boldWeight ?? .bold),
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
    final spans = <InlineSpan>[
      if (prefixSpans != null) ...prefixSpans!,
      ...parseSpans(text, style: style, boldWeight: boldWeight),
      if (suffixSpans != null) ...suffixSpans!,
    ];

    return Padding(
      padding: padding ?? .zero,
      child: RichText(
        text: TextSpan(
          children: spans,
          style: (style ?? DefaultTextStyle.of(context).style).copyWith(color: style?.color ?? DefaultTextStyle.of(context).style.color),
        ),
        textScaler: textScaler ?? MediaQuery.of(context).textScaler,
        overflow: overflow,
        softWrap: softWrap,
        maxLines: maxLines,
        textAlign: textAlign,
      ),
    );
  }
}
