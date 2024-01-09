import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:logger/logger.dart';
import 'package:roadeye/controller/LocationController.dart';
import 'package:roadeye/helper/constants.dart' as constant;
import 'package:dart_geohash/dart_geohash.dart';
import 'package:soundpool/soundpool.dart';

class LiveTracking extends StatefulWidget {
  const LiveTracking({super.key});

  @override
  State<LiveTracking> createState() => _LiveTrackingState();
}

class _LiveTrackingState extends State<LiveTracking> {
  Soundpool pool = Soundpool.fromOptions(
      options: SoundpoolOptions(streamType: StreamType.notification));

  int? soundId;
  int? streamId;

  var logger = Logger();
  final LocationController locationController = Get.put(LocationController());

  // ignore: non_constant_identifier_names
  final String GOOGLE_API_KEY = constant.GOOGLE_API_KEY;
  GeoHasher geoHasher = GeoHasher();
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;

  List<LatLng> polylineCoordinates = [];
  // ignore: prefer_final_fields
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  String _location = "Search Location";
  loc.LocationData? currentLocation;
  loc.LocationData? sourceLocation;
  LatLng? destinationLocation;
  loc.Location location = loc.Location();

  void getCurrentLocation() async {
    try {
      var locData = await location.getLocation();
      setState(() {
        currentLocation = locData;
      });
      // logger.d('Current location fetched: $currentLocation');

      if (currentLocation != null) {
        _updateCameraPosition(
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!));
      }

      GoogleMapController googleMapController = await _controller.future;

      location.onLocationChanged.listen((newLoc) {
        // logger.d('Location changed: $newLoc');
        double userSpeed = newLoc.speed ?? 0;
        locationController.updateSpeed(userSpeed);
        _updateCircle();
        _updateMarkersAndPolylines(googleMapController, newLoc, userSpeed);
      });
    } catch (e) {
      logger.e('Error getting location',
          error: e, stackTrace: StackTrace.current);
      // Handle the error, perhaps show an alert dialog
    }
  }

  void _updateMarkersAndPolylines(GoogleMapController googleMapController,
      loc.LocationData newLoc, double userSpeed) {
    currentLocation = newLoc;
    if (userSpeed > 10) {
      _checkForNearbyMarkers();
    }
    if (destinationLocation != null) {
      bool isClose = _isClose(
          LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          destinationLocation!);

      if (isClose) {
        _markers.removeWhere((marker) =>
            marker.markerId == const MarkerId('destination') ||
            marker.markerId == const MarkerId('sourceLocation'));
        polylineCoordinates.clear();
        setState(() {});
      }

      // logger.i(
      //     "Is Close: $isClose, Current Location: ${currentLocation!.latitude}, ${currentLocation!.longitude}, Destination Location: ${destinationLocation!.latitude}, ${destinationLocation!.longitude}");
    }
    _updateCameraPosition(
        LatLng(currentLocation!.latitude!, currentLocation!.longitude!));
  }

  void _updateCircle() {
    final double radius =
        locationController.currentRadius; // Radius from controller
    if (currentLocation != null) {
      _circles.clear();
      _circles.add(Circle(
        circleId: CircleId("userRadius"),
        center: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        radius: radius,
        fillColor:
            Colors.red.withOpacity(0.3), // Adjust color and opacity as needed
        strokeWidth: 1,
        strokeColor: Colors.red, // Adjust border color as needed
      ));
      setState(() {});
    }
  }

  void getPolyPoints(sourceLocation, destinationLocation) async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult polylineResult =
        await polylinePoints.getRouteBetweenCoordinates(
            GOOGLE_API_KEY,
            PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
            PointLatLng(
                destinationLocation.latitude, destinationLocation.longitude));

    if (polylineResult.points.isNotEmpty) {
      for (var point in polylineResult.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    // logger.i(polylineCoordinates);
    setState(() {});
  }

  Future<void> _searchLocation() async {
    try {
      Prediction? prediction = await _getLocationPrediction();
      if (prediction != null) {
        await _handleLocationSelected(prediction);
      }
    } catch (e) {
      logger.e('Error searching location',
          error: e, stackTrace: StackTrace.current);
    }
  }

  Future<Prediction?> _getLocationPrediction() async {
    return PlacesAutocomplete.show(
      context: context,
      apiKey: GOOGLE_API_KEY,
      mode: Mode.overlay,
      resultTextStyle: const TextStyle(fontSize: 14),
      cursorColor: Colors.white,
      overlayBorderRadius: BorderRadius.circular(12),
      hint: 'Search Location',
      types: [],
      strictbounds: false,
      components: [Component(Component.country, 'in')],
    );
  }

  Future<void> _handleLocationSelected(Prediction prediction) async {
    PlacesDetailsResponse detail =
        await GoogleMapsPlaces(apiKey: GOOGLE_API_KEY)
            .getDetailsByPlaceId(prediction.placeId!);

    LatLng newLatLng = LatLng(detail.result.geometry!.location.lat,
        detail.result.geometry!.location.lng);
    _updateCameraPosition(newLatLng);
    _addMarkers(newLatLng, prediction.description?.split(',')[0]);
    getPolyPoints(currentLocation, newLatLng);

    setState(() {
      destinationLocation = newLatLng;
      _location = prediction.description.toString();
    });
  }

  void _updateCameraPosition(LatLng newLatLng) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: newLatLng, zoom: 18),
      ),
    );
  }

  void _addMarkers(LatLng newLatLng, String? title) {
    Marker searchedLocation = Marker(
      markerId: const MarkerId("destination"),
      infoWindow: InfoWindow(title: title ?? 'Destination'),
      position: newLatLng,
    );

    _markers.add(
      Marker(
        markerId: const MarkerId("sourceLocation"),
        position:
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        infoWindow: const InfoWindow(title: "Source"),
      ),
    );

    _markers.add(searchedLocation);
  }

  bool _isClose(LatLng currentLocation, LatLng destinationLocation) {
    var currentLocGeohash =
        geoHasher.encode(currentLocation.longitude, currentLocation!.latitude!);
    var destinationLocGeohash = geoHasher.encode(
        destinationLocation.longitude, destinationLocation.latitude);
    logger.d("$currentLocGeohash, $destinationLocGeohash");
    return currentLocGeohash.substring(0, 8) ==
        destinationLocGeohash.substring(0, 8);
  }

  // FIREBASE IMPLEMENTATION FOR POTHOLES RETREIVAL

  void _listenForMarkerUpdates() {
    // logger.d("Listening to firebase");
    FirebaseFirestore.instance.collection('potholes').snapshots().listen(
      (snapshot) {
        var newMarkers = <Marker>{};
        for (var document in snapshot.docs) {
          var data = document.data();
          LatLng position = LatLng(data['latitude'], data['longitude']);
          newMarkers.add(Marker(
            markerId: const MarkerId("potholes"),
            position: position,
            infoWindow: const InfoWindow(title: 'Pothole', snippet: 'Detected'),
          ));
        }

        // CHECK IF THE WIDGET IS MOUNTED, IF IT IS THEN ADD THE MARKERS

        setState(() {
          // logger.d("Updated markers to latest potholes");
          _markers = newMarkers;
        });
      },
    );
  }

  // DETECT POTHOLES WITHIN 100 METRES OF USER'S LOCATION

  void _checkForNearbyMarkers() {
    final LocationController locationController = Get.find();
    double dynamicRadius = locationController.currentRadius;

    if (isMarkerNearbyWithGeohash(
        LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        dynamicRadius)) {
      logger.i('Found a marker');
      _playAlertSound();
    }
  }

  Future<void> _playAlertSound() async {
    if (soundId != null) {
      streamId = await pool.play(soundId!);
    }
  }

  bool isMarkerNearbyWithGeohash(LatLng userLocation, double radiusInMeters) {
    GeoHasher geoHasher = GeoHasher();
    String userGeohash =
        geoHasher.encode(userLocation.latitude, userLocation.longitude);
    int precision = 6;

    for (Marker marker in _markers) {
      String markerGeohash = geoHasher.encode(
          marker.position.latitude, marker.position.longitude,
          precision: precision);
      if (userGeohash.startsWith(markerGeohash) &&
          marker.markerId == MarkerId("potholes")) {
        return true; // A marker is found within the radius
      }
    }
    return false; // No markers found within the radius
  }

  // IF DETECTED PLAY AN ALERT
  Future<void> _loadSound() async {
    soundId =
        await rootBundle.load("assets/alert.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
  }

  @override
  void initState() {
    getCurrentLocation();
    _loadSound();
    _listenForMarkerUpdates();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return currentLocation == null
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              GoogleMap(
                trafficEnabled: true,
                compassEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                initialCameraPosition: CameraPosition(
                    target: LatLng(currentLocation!.latitude!,
                        currentLocation!.longitude!),
                    zoom: 13.5),
                polylines: {
                  Polyline(
                      polylineId: const PolylineId("route"),
                      points: polylineCoordinates,
                      color: Colors.blue[300]!,
                      width: 8)
                },
                markers: _markers,
                circles: _circles,
                onMapCreated: (mapController) {
                  _controller.complete(mapController);
                  _mapController = mapController;
                },
              ),
              Positioned(
                top: 30,
                child: InkWell(
                  onTap: () async {
                    await _searchLocation();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Card(
                      child: Container(
                        padding: const EdgeInsets.all(0),
                        width: MediaQuery.of(context).size.width - 40,
                        child: ListTile(
                          title: Text(
                            _location,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 18),
                          ),
                          trailing: const Icon(Icons.search),
                          dense: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 10,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() => Text(
                              'Speed: ${locationController.currentSpeed.toStringAsFixed(2)} km/h',
                              style: const TextStyle(fontSize: 16),
                            )),
                        Obx(() => Text(
                              'Radius: ${locationController.currentRadius.toStringAsFixed(2)} meters',
                              style: const TextStyle(fontSize: 16),
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
