import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'clipper/overlay_clipper.dart';
import 'exceptions/cropper_exceptions.dart';

/// A highly customizable image cropper widget with support for various overlay types,
/// zoom controls, rotation, and aspect ratio constraints.
///
/// Example usage:
/// ```dart
/// final imageCropperKey = GlobalKey();
///
/// ImageCropper(
///   imageCropperKey: imageCropperKey,
///   image: Image.network('https://example.com/image.jpg'),
///   aspectRatio: 16 / 9,
///   overlayType: OverlayType.grid,
/// )
///
/// // To crop the image:
/// final croppedBytes = await ImageCropper.crop(imageCropperKey: imageCropperKey);
/// ```
class ProfileImageCropper extends StatefulWidget {
  /// The cropper's key to reference when calling the crop function.
  /// This key is required to access the render boundary for cropping.
  final GlobalKey imageCropperKey;

  /// The background color of the cropper widget, visible when the image won't
  /// fill the entire widget. Defaults to [Color(0xFFCECECE)].
  final Color backgroundColor;

  /// The color of the cropper's overlay. Defaults to semi-transparent black
  /// [Colors.black38].
  final Color overlayColor;

  /// The type of semi-transparent overlay. Can be circle, rectangle, grid variants,
  /// or none. Defaults to [OverlayType.none].
  final OverlayType overlayType;

  /// The maximum scale the user is able to zoom. Must be greater than [minZoomScale].
  /// Defaults to 2.5.
  final double maxZoomScale;

  /// The minimum scale the user is able to zoom. Must be positive and less than
  /// [maxZoomScale]. Defaults to 0.1.
  final double minZoomScale;

  /// The aspect ratio to crop the image to. Must be positive.
  /// Defaults to 1.0 (square).
  final double aspectRatio;

  /// The number of clockwise quarter turns the image should be rotated.
  /// Defaults to 0.
  final int rotationTurns;

  /// The thickness of the grid lines when using grid overlay types.
  /// Defaults to 2.0.
  final double gridLineThickness;

  /// The image to crop. This is required.
  final Image image;

  /// Callback fired when the user begins a scale gesture.
  final GestureScaleStartCallback? onScaleStart;

  /// Callback fired when the user updates a scale gesture.
  final GestureScaleUpdateCallback? onScaleUpdate;

  /// Callback fired when the user ends a scale gesture.
  final GestureScaleEndCallback? onScaleEnd;

  /// Callback fired when an error occurs during image processing.
  final void Function(CropperException)? onError;

  /// Whether to enable haptic feedback on interactions.
  /// Defaults to false.
  final bool enableHapticFeedback;

  /// The duration of the scale animation when setting initial scale.
  /// Set to [Duration.zero] to disable animation.
  /// Defaults to 300 milliseconds.
  final Duration scalingAnimationDuration;

  /// Creates an [ProfileImageCropper] widget.
  ///
  /// The [imageCropperKey] and [image] parameters are required.
  /// The [aspectRatio], [maxZoomScale], and [minZoomScale] must be positive values.
  const ProfileImageCropper({
    super.key,
    required this.imageCropperKey,
    required this.image,
    this.backgroundColor = const Color(0xFFCECECE),
    this.overlayColor = Colors.black38,
    this.overlayType = OverlayType.none,
    this.maxZoomScale = 2.5,
    this.minZoomScale = 0.1,
    this.gridLineThickness = 2.0,
    this.aspectRatio = 1.0,
    this.rotationTurns = 0,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onError,
    this.enableHapticFeedback = false,
    this.scalingAnimationDuration = const Duration(milliseconds: 300),
  })  : assert(aspectRatio > 0, 'Aspect ratio must be positive'),
        assert(maxZoomScale > 0, 'Max zoom scale must be positive'),
        assert(minZoomScale > 0, 'Min zoom scale must be positive'),
        assert(maxZoomScale > minZoomScale, 'Max zoom scale must be greater than min zoom scale'),
        assert(gridLineThickness >= 0, 'Grid line thickness must be non-negative');

  @override
  State<ProfileImageCropper> createState() => _ProfileImageCropperState();

