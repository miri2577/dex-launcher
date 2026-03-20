import 'package:flutter/material.dart';

/// Reusable hover container that encapsulates the common pattern of
/// MouseRegion + hover state + Container with color change.
///
/// Use this to replace repeated hover-highlight patterns across the codebase.
class HoverContainer extends StatefulWidget {
  final Widget child;
  final Widget? hoverChild;
  final double? width;
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color hoverColor;
  final Color? defaultColor;
  final VoidCallback? onTap;
  final void Function(Offset)? onSecondaryTap;
  final String? tooltip;

  const HoverContainer({
    super.key,
    required this.child,
    this.hoverChild,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.borderRadius,
    this.hoverColor = const Color(0x1FFFFFFF), // Colors.white ~12% alpha
    this.defaultColor,
    this.onTap,
    this.onSecondaryTap,
    this.tooltip,
  });

  @override
  State<HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    Widget result = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: widget.onSecondaryTap != null
            ? (details) => widget.onSecondaryTap!(details.globalPosition)
            : null,
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color: _hovering
                ? widget.hoverColor
                : (widget.defaultColor ?? Colors.transparent),
          ),
          child: _hovering && widget.hoverChild != null
              ? widget.hoverChild!
              : widget.child,
        ),
      ),
    );

    if (widget.tooltip != null) {
      result = Tooltip(
        message: widget.tooltip!,
        waitDuration: const Duration(milliseconds: 500),
        child: result,
      );
    }

    return result;
  }
}
