# Profile Image Cropper

**Effortlessly crop profile images in your Flutter applications with this highly customizable and easy-to-use widget.**

[![pub version](https://img.shields.io/pub/v/profile_image_cropper.svg)](https://pub.dev/packages/profile_image_cropper)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Whether you're building a social media app, a professional networking platform, or any application that requires users to have a profile picture, the `profile_image_cropper` is the perfect tool for the job. With a rich set of features and a simple API, you can integrate a powerful image cropping experience in minutes.

<br/>

## Features

- **Customizable Overlay**: Choose from various overlay shapes like `circle`, `rectangle`, and `grid`.
- **Zoom and Pan**: Effortlessly zoom and pan the image for the perfect crop.
- **Rotation**: Rotate the image in 90-degree increments.
- **Aspect Ratio**: Enforce a specific aspect ratio for the cropped image.
- **Custom Styling**: Customize the background color, overlay color, and grid line thickness.
- **Gesture Callbacks**: Get notified about scale gestures with `onScaleStart`, `onScaleUpdate`, and `onScaleEnd`.
- **Error Handling**: An `onError` callback to handle exceptions during image loading or cropping.
- **Static Crop Method**: A convenient static method `ImageCropper.crop()` to perform the crop operation.


### 🖼️ Demo
<table>
  <tr>
    <th>Video</th>
    <th>Circle Crop</th>
    <th>Rectangle Crop</th>
  </tr>
  <tr>
    <td align="center">
      <img src="https://i.imgur.com/4YNQVWx.gif" width="260" />
    </td>
    <td align="center">
      <img src="https://i.imgur.com/jU0IUC7.png" width="260" />
    </td>
    <td align="center">
      <img src="https://i.imgur.com/n297cl4.png" width="260" />
    </td>
  </tr>
</table>

## Getting Started

To use this package, add `profile_image_cropper` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  profile_image_cropper: ^latest
```

Then, run `flutter pub get` to install the package.

## Usage

Here's a simple example of how to use the `ProfileImageCropper` widget with an image from the network:

```dart
import 'package:flutter/material.dart';
import 'package:profile_image_cropper/profile_image_cropper.dart';

class MyCropperPage extends StatelessWidget {
  final imageCropperKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Your Image'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              final croppedBytes = await ProfileImageCropper.crop(
                imageCropperKey: imageCropperKey,
              );

              if (croppedBytes != null) {
                // Handle the cropped image bytes
              }
            },
          ),
        ],
      ),
      body: ProfileImageCropper(
        imageCropperKey: imageCropperKey,
        image: Image.network('https://picsum.photos/seed/picsum/200/300'),
        aspectRatio: 1.0,
        overlayType: OverlayType.circle,
      ),
    );
  }
}
```

### Cropping an Image from Assets

To crop an image from your app's assets, first ensure you have added the image to your `pubspec.yaml` file:

```yaml
flutter:
  assets:
    - assets/profile.jpg
```

Then, you can use the `Image.asset` constructor:

```dart
ProfileImageCropper(
  imageCropperKey: imageCropperKey,
  image: Image.asset('assets/profile.jpg'),
  aspectRatio: 1.0,
  overlayType: OverlayType.circle,
)
```

### Cropping an Image from Memory

To crop an image that you have in memory as a `Uint8List`, you can use the `Image.memory` constructor:

```dart
import 'dart:typed_data';

// Assuming you have your image bytes in a Uint8List
Uint8List imageBytes = ...;

