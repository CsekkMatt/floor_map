import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:latlng/latlng.dart';
import 'package:map/map.dart';
import 'package:pocmap/imageservice.dart';

class CustomTilePage extends StatefulWidget {
  const CustomTilePage({Key? key}) : super(key: key);

  @override
  _CustomTilePageState createState() => _CustomTilePageState();
}

class _CustomTilePageState extends State<CustomTilePage> {
  Image mainImage = Image.asset("assets/images/homeplan1.png");
  List<List<Image>> firstLayer = [];
  List<List<Image>> secondLayer = [];
  List<List<Image>> thirdLayer = [];
  List<List<Image>> fourthLayer = [];
  List<List<Image>> fifthLayer = [];
  HashMap<int, List<List<Image>>> cache = HashMap<int, List<List<Image>>>();

  //replace this with a map<gridNumber;value(would be the list)>

  final markers = [
    LatLng(35.674, 51.41),
    LatLng(35.676, 51.41),
  ];

  final controller = MapController(
    zoom: 0,
    location: LatLng(35.68, 51.41),
  );

  void _gotoDefault() {
    controller.center = LatLng(35.68, 51.41);
    setState(() {});
  }

  void _onDoubleTap() {
    controller.zoom += 0.5;
    setState(() {});
  }

  Offset? _dragStart;
  double _scaleStart = 1.0;

  void _onScaleStart(ScaleStartDetails details) {
    _dragStart = details.focalPoint;
    _scaleStart = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final scaleDiff = details.scale - _scaleStart;
    _scaleStart = details.scale;

    if (scaleDiff > 0) {
      controller.zoom += 0.02;
      setState(() {});
    } else if (scaleDiff < 0) {
      controller.zoom -= 0.02;
      setState(() {});
    } else {
      final now = details.focalPoint;
      final diff = now - _dragStart!;
      _dragStart = now;
      controller.drag(diff.dx, diff.dy);
      setState(() {});
    }
  }

  @override
  void initState() {
    print('initState');
    super.initState();
    readtilesAndSaveImage();
  }

  Future<void> readtilesAndSaveImage() async {
    List<int> imageList = await ImageService().readImage();
    for (int zoom = 1; zoom <= 10; zoom++) {
      int grids = pow(2, zoom).floor();
      cache.putIfAbsent(zoom, () => calculateImageMatrix(grids, imageList));
      print('zoomLvl: $zoom ${DateTime.now()}');
    }
    print('cache size: ${cache.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<int>>(
        future: ImageService().readImage(),
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          print(snapshot.hasData);
          if (snapshot.hasData) {
            return MapLayoutBuilder(
              controller: controller,
              builder: (context, transformer) {
                final markerPositions =
                    markers.map(transformer.fromLatLngToXYCoords).toList();

                final markerWidgets = markerPositions.map(
                  (pos) => _buildMarkerWidget(pos, Colors.red),
                );
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: _onDoubleTap,
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        final delta = event.scrollDelta;
                        controller.zoom -= delta.dy / 1000.0;
                        setState(() {});
                      }
                    },
                    child: Stack(
                      children: [
                        Center(
                          child: Map(
                            controller: controller,
                            builder: (context, x, y, z) {
                              return FittedBox(
                                fit: BoxFit.fill,
                                child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        border: Border.all(width: 0),
                                      ),
                                      child: _imageBasedOnMatrix(
                                          x, y, z, snapshot.data!, controller)),
                                ),
                              );
                              //fit: BoxFit.fill,
                              //   );
                            },
                          ),
                        ),
                        ...markerWidgets,
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Text("Loading");
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _gotoDefault,
        tooltip: 'My Location',
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildMarkerWidget(Offset pos, Color color) {
    return Positioned(
      left: pos.dx - 16,
      top: pos.dy - 16,
      width: 24,
      height: 24,
      child: Icon(Icons.location_on, color: color),
    );
  }

  Image? _imageBasedOnMatrix(
      int x, int y, int z, List<int> image, MapController controller) {
    int zoom = pow(2, controller.zoom).floor();
    z = zoom;
    print('live zoom: ${controller.zoom}');
    print('x ${x} y ${y} z ${z} ssss');
    if (z == 1) {
      return mainImage;
    }
    if (z == 2) {
      if (firstLayer.isNotEmpty) {
        print('cacheApplied');
        return firstLayer[x][y];
      }
    }
    if (z == 3) {
      if (secondLayer.isNotEmpty) {
        print('cacheApplied');
        return secondLayer[x][y];
      }
    }
    if (z == 4) {
      if (thirdLayer.isNotEmpty) {
        print('cacheApplied');
        return thirdLayer[x][y];
      }
    }
    if (z == 5) {
      if (fourthLayer.isNotEmpty) {
        print('cacheApplied');
        return fourthLayer[x][y];
      }
    }
    if (z == 6) {
      if (fifthLayer.isNotEmpty) {
        print('cacheApplied');
        return fifthLayer[x][y];
      }
    }
    List<List<Image>> imageMatrix = _imageBasedOnZoomLevel(z, image);
    //cache
    if (z == 2) {
      firstLayer = imageMatrix;
    }
    if (z == 3) {
      secondLayer = imageMatrix;
    }
    if (z == 4) {
      thirdLayer = imageMatrix;
    }
    if (z == 5) {
      fourthLayer = imageMatrix;
    }
    if (z == 6) {
      fifthLayer = imageMatrix;
    }
    print('${imageMatrix[x][y]}');
    return imageMatrix[x][y];
  }

  List<List<Image>> _imageBasedOnZoomLevel(int layer, List<int> tiles) {
    // int numberOfImages = _numberOfImagesBasedOnZoomLevel(layer); not needed anymore ?
    List<List<Image>> images = calculateImageMatrix(layer, tiles);
    print('${images.length}');
    return images;
  }

  int _numberOfImagesBasedOnZoomLevel(int zoomLevel) {
    switch (zoomLevel) {
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 3;
      case 4:
        return 4;
      case 5:
        return 5;
      case 6:
        return 6;
    }
    return 0;
  }

  List<List<Image>> calculateImageMatrix(int layer, List<int> tiles) {
    final placeHolderImage = Base64Codec().decode(
        "R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7");
    imglib.Image? image = imglib.decodeImage(tiles);
    int x = 0, y = 0;
    int xlength = (image!.width / layer).round();
    int ylength = (image.height / layer).round();
    int row = layer;
    int col = layer;
    List<List<imglib.Image>> imageMatrix = List.generate(
      row + 1,
      (index) => List.filled(
          col + 1, imglib.copyCrop(image, x, y, xlength, ylength),
          growable: false),
    );
    for (int i = 0; i < layer; i++) {
      for (int j = 0; j < layer; j++) {
        imageMatrix[i][j] = imglib.copyCrop(image, x, y, xlength, ylength);
        y += ylength;
      }
      y = 0;
      x += xlength;
    }
    print('1st ${DateTime.now()}');
    List<List<Image>> resultMatrix = List.generate(
      row + 1,
      (index) =>
          List.filled(col + 1, Image.memory(placeHolderImage,height: 1), growable: false),
    );
    for (int i = 0; i < layer; i++) {
      for (int j = 0; j < layer; j++) {
        resultMatrix[i][j] = Image.memory(
            Uint8List.fromList(imglib.encodeJpg(imageMatrix[i][j])));
      }
    }
    print('2nd ${DateTime.now()}');
    return resultMatrix;
  }
}
