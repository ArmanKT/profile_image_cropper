import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:profile_image_cropper/profile_image_cropper.dart';
import 'cropper_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Cropper Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CircleCropPage(),
    );
  }
}

class CircleCropPage extends StatefulWidget {
  const CircleCropPage({super.key});

  @override
  State<CircleCropPage> createState() => _CircleCropPageState();
}

class _CircleCropPageState extends State<CircleCropPage> {
  final ImagePicker _picker = ImagePicker();
  File? _croppedFile;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;

      await CustomImageCropper.showCropDialog(
        context: context,
        imageBytes: bytes,
        overlayType: OverlayType.circle,
        onCropped: (croppedBytes) async {
          // Get temp directory
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(
            '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
          );

          // Save bytes to temp file
          await tempFile.writeAsBytes(croppedBytes);

          if (!mounted) return;
          setState(() {
            _croppedFile = tempFile;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Circle Crop Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Show profile image if exists, else default icon
            CircleAvatar(
              radius: 100,
              backgroundColor: Colors.grey[300],
              backgroundImage: _croppedFile != null
                  ? FileImage(_croppedFile!)
                  : null,
              child: _croppedFile == null
                  ? const Icon(Icons.person, size: 100, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick and Crop Image'),
            ),
          ],
        ),
      ),
    );
  }
}
