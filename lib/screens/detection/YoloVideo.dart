import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';

class YoloVideo extends StatefulWidget {
  final FlutterVision vision;

  const YoloVideo({Key? key, required this.vision}) : super(key: key);

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  var logger = Logger();
  late List<CameraDescription> cameras;
  late CameraController controller;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  String _currentAddress = '';
  bool isDetecting = false;
  int totalPotholes = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.ultraHigh);
    controller.initialize().then((value) {
      loadYoloModel().then((value) {
        setState(() {
          isLoaded = true;
          isDetecting = false;
          yoloResults = [];
        });
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    final GeolocatorPlatform geolocator = GeolocatorPlatform.instance;
    final LocationPermission permission = await geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      setState(() {
        _currentAddress = "Location permission denied";
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      Geolocator.openAppSettings();
      return;
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      try {
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks[0];
          final String address =
              '${place.street}, ${place.subLocality}, ${place.name}, ${place.administrativeArea}, ${place.postalCode}';
          logger.d(address);
          if (totalPotholes > 0) {
            addPotholeIfNotExists(position, address);
          }

          setState(() {
            _currentAddress = address;
          });
        } else {
          setState(() {
            _currentAddress = "Address not found";
          });
        }
      } catch (e) {
        logger.e("Error in fetching location", error: e);
      }
    }
  }

  Future<void> addPotholeIfNotExists(Position position, String address) async {
    try {
      // Convert GeoPoint to LatLng and calculate geohash
      GeoHasher geoHasher = GeoHasher();
      final geoHash =
          geoHasher.encode(position.latitude, position.longitude, precision: 7);

      // Reference to Firestore collection
      CollectionReference potholes =
          FirebaseFirestore.instance.collection('potholes');

      // Query for similar GeoPoints
      QuerySnapshot querySnapshot =
          await potholes.where('geohash', isEqualTo: geoHash).get();

      // Check if similar GeoPoints exist
      if (querySnapshot.docs.isEmpty) {
        // No similar GeoPoint, add new one
        potholes.add({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'geohash': geoHash,
          'address': address,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        logger.d('A similar GeoPoint already exists');
        // Optionally update existing document or take other actions
      }
    } catch (e) {
      logger.d('Error accessing Firestore: ${e.toString()}');
    }
  }

  @override
  void dispose() async {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(
              controller,
            ),
          ),
          ...displayBoxesAroundRecognizedObjects(size),
          Positioned(
            bottom: 75,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 5,
                      color: Colors.white,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: isDetecting
                      ? IconButton(
                          onPressed: () async {
                            stopDetection();
                          },
                          icon: const Icon(
                            Icons.stop,
                            color: Colors.red,
                          ),
                          iconSize: 50,
                        )
                      : IconButton(
                          onPressed: () async {
                            await startDetection();
                          },
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                          iconSize: 50,
                        ),
                ),
                SizedBox(height: 10),
                Text(_currentAddress)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadYoloModel() async {
    await widget.vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/yolo.tflite',
      modelVersion: "yolov8",
      numThreads: 2,
      useGpu: true,
    );
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await widget.vision.yoloOnFrame(
      bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      iouThreshold: 0.2,
      confThreshold: 0.2,
      classThreshold: 0.2,
    );
    if (result.isNotEmpty) {
      if (mounted) {
        setState(() {
          yoloResults = result;
          totalPotholes = yoloResults.length;
        });
      }

      if (totalPotholes > 0) {
        _getCurrentLocation();
      }
    }
    logger.i(
        "Address :$_currentAddress - Total Potholes ${totalPotholes.toString()}");
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });
    if (controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        yoloOnFrame(image);
      }
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);
    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(
              color: Colors.pink,
              width: 2.0,
            ),
          ),
          child: Text(
            "${result['tag']}",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
