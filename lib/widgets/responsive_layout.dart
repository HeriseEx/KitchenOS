import 'package:flutter/material.dart';

/// A wrapper widget that provides responsive layout capabilities.
/// 
/// It determines the current screen size and builds the appropriate layout.
/// It also enforces a maximum content width for larger screens to ensure readability.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget? tabletBody;
  final Widget? desktopBody;
  final bool useMaxWidthWrapper;
  final double maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    this.tabletBody,
    this.desktopBody,
    this.useMaxWidthWrapper = true,
    this.maxWidth = 1200,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 900;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content;
        if (constraints.maxWidth >= 900) {
          content = desktopBody ?? tabletBody ?? mobileBody;
        } else if (constraints.maxWidth >= 600) {
          content = tabletBody ?? mobileBody;
        } else {
          content = mobileBody;
        }

        if (useMaxWidthWrapper && constraints.maxWidth > maxWidth) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: content,
            ),
          );
        }
        return content;
      },
    );
  }
}

/// A responsive container that adds padding based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double mobilePadding;
  final double tabletPadding;
  final double desktopPadding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobilePadding = 16.0,
    this.tabletPadding = 24.0,
    this.desktopPadding = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double padding = mobilePadding;
    
    if (width >= 900) {
      padding = desktopPadding;
    } else if (width >= 600) {
      padding = tabletPadding;
    }

    return Padding(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}
