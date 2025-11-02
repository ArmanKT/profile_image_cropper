import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The type of overlay to display on the image cropper.
///
/// This enum is used to determine the shape and style of the
/// semi-transparent overlay that shows the crop area.
enum OverlayType {
  /// Circular overlay with semi-transparent outer area.
  ///
  /// Perfect for profile pictures and avatars.
  circle,

  /// Rectangular overlay with semi-transparent outer area.
  ///
  /// Good for general-purpose cropping with aspect ratio control.
  rectangle,

  /// Grid overlay with both horizontal and vertical lines (3x3 grid).
  ///
  /// Follows the rule of thirds for composition guidance.
  grid,

  /// Grid overlay with only horizontal lines.
  ///
  /// Useful for landscape-oriented crops.
  gridHorizontal,

  /// Grid overlay with only vertical lines.
  ///
  /// Useful for portrait-oriented crops.
  gridVertical,

  /// No overlay is displayed.
  ///
  /// Shows the image without any overlay effects.
  none,
}

/// A custom clipper that creates an overlay with a transparent area
/// in the shape of a circle or rectangle based on the specified aspect ratio.
///
/// This clipper is used internally by [ImageCropper] to create the
/// semi-transparent overlay effect that shows users the crop area.
///
/// The clipper works by creating a path that covers the entire area,
/// then subtracting the crop area shape from it using [PathOperation.difference].
///
/// ## Example Usage
///
/// ```dart
/// ClipPath(
///   clipper: OverlayClipper(
///     aspectRatio: 16 / 9,
///     overlayType: OverlayType.rectangle,
///     cornerRadius: 8.0,
///   ),
///   child: Container(color: Colors.black54),
/// )
/// ```
class OverlayClipper extends CustomClipper<Path> {
  /// The aspect ratio of the transparent crop area.
  ///
  /// Must be positive. A value of 1.0 creates a square,
  /// values > 1.0 create landscape rectangles,
  /// and values < 1.0 create portrait rectangles.
  final double aspectRatio;

  /// The type of overlay to create.
  ///
  /// Determines whether to clip a circle or rectangle shape.
  /// Grid types don't use clipping and should not use this clipper.
  final OverlayType overlayType;

  /// The radius of the corners for rectangle overlays.
  ///
  /// If null, sharp corners are used.
  /// If specified, must be non-negative.
  /// The effective radius will be clamped to half the minimum dimension
  /// to prevent excessive rounding.
  final double? cornerRadius;

  /// The padding around the crop area.
  ///
  /// This creates space between the edge of the widget and the crop area.
  /// Useful for adding visual breathing room.
  final EdgeInsets padding;

  /// Creates an [OverlayClipper] with the specified parameters.
  ///
  /// The [aspectRatio] must be positive.
  /// The [cornerRadius], if provided, must be non-negative.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Square crop with rounded corners
  /// OverlayClipper(
  ///   aspectRatio: 1.0,
  ///   overlayType: OverlayType.rectangle,
  ///   cornerRadius: 16.0,
  /// )
  ///
  /// // Circular crop
  /// OverlayClipper(
  ///   aspectRatio: 1.0,
  ///   overlayType: OverlayType.circle,
  /// )
  ///
  /// // 16:9 crop with padding
  /// OverlayClipper(
  ///   aspectRatio: 16 / 9,
  ///   overlayType: OverlayType.rectangle,
  ///   padding: EdgeInsets.all(16.0),
  /// )
  /// ```
  OverlayClipper({
    required this.aspectRatio,
    required this.overlayType,
    this.cornerRadius,
    this.padding = EdgeInsets.zero,
  })  : assert(aspectRatio > 0, 'Aspect ratio must be positive'),
        assert(cornerRadius == null || cornerRadius >= 0, 'Corner radius must be non-negative');

  @override
  Path getClip(Size size) {
    // Apply padding to the available size
    final availableSize = Size(
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );

    // Calculate the dimensions of the transparent area
    final dimensions = _calculateDimensions(availableSize);
    final cropWidth = dimensions.$1;
    final cropHeight = dimensions.$2;

    // Calculate center point accounting for padding
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    // Create the transparent area path
    final opening = _createOpeningPath(center, cropWidth, cropHeight);

    // Combine the full screen path with the opening to create the overlay
    return Path.combine(
      PathOperation.difference,
      _createFullScreenPath(size),
      opening..close(),
    );
  }

  /// Calculates the dimensions (width and height) of the transparent crop area
  /// based on the aspect ratio and available size.
  ///
  /// Returns a record of (width, height).
  ///
  /// The algorithm ensures the crop area fits within the available space
  /// while maintaining the specified aspect ratio.
  (double, double) _calculateDimensions(Size availableSize) {
    double cropWidth;
    double cropHeight;

    // Determine if we should fit to width or height
    final availableAspectRatio = availableSize.width / availableSize.height;

    if (aspectRatio >= availableAspectRatio) {
      // Fit to width (crop area is relatively wider)
      cropWidth = availableSize.width;
      cropHeight = cropWidth / aspectRatio;

      // Ensure we don't exceed available height
      if (cropHeight > availableSize.height) {
        cropHeight = availableSize.height;
        cropWidth = cropHeight * aspectRatio;
      }
    } else {
      // Fit to height (crop area is relatively taller)
      cropHeight = availableSize.height;
      cropWidth = cropHeight * aspectRatio;

      // Ensure we don't exceed available width
      if (cropWidth > availableSize.width) {
        cropWidth = availableSize.width;
        cropHeight = cropWidth / aspectRatio;
      }
    }

    return (cropWidth, cropHeight);
  }

  /// Creates the path for the transparent opening based on the overlay type.
  ///
  /// The path is centered at [center] with the specified [width] and [height].
  Path _createOpeningPath(Offset center, double width, double height) {
    switch (overlayType) {
      case OverlayType.circle:
        return _createCirclePath(center, width, height);

      case OverlayType.rectangle:
        return _createRectanglePath(center, width, height);

      case OverlayType.grid:
      case OverlayType.gridHorizontal:
      case OverlayType.gridVertical:
      case OverlayType.none:
        // Grid types don't use clipping, return empty path
        return Path();
    }
  }

  /// Creates a circular path centered at the given point.
  ///
  /// The radius is calculated as half the minimum dimension
  /// to ensure the circle fits within the crop area.
  Path _createCirclePath(Offset center, double width, double height) {
    final radius = math.min(width, height) / 2;
    final path = Path();

    path.addOval(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
    );

    return path;
  }

  /// Creates a rectangular path centered at the given point.
  ///
  /// Applies corner radius if specified. The effective corner radius
  /// is clamped to prevent over-rounding.
  Path _createRectanglePath(Offset center, double width, double height) {
    final path = Path();
    final rect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    if (cornerRadius != null && cornerRadius! > 0) {
      // Clamp corner radius to half the minimum dimension
      final maxRadius = math.min(width, height) / 2;
      final effectiveRadius = math.min(cornerRadius!, maxRadius);

      path.addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(effectiveRadius),
        ),
      );
    } else {
      path.addRect(rect);
    }

    return path;
  }

  /// Creates a path that covers the entire available size.
  ///
  /// This is used as the base for the overlay before subtracting
  /// the crop area.
  Path _createFullScreenPath(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldReclip(covariant OverlayClipper oldClipper) {
    // Reclip when any property that affects the clip changes
    return aspectRatio != oldClipper.aspectRatio || overlayType != oldClipper.overlayType || cornerRadius != oldClipper.cornerRadius || padding != oldClipper.padding;
  }
}
