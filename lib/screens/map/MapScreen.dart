import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:dart_geohash/dart_geohash.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  var logger = Logger();
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(0, 0);
  String _location = "Search Location";
  final String _googleApiKey =
      "AIzaSyACH5ogq7IGPRC_lPZzn7vA42hD-xJuGhk"; // Replace with your actual API key
  Set<Marker> _markers = {};
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenForMarkerUpdates();
    // _startLocationUpdateTask();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdateTask() {
    const locationUpdateInterval =
        Duration(seconds: 10); // Adjust the interval as needed
    _locationUpdateTimer =
        Timer.periodic(locationUpdateInterval, (timer) async {
      Position position = await _getCurrentLocation();
      _updateCurrentLocation(LatLng(position.latitude, position.longitude));
      _checkForNearbyMarkers();
    });
  }

  void _listenForMarkerUpdates() {
    FirebaseFirestore.instance.collection('potholes').snapshots().listen(
      (snapshot) {
        var newMarkers = <Marker>{};
        for (var document in snapshot.docs) {
          var data = document.data();
          LatLng position = LatLng(data['latitude'], data['longitude']);
          newMarkers.add(Marker(
            markerId: MarkerId(document.id),
            position: position,
            infoWindow: const InfoWindow(title: 'Pothole', snippet: 'Detected'),
          ));
        }
        _updateMarkers(newMarkers);
      },
    );
  }

  void _checkForNearbyMarkers() {
    if (isMarkerNearbyWithGeohash(_currentLocation, 200)) {
      logger.i('Found a marker');
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
      if (userGeohash.startsWith(markerGeohash)) {
        return true; // A marker is found within the radius
      }
    }
    return false; // No markers found within the radius
  }

  Future<Position> _getCurrentLocation() async {
    try {
      bool locationPermissionGranted = await _checkLocationPermission();
      if (locationPermissionGranted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        _updateCurrentLocation(LatLng(position.latitude, position.longitude));
        return position;
      } else {
        // Handle scenario when location permission is not granted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission not granted')),
        );
      }
    } catch (e) {
      // Handle exceptions
      print('Error getting current location: $e');
    }
    return Position(
        longitude: 19,
        latitude: 72,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0);
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildGoogleMap(),
          _buildSearchBar(),
          _buildLocationButton(),
        ],
      ),
    );
  }

  GoogleMap _buildGoogleMap() {
    return GoogleMap(
      zoomGesturesEnabled: true,
      trafficEnabled: true,
      initialCameraPosition: CameraPosition(
        target: _currentLocation,
        zoom: 18.0,
      ),
      markers: _markers,
      mapType: MapType.normal,
      onMapCreated: (controller) => _mapController = controller,
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
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
    );
  }

  Widget _buildLocationButton() {
    return Positioned(
      top: MediaQuery.of(context).size.height / 1.35,
      right: 5,
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.9),
        ),
        icon: const Icon(
          Icons.location_on,
          color: Colors.black,
        ),
        onPressed: () async {
          var position = await _getCurrentLocation();
          await _markCurrentLocation(position);
        },
      ),
    );
  }

  void _updateMarkers(Set<Marker> newMarkers) {
    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _updateCurrentLocation(LatLng newLocation) {
    if (mounted) {
      setState(() {
        _currentLocation = newLocation;
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newLocation, zoom: 18.0),
          ),
        );
      });
    }
  }

  Future<void> _searchLocation() async {
    try {
      final places = GoogleMapsPlaces(apiKey: _googleApiKey);

      Prediction? prediction = await PlacesAutocomplete.show(
        context: context,
        apiKey: _googleApiKey,
        mode: Mode.overlay,
        resultTextStyle: const TextStyle(fontSize: 14),
        cursorColor: Colors.white,
        overlayBorderRadius: BorderRadius.circular(12),
        hint: 'Search Location',
        types: [],
        strictbounds: false,
        components: [Component(Component.country, 'us')],
      );

      if (prediction != null) {
        PlacesDetailsResponse detail =
            await places.getDetailsByPlaceId(prediction.placeId!);
        final geometry = detail.result.geometry!;
        final lat = geometry.location.lat;
        final lng = geometry.location.lng;
        var newLatLng = LatLng(lat, lng);

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: newLatLng, zoom: 18),
          ),
        );

        Marker searchedLocation = Marker(
          markerId: MarkerId(prediction.placeId!),
          infoWindow: InfoWindow(title: prediction.description?.split(',')[0]),
          position: newLatLng,
        );

        setState(() {
          _markers.clear();
          _markers.add(searchedLocation);
          _location = prediction.description.toString();
        });
      }
    } catch (e) {
      logger.e('Error searching location',
          error: e, stackTrace: StackTrace.current);
    }
  }

  Future<void> _markCurrentLocation(Position position) async {
    Marker myPosition = Marker(
      markerId: const MarkerId('myLocation'),
      infoWindow: const InfoWindow(title: 'Current Location'),
      position: LatLng(position.latitude, position.longitude),
    );

    setState(() {
      _markers.add(myPosition);
    });
  }
}
