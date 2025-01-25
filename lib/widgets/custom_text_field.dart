import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomWidgets {
  /// 検索ボックス
  static Widget buildSearchBox(
    BuildContext context,
    TextEditingController startController,
    TextEditingController destinationController, {
    String? distance,
    required Future<void> Function() onRouteSearch,
  }) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ルート検索',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              _buildTextField(startController, '開始位置', '出発地点を入力してください'),
              SizedBox(height: 10),
              _buildTextField(destinationController, '目的位置', '目的地点を入力してください'),
              if (distance != null) ...[
                SizedBox(height: 10),
                Text(
                  '距離: $distance km',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ],
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (startController.text.isNotEmpty &&
                      destinationController.text.isNotEmpty) {
                    onRouteSearch();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('開始位置と目的位置を入力してください')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    'ルート検索',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// テキストフィールドのビルダー
  static Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// ズームコントロールボタン
  static Widget buildZoomControls(GoogleMapController mapController) {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildZoomButton(Icons.add,
                  () => mapController.animateCamera(CameraUpdate.zoomIn())),
              SizedBox(height: 10),
              _buildZoomButton(Icons.remove,
                  () => mapController.animateCamera(CameraUpdate.zoomOut())),
            ],
          ),
        ),
      ),
    );
  }

  /// ズームボタンのビルダー
  static Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return ClipOval(
      child: Material(
        color: Colors.blue.shade100,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: 50, height: 50, child: Icon(icon)),
        ),
      ),
    );
  }

  /// 現在地ボタン
  static Widget buildCurrentLocationButton(VoidCallback onTap) {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 10, top: 10),
          child: ClipOval(
            child: Material(
              color: Colors.blue.shade100,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Icon(Icons.my_location),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
