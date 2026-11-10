// Source - https://stackoverflow.com/a/79670335
// Posted by PRATHIV
// Retrieved 2025-12-05, License - CC BY-SA 4.0

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum ChatSlot { content, timestamp }

class TextChatBubbleWithTimeStamp extends SlottedMultiChildRenderObjectWidget<ChatSlot, RenderBox> {
  const TextChatBubbleWithTimeStamp({super.key, required this.content, required this.timestamp}) : super();

  final Widget content;
  final Widget timestamp;

  @override
  Iterable<ChatSlot> get slots => ChatSlot.values;

  @override
  Widget? childForSlot(ChatSlot slot) {
    return switch (slot) {
      ChatSlot.content => content,
      ChatSlot.timestamp => timestamp,
    };
  }

  @override
  RenderChatBubble createRenderObject(BuildContext context) {
    return RenderChatBubble();
  }
}

class RenderChatBubble extends RenderBox with SlottedContainerRenderObjectMixin<ChatSlot, RenderBox> {
  RenderChatBubble();

  RenderBox? get _content => childForSlot(ChatSlot.content);
  RenderBox? get _timestamp => childForSlot(ChatSlot.timestamp);

  // The intrinsic sizes let a bubble be as wide as its widest part (an answer's quote above the text, through
  // IntrinsicWidth): the text on one line with the time next to it at most, its longest word above the time at least

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(_content?.getMinIntrinsicWidth(height) ?? 0, _timestamp?.getMinIntrinsicWidth(height) ?? 0);

  @override
  double computeMaxIntrinsicWidth(double height) => (_content?.getMaxIntrinsicWidth(height) ?? 0) + (_timestamp?.getMaxIntrinsicWidth(height) ?? 0) + 2;

  @override
  double computeMinIntrinsicHeight(double width) => (_content?.getMinIntrinsicHeight(width) ?? 0) + (_timestamp?.getMinIntrinsicHeight(width) ?? 0);

  @override
  double computeMaxIntrinsicHeight(double width) => (_content?.getMaxIntrinsicHeight(width) ?? 0) + (_timestamp?.getMaxIntrinsicHeight(width) ?? 0);
  @override
  void performLayout() {
    final RenderBox? content = _content;
    final RenderBox? timestamp = _timestamp;

    if (content == null || timestamp == null) {
      size = constraints.smallest;
      return;
    }

    final double maxWidth = constraints.maxWidth;

    // Layout timestamp
    timestamp.layout(BoxConstraints.loose(constraints.biggest), parentUsesSize: true);
    final timestampSize = timestamp.size;

    // Layout content
    content.layout(BoxConstraints(maxWidth: maxWidth), parentUsesSize: true);
    final contentSize = content.size;

    // Analyze if timestamp fits in last line of text
    bool fitsInline = false;
    double lastLineWidth = contentSize.width;
    if (content is RenderParagraph) {
      final span = content.text as TextSpan?;
      if (span != null) {
        // Measured exactly like the paragraph draws itself: with the phone's text size (textScaler) and the same
        // strut, otherwise a bigger system font makes the last line wider than measured and the time covers it
        final tp = TextPainter(
          text: span,
          textDirection: content.textDirection,
          textScaler: content.textScaler,
          locale: content.locale,
          strutStyle: content.strutStyle,
          textWidthBasis: content.textWidthBasis,
          textHeightBehavior: content.textHeightBehavior,
        );
        tp.layout(maxWidth: maxWidth);
        final lines = tp.computeLineMetrics();
        if (lines.isNotEmpty) {
          lastLineWidth = lines.last.left + lines.last.width;
          // A little margin: rounding must never put the time on the last letters
          if (lastLineWidth + timestampSize.width + 2 <= maxWidth) {
            fitsInline = true;
          }
        }
        tp.dispose();
      }
    }

    // Final bubble size
    final double bubbleWidth = fitsInline ? math.max(lastLineWidth + timestampSize.width + 2, contentSize.width) : math.max(contentSize.width, timestampSize.width);

    final double bubbleHeight = contentSize.height + (fitsInline ? 0 : timestampSize.height);

    size = constraints.constrain(Size(bubbleWidth, bubbleHeight));

    // Set offsets
    final contentParentData = content.parentData! as BoxParentData;
    contentParentData.offset = Offset.zero;

    final timestampParentData = timestamp.parentData! as BoxParentData;
    const double timestampInlineTopPadding = 4.0; // Adjust this value to your needs

    // From the real width (constrained), not the wanted one: the time never goes out of the bubble
    if (fitsInline) {
      timestampParentData.offset = Offset(size.width - timestampSize.width, contentSize.height - timestampSize.height + timestampInlineTopPadding);
    } else {
      timestampParentData.offset = Offset(size.width - timestampSize.width, contentSize.height);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_content case final RenderBox content) {
      final offsetContent = (content.parentData! as BoxParentData).offset;
      context.paintChild(content, offset + offsetContent);
    }

    if (_timestamp case final RenderBox timestamp) {
      final offsetTS = (timestamp.parentData! as BoxParentData).offset;
      context.paintChild(timestamp, offset + offsetTS);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [if (_timestamp != null) _timestamp!, if (_content != null) _content!]) {
      final offset = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(offset: offset, position: position, hitTest: (result, transformed) => child.hitTest(result, position: transformed));
      if (hit) return true;
    }
    return false;
  }
}
