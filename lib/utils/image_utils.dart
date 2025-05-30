import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<File?> pickAndCompressImage() async {
  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

  if (pickedFile == null) return null;

  final dir = await getTemporaryDirectory();
  final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

  final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
    pickedFile.path,
    targetPath,
    quality: 70,
  );

  return compressedXFile != null ? File(compressedXFile.path) : null;
}
