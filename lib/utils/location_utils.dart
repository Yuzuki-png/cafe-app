import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'polyline_utils.dart';

class LocationUtils {
  static Future<Position> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("現在位置の取得に失敗しました: $e");
      throw Exception("現在位置の取得に失敗しました");
    }
  }

  static Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
      } else {
        throw Exception("住所が見つかりませんでした");
      }
    } catch (e) {
      print("住所の取得に失敗しました: $e");
      throw Exception("住所の取得に失敗しました");
    }
  }

  static Future<Map<String, dynamic>> getRouteDetails(
    String startAddress,
    String destinationAddress,
    String currentAddress,
    Position currentPosition,
  ) async {
    try {
      final startLocation = await _getLocationFromAddress(
        address: startAddress,
        currentAddress: currentAddress,
        currentPosition: currentPosition,
      );

      final destinationLocation =
          await _getLocationFromAddress(address: destinationAddress);

      final polylineCoordinates = await PolylineUtils.getPolylineCoordinates(
        startLocation.latitude,
        startLocation.longitude,
        destinationLocation.latitude,
        destinationLocation.longitude,
      );

      if (polylineCoordinates.isEmpty) {
        throw Exception("ポリラインデータが取得できません");
      }

      final markers = _createMarkers(startLocation, destinationLocation);

      final bounds = _calculateBounds(startLocation, destinationLocation);

      final distance =
          PolylineUtils.calculateTotalDistance(polylineCoordinates);

      return {
        'markers': markers,
        'bounds': bounds,
        'polylineCoordinates': polylineCoordinates,
        'distance': distance.toStringAsFixed(2),
      };
    } catch (e) {
      print("ルートの取得に失敗しました: $e");
      throw Exception("ルートの取得に失敗しました。");
    }
  }

  static Future<Location> _getLocationFromAddress({
    required String address,
    String? currentAddress,
    Position? currentPosition,
  }) async {
    try {
      if (currentAddress != null &&
          currentPosition != null &&
          address == currentAddress) {
        return Location(
          latitude: currentPosition.latitude,
          longitude: currentPosition.longitude,
          timestamp: DateTime.now(),
        );
      } else {
        final locations = await locationFromAddress(address);
        if (locations.isEmpty) {
          throw Exception("住所が無効です: $address");
        }
        return locations.first;
      }
    } catch (e) {
      print("住所の解析に失敗しました: $e");
      throw Exception("住所の解析に失敗しました: $address");
    }
  }

  static Set<Marker> _createMarkers(Location start, Location destination) {
    return {
      Marker(
        markerId: MarkerId('start'),
        position: LatLng(start.latitude, start.longitude),
        infoWindow: InfoWindow(title: '出発地'),
      ),
      Marker(
        markerId: MarkerId('destination'),
        position: LatLng(destination.latitude, destination.longitude),
        infoWindow: InfoWindow(title: '目的地'),
      ),
    };
  }

  static LatLngBounds _calculateBounds(Location start, Location destination) {
    return LatLngBounds(
      southwest: LatLng(
        start.latitude < destination.latitude
            ? start.latitude
            : destination.latitude,
        start.longitude < destination.longitude
            ? start.longitude
            : destination.longitude,
      ),
      northeast: LatLng(
        start.latitude > destination.latitude
            ? start.latitude
            : destination.latitude,
        start.longitude > destination.longitude
            ? start.longitude
            : destination.longitude,
      ),
    );
  }
}