  /// Crops the image as displayed in the cropper widget and returns it as [Uint8List]
  /// in PNG format.
  ///
  /// Parameters:
  /// - [imageCropperKey]: The GlobalKey associated with the ImageCropper widget
  /// - [pixelRatio]: The pixel density for the output image. Higher values produce
  ///   higher resolution images. Defaults to 3.0.
  /// - [format]: The output image format. Defaults to PNG.
  ///
  /// Returns a [Future] that completes with the cropped image bytes, or null if
  /// cropping fails.
  ///
  /// Throws [CropperException] if the cropper context is not found or if image
  /// processing fails.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final bytes = await ImageCropper.crop(
  ///     imageCropperKey: _imageCropperKey,
  ///     pixelRatio: 3.0,
  ///   );
  ///   if (bytes != null) {
  ///     // Use the cropped image
  ///   }
  /// } on CropperException catch (e) {
  ///   print('Cropping failed: ${e.message}');
  /// }
  /// ```
  static Future<Uint8List?> crop({
    required GlobalKey imageCropperKey,
    double pixelRatio = 3.0,
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    assert(pixelRatio > 0, 'Pixel ratio must be positive');

    try {
      // Validate context
      final context = imageCropperKey.currentContext;
      if (context == null) {
        throw CropperException(
          'Cropper context not found. Make sure the ImageCropper widget is mounted.',
          type: CropperExceptionType.contextNotFound,
        );
      }

      // Get render object
      final renderObject = context.findRenderObject();
      if (renderObject == null) {
        throw CropperException(
          'Render object not found.',
          type: CropperExceptionType.renderObjectNotFound,
        );
      }

      if (renderObject is! RenderRepaintBoundary) {
        throw CropperException(
          'Render object is not a RepaintBoundary.',
          type: CropperExceptionType.invalidRenderObject,
        );
      }

      // Convert to image
      final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);

      // Convert to bytes
      final byteData = await image.toByteData(format: format);

      if (byteData == null) {
        throw CropperException(
          'Failed to convert image to byte data.',
          type: CropperExceptionType.imageConversionFailed,
        );
      }

      return byteData.buffer.asUint8List();
    } on CropperException {
      rethrow;
    } catch (e, stackTrace) {
      throw CropperException(
        'Unexpected error during cropping: $e',
        type: CropperExceptionType.unknown,
        stackTrace: stackTrace,
      );
    }
  }
}

