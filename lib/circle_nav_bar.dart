library circle_nav_bar;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class CircleNavBar extends StatefulWidget {
  /// Construct a new appBar with internal style.
  ///
  /// ```dart
  /// CircleNavBar(
  ///   activeIcons: const [
  ///     Icon(Icons.person, color: Colors.deepPurple),
  ///     Icon(Icons.home, color: Colors.deepPurple),
  ///     Icon(Icons.favorite, color: Colors.deepPurple),
  ///   ],
  ///   inactiveIcons: const [
  ///     Text("My"),
  ///     Text("Home"),
  ///     Text("Like"),
  ///   ],
  ///   color: Colors.white,
  ///   // circleColor: Colors.white,
  ///   height: 60,
  ///   circleWidth: 60,
  ///   activeIndex: 1,
  ///   onTap: (index) {
  ///   },
  ///   padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
  ///   cornerRadius: const BorderRadius.only(
  ///     topLeft: Radius.circular(8),
  ///     topRight: Radius.circular(8),
  ///     bottomRight: Radius.circular(24),
  ///     bottomLeft: Radius.circular(24),
  ///   ),
  ///   shadowColor: Colors.deepPurple,
  ///   // circleShadowColor: Colors.deepPurple,
  ///   elevation: 10,
  ///   // gradient: LinearGradient(colors: [0xFF73d1d3, 0xFFBADCC3, 0xFFDBA380].map(Color.new).toList()),
  ///   // circleGradient: LinearGradient(colors: [0xFF73d1d3, 0xFFBADCC3, 0xFFDBA380].map(Color.new).toList()),
  /// );
  /// ```
  ///
  /// ![](doc/value-05.png)
  const CircleNavBar({
    required this.activeIndex,
    this.onTap,
    this.tabCurve = Curves.linearToEaseOut,
    this.iconCurve = Curves.bounceOut,
    this.tabDurationMillSec = 500,
    this.iconDurationMillSec = 300,
    required this.activeIcons,
    required this.inactiveIcons,
    this.circleWidth = 60,
    required this.color,
    this.height = 75,
    this.circleColor,
    this.padding = EdgeInsets.zero,
    this.cornerRadius = BorderRadius.zero,
    this.shadowColor = Colors.transparent,
    this.circleShadowColor = Colors.transparent,
    this.elevation = 0,
    this.gradient,
    this.circleGradient,
    this.levels,
    this.activeLevelsStyle,
    this.inactiveLevelsStyle,
    this.onError,
    this.enableErrorReporting = true,
    super.key,
  }) : assert(circleWidth <= height, "circleWidth <= height"),
       assert(
         activeIcons.length == inactiveIcons.length,
         "activeIcons.length and inactiveIcons.length must be equal!",
       ),
       assert(
         activeIcons.length > activeIndex,
         "activeIcons.length > activeIndex",
       );

  /// Bottom bar height (without bottom padding)
  ///
  /// ![](doc/value-05.png)
  final double height;

  /// Circle icon diameter
  ///
  /// ![](doc/value-05.png)
  final double circleWidth;

  /// Bottom bar Color
  ///
  /// If you set gradient, color will be ignored
  ///
  /// ![](doc/value-05.png)
  final Color color;

  /// Circle color (for active index)
  ///
  /// If [circleGradient] is given, [circleColor] & [color] will be ignored
  /// If null, [color] will be used
  ///
  /// ![](doc/value-05.png)
  final Color? circleColor;

  /// Bottom bar activeIcon List
  ///
  /// The active icon must be smaller than the diameter of the circle
  ///
  /// activeIcons.length and inactiveIcons.length must be equal
  final List<Widget> activeIcons;

  /// Bottom bar inactiveIcon List
  ///
  /// The active icon must be smaller than the bottom bar height
  ///
  /// activeIcons.length and inactiveIcons.length must be equal
  final List<Widget> inactiveIcons;

  /// bottom bar padding
  ///
  /// It is the distance from the Scaffold
  ///
  /// ![](doc/value-05.png)
  final EdgeInsets padding;

  /// cornerRadius
  ///
  /// You can specify different values ​​for each corner
  ///
  /// ![](doc/value-05.png)
  final BorderRadius cornerRadius;

  /// shadowColor
  ///
  /// ![](doc/value-05.png)
  final Color shadowColor;

  /// Circle shadow color (for active index)
  ///
  /// If null, [shadowColor] will be used
  ///
  /// ![](doc/value-05.png)
  final Color? circleShadowColor;

  /// elevation
  final double elevation;

  /// gradient
  ///
  /// If you set gradient, [color] will be ignored
  ///
  /// ![](doc/value-05.png)
  final Gradient? gradient;

  /// Circle gradient (for active index)
  ///
  /// If null, [gradient] might be used
  ///
  /// ![](doc/value-05.png)
  final Gradient? circleGradient;

  /// active index
  final int activeIndex;

  /// When the circle icon moves left and right
  ///
  /// ![](doc/animation.gif)
  final Curve tabCurve;

  /// When the active icon moves up from the bottom
  ///
  /// /// ![](doc/animation.gif)
  final Curve iconCurve;

  /// When the circle icon moves left and right
  final int tabDurationMillSec;

  /// When the active icon moves up from the bottom
  final int iconDurationMillSec;

  /// If you tap bottom navigation menu, this function will be called
  /// You have to update widget state by setting new [activeIndex]
  final Function(int index)? onTap;

  /// User can set the levels
  final List<String>? levels;

  /// User can set the style for the Active levels
  final TextStyle? activeLevelsStyle;

  /// User can set the style for the Inactive levels
  final TextStyle? inactiveLevelsStyle;

  /// Error callback - called when an error occurs
  final Function(String error, StackTrace stackTrace)? onError;

  /// Enable automatic error reporting to clipboard
  final bool enableErrorReporting;

  @override
  State<StatefulWidget> createState() => _CircleNavBarState();
}

