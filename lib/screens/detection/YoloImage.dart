import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';

class YoloImageV8 extends StatefulWidget {
  final FlutterVision vision;

  const YoloImageV8({Key? key, required this.vision}) : super(key: key);

  @override
  State<YoloImageV8> createState() => _YoloImageV8State();
}

class _YoloImageV8State extends State<YoloImageV8> {
  late List<Map<String, dynamic>> yoloResults;
  File? imageFile;
  int imageHeight = 1;
  int imageWidth = 1;
  bool isLoaded = false;
  String _currentAddress = '';
  int totalPotholes = 0;

  @override
  void initState() {
    super.initState();
    loadYoloModel().then((value) {
      setState(() {
        yoloResults = [];
        isLoaded = true;
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return !isLoaded
        ? const Scaffold(
            body: Center(
              child: Text('Model Not Loaded. Please Wait'),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
            ),
            extendBodyBehindAppBar: true,
            body: Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.5),
                    Colors.green.withOpacity(0.5),
                  ],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageFile != null
                        ? Image.file(imageFile!)
                        : const SizedBox(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: pickImage,
                              child: const Text(
                                "Pick an image",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: yoloOnImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                "Detect",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                textAlign: TextAlign.center,
                              ),
                            )
                          ],
                        ),
                        _currentAddress.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 50, horizontal: 20),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: GoogleFonts.raleway(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    children: <TextSpan>[
                                      const TextSpan(
                                        text: 'Location: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: '$_currentAddress\n\n'),
                                      const TextSpan(
                                        text: 'Total Potholes Detected: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: '$totalPotholes'),
                                    ],
                                  ),
                                ),
                              )
                            : const Padding(
                                padding: EdgeInsets.symmetric(vertical: 50),
                                child: Text(
                                  'Location: N/A \n\nTotal Potholes Detected: 0',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ))
                      ],
                    ),
                    ...displayBoxesAroundRecognizedObjects(size),
                  ],
                ),
              ),
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

  Future<void> pickImage() async {
    yoloResults.clear();
    _currentAddress = '';
    totalPotholes = 0;
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        imageFile = File(photo.path);
      });
    }
  }

  yoloOnImage() async {
    yoloResults.clear();
    Uint8List byte = await imageFile!.readAsBytes();
    final image = await decodeImageFromList(byte);
    imageHeight = image.height;
    imageWidth = image.width;
    final result = await widget.vision.yoloOnImage(
      bytesList: byte,
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.8,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
        totalPotholes = yoloResults.length;
      });
      _getCurrentLocation();
    } else {
      setState(() {
        _currentAddress = "No Pothole Detected";
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    showDialog(
        context: context,
        builder: (context) => const Center(
                child: CircularProgressIndicator(
              backgroundColor: Colors.greenAccent,
              color: Colors.white54,
            )));

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
          // Add geopoint entry to firebase, collection named : potholes

          final Placemark place = placemarks[0];
          final String address =
              '${place.street}, ${place.subLocality}, ${place.name}, ${place.administrativeArea}, ${place.postalCode}';
          print(address);
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
        setState(() {
          _currentAddress = "Error fetching location";
        });
      }
    }
    Navigator.of(context).pop();
  }

  Future<void> addPotholeIfNotExists(Position position, String address) async {
    try {
      // Convert GeoPoint to LatLng and calculate geohash
      GeoHasher geoHasher = GeoHasher();
      final geoHash =
          geoHasher.encode(position.latitude, position.longitude, precision: 4);

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
        print('A similar GeoPoint already exists');
        // Optionally update existing document or take other actions
      }
    } catch (e) {
      print('Error accessing Firestore: ${e.toString()}');
    }
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (imageWidth);
    double imgRatio = imageWidth / imageHeight;
    double newWidth = imageWidth * factorX;
    double newHeight = newWidth / imgRatio;
    double factorY = newHeight / (imageHeight);
    double pady = (screen.height - newHeight) / 2.25;
    Color colorPick = const Color(0xff0fff78).withOpacity(0.7);
    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY + pady - 30,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY + 10,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(
              color: Colors.redAccent,
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
