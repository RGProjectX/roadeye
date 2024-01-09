import 'package:get/get.dart';
import 'package:logger/logger.dart';

class LocationController extends GetxController {
  var logger = Logger();
  var _currentSpeed = 0.0.obs;
  var _currentRadius = 50.0.obs; // Initial dynamic radius

  double get currentSpeed => _currentSpeed.value;
  double get currentRadius => _currentRadius.value;

  void updateSpeed(double newSpeed) {
    _currentSpeed.value = newSpeed * 3.6;
    _currentRadius.value = calculateDynamicRadius(newSpeed);
  }

  double calculateDynamicRadius(double speed) {
    // Implement your logic here
    double baseRadius = 50; // Base radius in meters
    double speedFactor = 1.5; // Factor to increase radius based on speed
    double userSpeedKilometersPerHour = speed * 3.6;
    return baseRadius +
        (speedFactor * userSpeedKilometersPerHour); // Example calculation
  }
}
