import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart';

class ImageService {
  Future<List<int>> readImage() async {
    ByteData byteData =
        await rootBundle.load(join("assets", "images", "homeplan1.png"));
    List<int> data = byteData.buffer.asUint8List();
    return data;
  }
}
