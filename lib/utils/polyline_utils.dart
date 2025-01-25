import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show cos, sqrt, asin;

class PolylineUtils {
  static String get apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static Future<List<LatLng>> getPolylineCoordinates(
    double startLat,
    double startLng,
    double destLat,
    double destLng,
  ) async {
    PolylinePoints polylinePoints = PolylinePoints();
    final result = await polylinePoints.getRouteBetweenCoordinates(
      apiKey,
      PointLatLng(startLat, startLng),
      PointLatLng(destLat, destLng),
      travelMode: TravelMode.walking,
    );

    if (result.points.isNotEmpty) {
      return result.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    }
    return [];
  }

  static double calculateTotalDistance(List<LatLng> polylineCoordinates) {
    double distance = 0.0;
    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      distance += _coordinateDistance(
        polylineCoordinates[i].latitude,
        polylineCoordinates[i].longitude,
        polylineCoordinates[i + 1].latitude,
        polylineCoordinates[i + 1].longitude,
      );
    }
    return distance;
  }

  static double _coordinateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;
    final c = cos;
    final a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
