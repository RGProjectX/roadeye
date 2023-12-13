import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

class SearchScreen extends StatefulWidget {
  final String initialLocation;

  const SearchScreen({super.key, required this.initialLocation});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  GoogleMapController? mapController;
  TextEditingController searchController = TextEditingController();
  LatLng currentLocation = LatLng(0, 0);
  String location = '';
  final String googleApiKey = "AIzaSyACH5ogq7IGPRC_lPZzn7vA42hD-xJuGhk";
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _searchLocation(widget.initialLocation);
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String locationName) async {
    final places = GoogleMapsPlaces(apiKey: googleApiKey);

    PlacesAutocompleteResponse response = await places.autocomplete(
      locationName,
      components: [Component(Component.country, 'in')],
    );

    if (response.isOkay && response.predictions.isNotEmpty) {
      Prediction prediction = response.predictions.first;

      PlacesDetailsResponse detail =
          await places.getDetailsByPlaceId(prediction.placeId!);
      final geometry = detail.result.geometry!;
      final lat = geometry.location.lat;
      final lng = geometry.location.lng;
      var newLatLng = LatLng(lat, lng);

      mapController?.animateCamera(
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
        markers.clear();
        markers.add(searchedLocation);
        location = prediction.description.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            zoomGesturesEnabled: true,
            trafficEnabled: true,
            initialCameraPosition: CameraPosition(
              target: currentLocation,
              zoom: 18.0,
            ),
            markers: markers,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              setState(() {
                mapController = controller;
              });
            },
          ),
          Positioned(
            top: 30,
            child: InkWell(
              onTap: () async {
                await _searchLocation(searchController.text);
              },
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Card(
                  child: Container(
                    padding: const EdgeInsets.all(0),
                    width: MediaQuery.of(context).size.width - 40,
                    child: ListTile(
                      title: Text(
                        location,
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
        ],
      ),
    );
  }
}
