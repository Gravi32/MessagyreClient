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
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr, maxLines: null);
        tp.layout(maxWidth: maxWidth);
        final lines = tp.computeLineMetrics();
        if (lines.isNotEmpty) {
          lastLineWidth = lines.last.width;
          if (lastLineWidth + timestampSize.width <= maxWidth) {
            fitsInline = true;
          }
        }
      }
    }

    // Final bubble size
    final double bubbleWidth = fitsInline ? math.max(lastLineWidth + timestampSize.width, contentSize.width) : math.max(contentSize.width, timestampSize.width);

    final double bubbleHeight = contentSize.height + (fitsInline ? 0 : timestampSize.height);

    size = constraints.constrain(Size(bubbleWidth, bubbleHeight));

    // Set offsets
    final contentParentData = content.parentData! as BoxParentData;
    contentParentData.offset = Offset.zero;

    final timestampParentData = timestamp.parentData! as BoxParentData;
    const double timestampInlineTopPadding = 4.0; // Adjust this value to your needs

    if (fitsInline) {
      timestampParentData.offset = Offset(bubbleWidth - timestampSize.width, contentSize.height - timestampSize.height + timestampInlineTopPadding);
    } else {
      timestampParentData.offset = Offset(bubbleWidth - timestampSize.width, contentSize.height);
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
