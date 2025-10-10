import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final FontWeight? boldWeight;

  const CustomText(this.text, {super.key, this.style, this.boldWeight});

  @override
  Widget build(BuildContext context) {
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
          style: style?.merge(TextStyle(fontWeight: boldWeight ?? FontWeight.bold)) ?? TextStyle(fontWeight: boldWeight ?? FontWeight.bold),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