ProfileImageCropper(
  imageCropperKey: imageCropperKey,
  image: Image.memory(imageBytes),
  aspectRatio: 1.0,
  overlayType: OverlayType.circle,
)
```

### Displaying the Cropped Image

After you have cropped the image, you get the result as a `Uint8List`. You can then display this cropped image using the `Image.memory` constructor. Here is a complete example of a stateful widget that allows you to crop an image and display the result.

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:profile_image_cropper/profile_image_cropper.dart';

class CropperAndResultPage extends StatefulWidget {
  const CropperAndResultPage({super.key});

  @override
  State<CropperAndResultPage> createState() => _CropperAndResultPageState();
}

class _CropperAndResultPageState extends State<CropperAndResultPage> {
  final imageCropperKey = GlobalKey();
  Uint8List? _croppedBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop and Display'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              final croppedBytes = await ProfileImageCropper.crop(
                imageCropperKey: imageCropperKey,
              );

              if (croppedBytes != null) {
                setState(() {
                  _croppedBytes = croppedBytes;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            width: 500,
            height: 500,
            child: ProfileImageCropper(
              imageCropperKey: imageCropperKey,
              image: Image.network('https://picsum.photos/seed/picsum/200/300'),
              aspectRatio: 1.0,
              overlayType: OverlayType.circle,
            ),
          ),
          if (_croppedBytes != null)
            Expanded(
              child: Center(
                child: Image.memory(_croppedBytes!),
              ),
            ),
        ],
      ),
    );
  }
}
```

## Customization

You can customize the `ProfileImageCropper` widget with the following parameters:

| Parameter                  | Type                                | Description                                                                                             | Default Value                  |
| -------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------ |
| `imageCropperKey`          | `GlobalKey`                         | A key to reference the cropper when calling the `crop` function.                                        | **Required**                   |
| `image`                    | `Image`                             | The image to be cropped.                                                                                | **Required**                   |
| `backgroundColor`          | `Color`                             | The background color of the cropper widget.                                                             | `Color(0xFFCECECE)`            |
| `overlayColor`             | `Color`                             | The color of the cropper's overlay.                                                                    | `Colors.black38`               |
| `overlayType`              | `OverlayType`                       | The type of semi-transparent overlay (`circle`, `rectangle`, `grid`, `none`).                           | `OverlayType.none`             |
| `maxZoomScale`             | `double`                            | The maximum scale the user can zoom.                                                                    | `2.5`                          |
| `minZoomScale`             | `double`                            | The minimum scale the user can zoom.                                                                    | `0.1`                          |
| `aspectRatio`              | `double`                            | The aspect ratio to crop the image to.                                                                  | `1.0` (square)                 |
| `rotationTurns`            | `int`                               | The number of clockwise quarter turns the image should be rotated.                                      | `0`                            |
| `gridLineThickness`        | `double`                            | The thickness of the grid lines when using grid overlay types.                                          | `2.0`                          |
| `onScaleStart`             | `GestureScaleStartCallback?`        | Callback fired when the user begins a scale gesture.                                                    | `null`                         |
| `onScaleUpdate`            | `GestureScaleUpdateCallback?`       | Callback fired when the user updates a scale gesture.                                                   | `null`                         |
| `onScaleEnd`               | `GestureScaleEndCallback?`          | Callback fired when the user ends a scale gesture.                                                      | `null`                         |
| `onError`                  | `void Function(CropperException)?`  | Callback fired when an error occurs during image processing.                                            | `null`                         |
| `enableHapticFeedback`     | `bool`                              | Whether to enable haptic feedback on interactions.                                                      | `false`                        |
| `scalingAnimationDuration` | `Duration`                          | The duration of the scale animation when setting the initial scale.                                     | `Duration(milliseconds: 300)`  |

## A Note on 'Pure Dart' Usage

The `profile_image_cropper` is a Flutter widget, and it is designed to be used within a Flutter application. It relies on the Flutter framework for rendering the UI, handling user gestures, and processing images. Therefore, it is not possible to use this widget in a "pure Dart" environment (e.g., a command-line application) without the Flutter engine.

The simplest and most "low-powered" way to use this package is to follow the basic usage examples provided above, which demonstrate how to integrate the widget into your Flutter app with minimal configuration.

## Additional Information

- **Reporting Issues**: If you encounter any issues or have suggestions for improvement, please file an issue on the [GitHub repository](https://github.com/ArmanKT/profile_image_cropper/issues).
- **Contributing**: Contributions are welcome! If you'd like to contribute to this project, please fork the repository and submit a pull request.
