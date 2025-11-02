import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:profile_image_cropper/profile_image_cropper.dart';

class CustomImageCropper {
  static Future<void> showCropDialog({
    required BuildContext context,
    required Uint8List imageBytes,
    required Function(Uint8List) onCropped,
    required OverlayType overlayType,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CropperDialog(
        imageBytes: imageBytes,
        onCropped: onCropped,
        overlayType: overlayType,
      ),
    );
  }
}

class _CropperDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List) onCropped;
  final OverlayType overlayType;

  const _CropperDialog({
    required this.imageBytes,
    required this.onCropped,
    required this.overlayType,
  });

  @override
  State<_CropperDialog> createState() => _CropperDialogState();
}

class _CropperDialogState extends State<_CropperDialog> {
  final GlobalKey _imageCropperKey = GlobalKey(debugLabel: 'imageCropperKey');
  bool _isCropping = false;
  late OverlayType _overlayType;

  final overlayIcons = {
    OverlayType.circle: Icons.circle_outlined,
    OverlayType.grid: Icons.grid_on,
    OverlayType.rectangle: Icons.crop_square,
  };

  int _rotationTurns = 0;

  @override
  void initState() {
    super.initState();
    _overlayType = widget.overlayType;
  }

  Future<void> _cropImage() async {
    setState(() => _isCropping = true);

    try {
      final croppedBytes = await ProfileImageCropper.crop(
        imageCropperKey: _imageCropperKey,
      );
      if (croppedBytes == null) throw Exception('Failed to crop image');

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCropped(croppedBytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cropping image: $e')));
    } finally {
      if (mounted) setState(() => _isCropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 600;

    final dialogWidth = isTablet ? 500.0 : double.infinity;
    final dialogHeight = isTablet ? 600.0 : 500.0;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                color: Theme.of(context).primaryColor,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Crop Image',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: _isCropping
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.done, color: Colors.white),
                    onPressed: _isCropping ? null : _cropImage,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ProfileImageCropper(
                  imageCropperKey: _imageCropperKey,
                  overlayType: _overlayType,
                  rotationTurns: _rotationTurns,
                  image: Image.memory(widget.imageBytes),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _bottomButton(
                  icon: Icons.rotate_left,
                  onTap: () => setState(() => _rotationTurns--),
                ),
                _bottomButton(
                  icon: Icons.rotate_right,
                  onTap: () => setState(() => _rotationTurns++),
                ),
                _bottomButton(
                  icon: overlayIcons[_overlayType] ?? Icons.circle,
                  onTap: () {
                    setState(() {
                      _overlayType = _overlayType == OverlayType.circle
                          ? OverlayType.grid
                          : _overlayType == OverlayType.grid
                          ? OverlayType.rectangle
                          : OverlayType.circle;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }
}