class _CircleNavBarState extends State<CircleNavBar>
    with TickerProviderStateMixin {
  late AnimationController tabAc;
  late AnimationController activeIconAc;
  bool _isDisposed = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    try {
      // Initialize tab animation controller with safety checks
      tabAc = AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: widget.tabDurationMillSec.clamp(100, 5000),
        ),
      );

      // Initialize active icon animation controller with safety checks
      activeIconAc = AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: widget.iconDurationMillSec.clamp(100, 5000),
        ),
      );

      // Add listeners with error handling
      tabAc.addListener(_onTabAnimationUpdate);
      activeIconAc.addListener(_onIconAnimationUpdate);

      // Set initial values safely
      final initialPosition = _getPositionSafely(widget.activeIndex);
      tabAc.value = initialPosition;
      activeIconAc.value = 1;

      _logDebug('Controllers initialized successfully');
    } catch (e, stackTrace) {
      _handleError(
        'Failed to initialize animation controllers: $e',
        stackTrace,
      );
    }
  }

  void _onTabAnimationUpdate() {
    if (!_isDisposed && mounted) {
      try {
        setState(() {});
      } catch (e, stackTrace) {
        _handleError('Tab animation update error: $e', stackTrace);
      }
    }
  }

  void _onIconAnimationUpdate() {
    if (!_isDisposed && mounted) {
      try {
        setState(() {});
      } catch (e, stackTrace) {
        _handleError('Icon animation update error: $e', stackTrace);
      }
    }
  }

  @override
  void didUpdateWidget(covariant CircleNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    try {
      // Only animate if activeIndex changed and within bounds
      if (oldWidget.activeIndex != widget.activeIndex) {
        _performAnimation();
      }

      // Update duration if changed
      if (oldWidget.tabDurationMillSec != widget.tabDurationMillSec) {
        _updateTabDuration();
      }

      if (oldWidget.iconDurationMillSec != widget.iconDurationMillSec) {
        _updateIconDuration();
      }
    } catch (e, stackTrace) {
      _handleError('Widget update error: $e', stackTrace);
    }
  }

  void _updateTabDuration() {
    try {
      if (!_isDisposed && tabAc.isAnimating) {
        tabAc.stop();
      }
      tabAc.duration = Duration(
        milliseconds: widget.tabDurationMillSec.clamp(100, 5000),
      );
    } catch (e, stackTrace) {
      _handleError('Tab duration update error: $e', stackTrace);
    }
  }

  void _updateIconDuration() {
    try {
      if (!_isDisposed && activeIconAc.isAnimating) {
        activeIconAc.stop();
      }
      activeIconAc.duration = Duration(
        milliseconds: widget.iconDurationMillSec.clamp(100, 5000),
      );
    } catch (e, stackTrace) {
      _handleError('Icon duration update error: $e', stackTrace);
    }
  }

  void _performAnimation() {
    if (_isDisposed || !mounted) return;

    try {
      final nextPosition = _getPositionSafely(widget.activeIndex);

      // Stop current animations safely
      if (tabAc.isAnimating) {
        tabAc.stop();
      }
      if (activeIconAc.isAnimating) {
        activeIconAc.stop();
      }

      // Start new animations with error handling
      tabAc.animateTo(nextPosition, curve: widget.tabCurve).catchError((e) {
        _handleError('Tab animation error: $e', StackTrace.current);
      });

      activeIconAc.reset();
      activeIconAc.animateTo(1, curve: widget.iconCurve).catchError((e) {
        _handleError('Icon animation error: $e', StackTrace.current);
      });

      _logDebug('Animation started for index: ${widget.activeIndex}');
    } catch (e, stackTrace) {
      _handleError('Animation setup error: $e', stackTrace);
    }
  }

  double _getPositionSafely(int index) {
    try {
      final itemCount = widget.activeIcons.length;
      if (itemCount == 0) {
        _logDebug('Warning: No active icons available');
        return 0.5;
      }

      final clampedIndex = index.clamp(0, itemCount - 1);
      final position = clampedIndex / itemCount + (1 / itemCount) / 2;

      return position.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      _handleError('Position calculation error: $e', stackTrace);
      return 0.5; // Fallback to center
    }
  }

  double getPosition(int i) => _getPositionSafely(i);

  void _handleError(String message, StackTrace stackTrace) {
    _hasError = true;
    _errorMessage = message;

    _logDebug('ERROR: $message');
    _logDebug('StackTrace: $stackTrace');

    // Call user-defined error handler
    widget.onError?.call(message, stackTrace);

    // Copy to clipboard if enabled
    if (widget.enableErrorReporting) {
      _copyErrorToClipboard(message, stackTrace);
    }

    // Try to recover by resetting states
    _attemptRecovery();
  }

  void _copyErrorToClipboard(String message, StackTrace stackTrace) {
    try {
      final errorReport =
          '''
CircleNavBar Error Report
========================
Error: $message
Time: ${DateTime.now()}
Device Info: Flutter App
Stack Trace: $stackTrace

Widget State:
- ActiveIndex: ${widget.activeIndex}
- ActiveIcons Length: ${widget.activeIcons.length}
- InactiveIcons Length: ${widget.inactiveIcons.length}
- Is Disposed: $_isDisposed
- Is Mounted: $mounted
- Tab Controller Status: ${tabAc.status}
- Icon Controller Status: ${activeIconAc.status}
      ''';

      Clipboard.setData(ClipboardData(text: errorReport));
      _showErrorSnackbar('Error details copied to clipboard');
    } catch (e) {
      _logDebug('Failed to copy error to clipboard: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    try {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      _logDebug('Failed to show snackbar: $e');
    }
  }

  void _attemptRecovery() {
    try {
      if (!_isDisposed && mounted) {
        // Reset animation states
        if (tabAc.isAnimating) tabAc.stop();
        if (activeIconAc.isAnimating) activeIconAc.stop();

        // Reset to safe values
        final safePosition = _getPositionSafely(widget.activeIndex);
        tabAc.value = safePosition;
        activeIconAc.value = 1.0;

        _logDebug('Recovery attempt completed');
      }
    } catch (e) {
      _logDebug('Recovery failed: $e');
    }
  }

  void _logDebug(String message) {
    debugPrint('[CircleNavBar] $message');
  }

  @override
  Widget build(BuildContext context) {
    // Safety check for context and mounting
    if (!mounted || _hasError) {
      return _buildErrorWidget();
    }

    try {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery == null) {
        throw Exception('MediaQuery not found in context');
      }

      final deviceWidth = mediaQuery.size.width;

      // Validate device width
      if (deviceWidth <= 0 || !deviceWidth.isFinite) {
        throw Exception('Invalid device width: $deviceWidth');
      }

      // Validate activeIndex bounds
      if (widget.activeIndex < 0 ||
          widget.activeIndex >= widget.activeIcons.length) {
        throw Exception('ActiveIndex out of bounds: ${widget.activeIndex}');
      }

      return _buildNavBar(deviceWidth);
    } catch (e, stackTrace) {
      _handleError('Build error: $e', stackTrace);
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: widget.padding,
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: widget.cornerRadius,
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(height: 4),
            Text(
              'NavBar Error',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 2),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade600, fontSize: 8),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(double deviceWidth) {
    return Container(
      margin: widget.padding,
      width: double.infinity,
      height: widget.height,
      child: Stack(
        children: [
          // Navigation Bar Background
          CustomPaint(
            painter: _CircleBottomPainter(
              iconWidth: widget.circleWidth,
              color: widget.color,
              circleColor: widget.circleColor ?? widget.color,
              xOffsetPercent: tabAc.value.clamp(0.0, 1.0),
              boxRadius: widget.cornerRadius,
              shadowColor: widget.shadowColor,
              circleShadowColor: widget.circleShadowColor ?? widget.shadowColor,
              elevation: widget.elevation.clamp(0.0, 50.0),
              gradient: widget.gradient,
              circleGradient: widget.circleGradient ?? widget.gradient,
            ),
            child: SizedBox(height: widget.height, width: double.infinity),
          ),
          // Bottom Navigation Bar with Inactive Icons and Labels
          _buildInactiveIcons(),
          // Floating Active Icon
          _buildActiveIcon(deviceWidth),
        ],
      ),
    );
  }

  Widget _buildInactiveIcons() {
    return Row(
      children: widget.inactiveIcons.asMap().entries.map((entry) {
        final index = entry.key;
        final icon = entry.value;
        final isActive = widget.activeIndex == index;

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              try {
                if (index != widget.activeIndex) {
                  widget.onTap?.call(index);
                  _logDebug('Tab tapped: $index');
                }
              } catch (e, stackTrace) {
                _handleError('Tap handler error: $e', stackTrace);
              }
            },
            child: Column(
              mainAxisAlignment:
                  widget.levels != null && index < widget.levels!.length
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.center,
              children: [
                if (!isActive) icon,
                if (widget.levels != null && index < widget.levels!.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                    child: Text(
                      widget.levels![index],
                      style: isActive
                          ? widget.activeLevelsStyle
                          : widget.inactiveLevelsStyle,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveIcon(double deviceWidth) {
    final safeActiveIndex = widget.activeIndex.clamp(
      0,
      widget.activeIcons.length - 1,
    );
    final leftPosition =
        tabAc.value * deviceWidth -
        widget.circleWidth / 2 -
        tabAc.value * (widget.padding.left + widget.padding.right);

    return Positioned(
      left: leftPosition.clamp(0, deviceWidth - widget.circleWidth),
      child: Transform.scale(
        scale: activeIconAc.value.clamp(0.0, 2.0),
        child: Container(
          width: widget.circleWidth,
          height: widget.circleWidth,
          transform: Matrix4.translationValues(
            0,
            -(widget.circleWidth * 0.5) +
                _CircleBottomPainter.getMiniRadius(widget.circleWidth) -
                widget.circleWidth * 0.5 * (1 - activeIconAc.value),
            0,
          ),
          child: widget.activeIcons[safeActiveIndex],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;

    try {
      // Remove listeners first
      tabAc.removeListener(_onTabAnimationUpdate);
      activeIconAc.removeListener(_onIconAnimationUpdate);

      // Stop animations
      if (tabAc.isAnimating) tabAc.stop();
      if (activeIconAc.isAnimating) activeIconAc.stop();

      // Dispose controllers
      tabAc.dispose();
      activeIconAc.dispose();

      _logDebug('Controllers disposed successfully');
    } catch (e) {
      _logDebug('Disposal error: $e');
    }

    super.dispose();
  }
}

class _CircleBottomPainter extends CustomPainter {
  _CircleBottomPainter({
    required this.iconWidth,
    required this.color,
    required this.circleColor,
    required this.xOffsetPercent,
    required this.boxRadius,
    required this.shadowColor,
    required this.circleShadowColor,
    required this.elevation,
    this.gradient,
    this.circleGradient,
  });

  final Color color;
  final Color circleColor;
  final double iconWidth;
  final double xOffsetPercent;
  final BorderRadius boxRadius;
  final Color shadowColor;
  final Color circleShadowColor;
  final double elevation;
  final Gradient? gradient;
  final Gradient? circleGradient;

  static double getR(double circleWidth) {
    return (circleWidth / 2 * 1.2).clamp(10.0, 200.0);
  }

  static double getMiniRadius(double circleWidth) {
    return (getR(circleWidth) * 0.3).clamp(5.0, 100.0);
  }

  static double convertRadiusToSigma(double radius) {
    return (radius * 0.57735 + 0.5).clamp(0.0, 50.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // Validate size
      if (size.width <= 0 ||
          size.height <= 0 ||
          !size.width.isFinite ||
          !size.height.isFinite) {
        debugPrint('[CircleNavBar] Invalid canvas size: $size');
        return;
      }

      Path path = Path();
      Paint paint = Paint();
      Paint? circlePaint;

      if (color != circleColor || circleGradient != null) {
        circlePaint = Paint();
        circlePaint.color = circleColor;
      }

      final w = size.width;
      final h = size.height;
      final r = getR(iconWidth);
      final miniRadius = getMiniRadius(iconWidth);
      final x = (xOffsetPercent * w).clamp(r, w - r);
      final firstX = x - r;
      final secondX = x + r;

      // Build path with safety checks
      _buildPath(path, w, h, r, miniRadius, firstX, secondX);

      paint.color = color;

      // Apply gradients safely
      _applyGradients(paint, circlePaint, w, h, x, miniRadius);

      // Draw shadows safely
      _drawShadows(canvas, path, x, miniRadius);

      // Draw main shapes
      canvas.drawPath(path, paint);
      canvas.drawCircle(
        Offset(x, miniRadius),
        (iconWidth / 2).clamp(5.0, 100.0),
        circlePaint ?? paint,
      );
    } catch (e) {
      debugPrint('[CircleNavBar] Paint error: $e');
      // Draw fallback rectangle
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = color,
      );
    }
  }

  void _buildPath(
    Path path,
    double w,
    double h,
    double r,
    double miniRadius,
    double firstX,
    double secondX,
  ) {
    // TopLeft Radius
    path.moveTo(0, 0 + boxRadius.topLeft.y);
    path.quadraticBezierTo(0, 0, boxRadius.topLeft.x, 0);
    path.lineTo(firstX - miniRadius, 0);
    path.quadraticBezierTo(firstX, 0, firstX, miniRadius);

    path.arcToPoint(
      Offset(secondX, miniRadius),
      radius: Radius.circular(r),
      clockwise: false,
    );

    path.quadraticBezierTo(secondX, 0, secondX + miniRadius, 0);

    // TopRight Radius
    path.lineTo(w - boxRadius.topRight.x, 0);
    path.quadraticBezierTo(w, 0, w, boxRadius.topRight.y);

    // BottomRight Radius
    path.lineTo(w, h - boxRadius.bottomRight.y);
    path.quadraticBezierTo(w, h, w - boxRadius.bottomRight.x, h);

    // BottomLeft Radius
    path.lineTo(boxRadius.bottomLeft.x, h);
    path.quadraticBezierTo(0, h, 0, h - boxRadius.bottomLeft.y);

    path.close();
  }

  void _applyGradients(
    Paint paint,
    Paint? circlePaint,
    double w,
    double h,
    double x,
    double miniRadius,
  ) {
    if (gradient != null) {
      try {
        Rect shaderRect = Rect.fromCircle(
          center: Offset(w / 2, h / 2),
          radius: 180.0,
        );
        paint.shader = gradient!.createShader(shaderRect);
      } catch (e) {
        debugPrint('[CircleNavBar] Gradient shader error: $e');
      }
    }

    if (circleGradient != null && circlePaint != null) {
      try {
        Rect shaderRect = Rect.fromCircle(
          center: Offset(x, miniRadius),
          radius: iconWidth / 2,
        );
        circlePaint.shader = circleGradient!.createShader(shaderRect);
      } catch (e) {
        debugPrint('[CircleNavBar] Circle gradient shader error: $e');
      }
    }
  }

  void _drawShadows(Canvas canvas, Path path, double x, double miniRadius) {
    if (elevation > 0) {
      try {
        final sigma = convertRadiusToSigma(elevation);

        // Draw path shadow
        canvas.drawPath(
          path,
          Paint()
            ..color = shadowColor
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
        );

        // Draw circle shadow
        canvas.drawCircle(
          Offset(x, miniRadius),
          iconWidth / 2,
          Paint()
            ..color = circleShadowColor
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
        );
      } catch (e) {
        debugPrint('[CircleNavBar] Shadow drawing error: $e');
      }
    }
  }

  @override
  bool shouldRepaint(_CircleBottomPainter oldDelegate) {
    return oldDelegate.xOffsetPercent != xOffsetPercent ||
        oldDelegate.iconWidth != iconWidth ||
        oldDelegate.color != color ||
        oldDelegate.circleColor != circleColor;
  }
}
