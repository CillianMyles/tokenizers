import 'package:flutter/material.dart';

/// A text block that truncates long content behind an inline toggle.
class ExpandableText extends StatefulWidget {
  /// Creates an expandable text block.
  const ExpandableText(
    this.text, {
    super.key,
    this.maxLines = 3,
    this.style,
    this.textAlign,
  });

  final int maxLines;
  final TextStyle? style;
  final String text;
  final TextAlign? textAlign;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite) {
          return Text(
            widget.text,
            style: effectiveStyle,
            textAlign: widget.textAlign,
          );
        }

        final painter = TextPainter(
          maxLines: widget.maxLines,
          text: TextSpan(text: widget.text, style: effectiveStyle),
          textAlign: widget.textAlign ?? TextAlign.start,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = painter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.text,
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.fade,
              style: effectiveStyle,
              textAlign: widget.textAlign,
            ),
            if (isOverflowing)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(_isExpanded ? 'Show less' : 'Show more'),
              ),
          ],
        );
      },
    );
  }
}
