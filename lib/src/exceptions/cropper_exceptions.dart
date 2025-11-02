/// Exception types that can occur during image cropping operations.
///
/// Each type represents a specific category of error that can occur
/// during the image cropping process, making it easier to handle
/// different error scenarios appropriately.
enum CropperExceptionType {
  /// The cropper's context could not be found.
  /// This typically occurs when trying to crop before the widget is mounted
  /// or after it has been disposed.
  contextNotFound,

  /// The render object could not be found.
  /// This may happen if the widget tree structure is invalid.
  renderObjectNotFound,

  /// The render object is not a valid RepaintBoundary.
  /// The cropper requires a RepaintBoundary to capture the image.
  invalidRenderObject,

  /// Failed to load the image.
  /// This can occur due to network issues, invalid URLs, or corrupted image data.
  imageLoadFailed,

  /// Failed to convert the image to byte data.
  /// This may happen due to memory constraints or format issues.
  imageConversionFailed,

  /// Failed to scale or transform the image.
  /// This can occur during initial scaling or rotation operations.
  scalingFailed,

  /// An unknown or unexpected error occurred.
  /// This is a catch-all for errors that don't fit other categories.
  unknown,
}

/// Exception thrown when an error occurs during image cropping operations.
///
/// This exception provides detailed information about what went wrong,
/// including the type of error, a descriptive message, and optionally
/// a stack trace for debugging.
///
/// ## Example Usage
///
/// ```dart
/// try {
///   final bytes = await ImageCropper.crop(imageCropperKey: _imageCropperKey);
/// } on CropperException catch (e) {
///   // Handle specific error types
///   if (e.type == CropperExceptionType.imageLoadFailed) {
///     print('Failed to load image: ${e.userMessage}');
///   }
///
///   // Or show user-friendly message
///   showDialog(
///     context: context,
///     builder: (_) => AlertDialog(
///       title: Text('Error'),
///       content: Text(e.userMessage),
///     ),
///   );
/// }
/// ```
class CropperException implements Exception {
  /// A human-readable description of the error.
  ///
  /// This message is intended for developers and may contain technical details.
  final String message;

  /// The type of error that occurred.
  ///
  /// This can be used to handle different error scenarios differently.
  final CropperExceptionType type;

  /// The stack trace at the point where the exception was thrown, if available.
  ///
  /// This is useful for debugging and error reporting.
  final StackTrace? stackTrace;

  /// Creates a [CropperException] with the given message and type.
  ///
  /// The [message] should describe what went wrong in a way that's helpful
  /// to developers debugging the issue.
  ///
  /// The [type] categorizes the error for easier handling.
  ///
  /// The [stackTrace] is optional but recommended for debugging purposes.
  ///
  /// ## Example
  ///
  /// ```dart
  /// throw CropperException(
  ///   'Failed to load image from network',
  ///   type: CropperExceptionType.imageLoadFailed,
  ///   stackTrace: StackTrace.current,
  /// );
  /// ```
  CropperException(
    this.message, {
    required this.type,
    this.stackTrace,
  });

  /// Creates a [CropperException] from another exception.
  ///
  /// This is useful for wrapping lower-level exceptions with cropper-specific
  /// context.
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   // Some operation
  /// } catch (e, stackTrace) {
  ///   throw CropperException.fromException(
  ///     e,
  ///     type: CropperExceptionType.imageConversionFailed,
  ///     stackTrace: stackTrace,
  ///   );
  /// }
  /// ```
  factory CropperException.fromException(
    Object exception, {
    required CropperExceptionType type,
    StackTrace? stackTrace,
  }) {
    return CropperException(
      'Cropper error: $exception',
      type: type,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('CropperException: $message');
    buffer.write(' (type: ${type.name})');

    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }

    return buffer.toString();
  }
}