class _ProfileImageCropperState extends State<ProfileImageCropper> with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  Animation<Matrix4>? _scaleAnimation;

  bool _hasImageUpdated = false;
  bool _shouldSetInitialScale = false;
  bool _shouldUpdateScale = false;
  bool _isImageLoaded = false;

  final _imageConfiguration = const ImageConfiguration();

  late final ImageStreamListener _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.scalingAnimationDuration,
    );

    _imageStreamListener = ImageStreamListener(
      _onImageLoaded,
      onError: _onImageError,
    );

    _hasImageUpdated = true;
  }

  void _onImageLoaded(ImageInfo info, bool synchronousCall) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isImageLoaded = true;
          _shouldSetInitialScale = true;
        });
      }
    });
  }

  void _onImageError(Object exception, StackTrace? stackTrace) {
    if (!mounted) return;

    final cropperException = CropperException(
      'Failed to load image: $exception',
      type: CropperExceptionType.imageLoadFailed,
      stackTrace: stackTrace,
    );

    widget.onError?.call(cropperException);

    if (kDebugMode) {
      debugPrint('ImageCropper Error: ${cropperException.message}');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  @override
  void didUpdateWidget(covariant ProfileImageCropper oldWidget) {
    super.didUpdateWidget(oldWidget);

    _hasImageUpdated = oldWidget.image.image != widget.image.image;
    _shouldUpdateScale = oldWidget.rotationTurns != widget.rotationTurns || oldWidget.aspectRatio != widget.aspectRatio;

    if (_hasImageUpdated) {
      _isImageLoaded = false;
    }

    if (oldWidget.scalingAnimationDuration != widget.scalingAnimationDuration) {
      _animationController.duration = widget.scalingAnimationDuration;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: widget.backgroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RepaintBoundary(
              key: widget.imageCropperKey,
              child: AspectRatio(
                aspectRatio: widget.aspectRatio,
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    return InteractiveViewer(
                      clipBehavior: Clip.none,
                      transformationController: _transformationController,
                      constrained: false,
                      minScale: widget.minZoomScale,
                      maxScale: widget.maxZoomScale,
                      onInteractionStart: _handleScaleStart,
                      onInteractionUpdate: widget.onScaleUpdate,
                      onInteractionEnd: widget.onScaleEnd,
                      child: Builder(
                        builder: (context) {
                          _handleImageStream(context, constraints.biggest);

                          return RotatedBox(
                            quarterTurns: widget.rotationTurns,
                            child: widget.image,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            _buildOverlay(),
          ],
        ),
      ),
    );
  }

  void _handleImageStream(BuildContext context, Size parentSize) {
    final imageStream = widget.image.image.resolve(_imageConfiguration);

    if (_hasImageUpdated && _shouldSetInitialScale && _isImageLoaded) {
      imageStream.removeListener(_imageStreamListener);
      _setInitialScale(context, parentSize);
    }

    if (_hasImageUpdated && !_shouldSetInitialScale) {
      imageStream.addListener(_imageStreamListener);
    }

    if (_shouldUpdateScale && _isImageLoaded) {
      _setInitialScale(context, parentSize);
      _shouldUpdateScale = false;
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    widget.onScaleStart?.call(details);
  }

  Widget _buildOverlay() {
    if (widget.overlayType == OverlayType.none) {
      return const SizedBox.shrink();
    }

    final overlayWidgets = <Widget>[];

    // Add shape overlay (circle or rectangle)
    if (widget.overlayType == OverlayType.circle || widget.overlayType == OverlayType.rectangle) {
      overlayWidgets.add(
        Positioned.fill(
          child: ClipPath(
            clipper: OverlayClipper(
              aspectRatio: widget.aspectRatio,
              overlayType: widget.overlayType,
            ),
            child: Container(
              color: widget.overlayColor,
            ),
          ),
        ),
      );
    }

    // Add grid lines
    if (widget.overlayType == OverlayType.grid || widget.overlayType == OverlayType.gridHorizontal) {
      overlayWidgets.add(_buildHorizontalGridLines());
    }

    if (widget.overlayType == OverlayType.grid || widget.overlayType == OverlayType.gridVertical) {
      overlayWidgets.add(_buildVerticalGridLines());
    }

    return Stack(children: overlayWidgets);
  }

  Widget _buildHorizontalGridLines() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            2,
            (_) => Divider(
              color: widget.overlayColor,
              thickness: widget.gridLineThickness,
              height: widget.gridLineThickness,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalGridLines() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            2,
            (_) => VerticalDivider(
              color: widget.overlayColor,
              thickness: widget.gridLineThickness,
              width: widget.gridLineThickness,
            ),
          ),
        ),
      ),
    );
  }

  /// Calculates the scale ratio needed to cover the parent size with the child size
  double _getCoverRatio(Size outside, Size inside) {
    if (inside.width == 0 || inside.height == 0) return 1.0;

    final widthRatio = outside.width / inside.width;
    final heightRatio = outside.height / inside.height;

    return max(widthRatio, heightRatio);
  }

  /// Calculates the X translation needed to center the image
  double _getTranslationX(Size outside, Size inside, double coverRatio) {
    return (outside.width / coverRatio - inside.width) / 2;
  }

  /// Calculates the Y translation needed to center the image
  double _getTranslationY(Size outside, Size inside, double coverRatio) {
    return (outside.height / coverRatio - inside.height) / 2;
  }

  void _setInitialScale(BuildContext context, Size parentSize) {
    if (parentSize == Size.zero) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      final childSize = renderBox?.size;

      if (childSize == null || childSize == Size.zero) return;

      try {
        final coverRatio = _getCoverRatio(parentSize, childSize);
        final targetMatrix = Matrix4.identity();

        targetMatrix.scaleByDouble(coverRatio, coverRatio, coverRatio, 1.0);
        targetMatrix.translateByDouble(_getTranslationX(parentSize, childSize, coverRatio), _getTranslationY(parentSize, childSize, coverRatio), 1.0, 1.0);

        // Animate if duration is non-zero
        if (widget.scalingAnimationDuration > Duration.zero) {
          _animateToScale(targetMatrix);
        } else {
          _transformationController.value = targetMatrix;
        }

        _shouldSetInitialScale = false;
      } catch (e, stackTrace) {
        final exception = CropperException(
          'Failed to set initial scale: $e',
          type: CropperExceptionType.scalingFailed,
          stackTrace: stackTrace,
        );
        widget.onError?.call(exception);

        if (kDebugMode) {
          debugPrint('ImageCropper Error: ${exception.message}');
        }
      }
    });
  }

  void _animateToScale(Matrix4 targetMatrix) {
    _scaleAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation!.addListener(() {
      if (mounted) {
        _transformationController.value = _scaleAnimation!.value;
      }
    });

    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    try {
      // remove image listener if it was added
      widget.image.image.resolve(_imageConfiguration).removeListener(_imageStreamListener);
    } catch (_) {
      // ignore if not attached
    }

    _animationController.stop();
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }
}
