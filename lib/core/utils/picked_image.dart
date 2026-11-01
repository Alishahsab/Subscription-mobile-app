import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

const _maxSide = 1000.0;
const _quality = 72;

class PickedImage {
  const PickedImage(this.bytes, this.png);

  final Uint8List bytes;
  final bool png;
}

Future<PickedImage?> pickImageFromGallery() async {
  final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: _maxSide, maxHeight: _maxSide, imageQuality: _quality);
  if (file == null) return null;
  return PickedImage(await file.readAsBytes(), file.name.toLowerCase().endsWith('.png'));
}

class PickedPhoto {
  const PickedPhoto(this.bytes, this.extension);

  final Uint8List bytes;
  final String extension;
}

Future<PickedPhoto?> pickProfilePhoto(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source, preferredCameraDevice: CameraDevice.front);
  if (file == null) return null;
  return PickedPhoto(await file.readAsBytes(), file.name.split('.').last.toLowerCase());
}
