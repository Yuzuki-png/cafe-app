import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_app/widgets/custom_text_field.dart';
import '../utils/location_utils.dart';

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class Secrets {
  static String get API_KEY => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
}

class _MapViewState extends State<MapView> {
  final CameraPosition _initialLocation =
      CameraPosition(target: LatLng(0.0, 0.0));
  GoogleMapController? mapController;
  late Position _currentPosition;

  final TextEditingController startAddressController = TextEditingController();
  final TextEditingController destinationAddressController =
      TextEditingController();
  String _currentAddress = '';
  String? _placeDistance;

  Set<Marker> markers = {};
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// 現在地取得
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address = await LocationUtils.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        startAddressController.text = address;

        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 18.0,
            ),
          ),
        );
      });
    } catch (e) {
      print('現在地取得エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('現在地の取得に失敗しました。')),
      );
    }
  }

  /// 座標から距離を計算
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // π/180
    final c = cos;
    final a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin
  }

  /// ポリライン作成
  Future<void> _createPolylines(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Secrets.API_KEY,
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.walking,
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates.clear();
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        polylines[PolylineId('poly')] = Polyline(
          polylineId: PolylineId('poly'),
          color: Colors.blue,
          points: polylineCoordinates,
          width: 3,
        );
      });
    }
  }

  /// ルート計算
  Future<void> _calculateRoute() async {
    try {
      if (startAddressController.text.isEmpty ||
          destinationAddressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('出発地と目的地を入力してください')),
        );
        return;
      }

      // 出発地と目的地の座標を取得
      final startPlacemark =
          await locationFromAddress(startAddressController.text);
      final destinationPlacemark =
          await locationFromAddress(destinationAddressController.text);

      if (startPlacemark.isEmpty || destinationPlacemark.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('住所が無効です。正しい住所を入力してください。')),
        );
        return;
      }

      final start = startPlacemark.first;
      final destination = destinationPlacemark.first;

      final startLatitude = start.latitude;
      final startLongitude = start.longitude;
      final destinationLatitude = destination.latitude;
      final destinationLongitude = destination.longitude;

      // マーカー追加
      setState(() {
        markers = {
          Marker(
            markerId: MarkerId('start'),
            position: LatLng(startLatitude, startLongitude),
            infoWindow: InfoWindow(
              title: '出発地',
              snippet: startAddressController.text,
            ),
          ),
          Marker(
            markerId: MarkerId('destination'),
            position: LatLng(destinationLatitude, destinationLongitude),
            infoWindow: InfoWindow(
              title: '目的地',
              snippet: destinationAddressController.text,
            ),
          ),
        };
      });

      // ポリラインを作成
      await _createPolylines(
        startLatitude,
        startLongitude,
        destinationLatitude,
        destinationLongitude,
      );

      // 距離計算
      final distance = _calculateDistance(
        startLatitude,
        startLongitude,
        destinationLatitude,
        destinationLongitude,
      );

      setState(() {
        _placeDistance = distance.toStringAsFixed(2);
      });

      // カメラ位置を調整
      mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              min(startLatitude, destinationLatitude),
              min(startLongitude, destinationLongitude),
            ),
            northeast: LatLng(
              max(startLatitude, destinationLatitude),
              max(startLongitude, destinationLongitude),
            ),
          ),
          100.0,
        ),
      );
    } catch (e) {
      print('ルート計算エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ルート計算に失敗しました。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            markers: markers,
            initialCameraPosition: _initialLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            polylines: polylines.values.toSet(),
            onMapCreated: (controller) {
              mapController = controller;
              _getCurrentLocation();
            },
          ),
          Column(
            children: [
              Spacer(),
              CustomWidgets.buildSearchBox(
                context,
                startAddressController,
                destinationAddressController,
                onRouteSearch: _calculateRoute,
                distance: _placeDistance,
              ),
              if (mapController != null)
                CustomWidgets.buildZoomControls(mapController!),
              CustomWidgets.buildCurrentLocationButton(_getCurrentLocation),
            ],
          ),
        ],
      ),
    );
  }
}
