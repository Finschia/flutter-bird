import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../model/skin.dart';

class Bird extends StatelessWidget {
  const Bird({
    Key? key,
    this.skin,
  }) : super(key: key);

  final Skin? skin;

  bool get isLoading => skin != null && skin!.imageLocation == null;

  String get name => skin?.tokenId != null ? ('#${skin!.tokenId}') : '';

  @override
  Widget build(BuildContext context) {
    if (skin == null) {
      return Image.asset('images/flappy_bird.png');
    }

    if (skin?.imageLocation == null) {
      return _buildLoadingIndicator(context, 0.3);
    }

    try {
      final imageDataUrl = _extractImageDataUrl(skin!.imageLocation!);
      return Image.memory(
        _dataUrlToBytes(imageDataUrl),
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return _buildErrorWidget(context);
        },
      );
    } catch (e) {
      print('Error processing image data: $e');
      return _buildErrorWidget(context);
    }
  }

  Uint8List _dataUrlToBytes(String dataUrl) {
    final base64Str = dataUrl.split(',').last;
    return base64Decode(base64Str);
  }

  String _extractImageDataUrl(String tokenUri) {
    try {
      final jsonStr = tokenUri.replaceFirst('data:application/json,', '');
      print('jsonStr:${jsonStr}');
      String decodedStr = Uri.decodeFull(jsonStr);
      print('decodedStr:${decodedStr}');
      Map<String, dynamic> jsonData = jsonDecode(decodedStr);
      print('jsonData:${jsonData}');
      if (jsonData.containsKey('image')) {
        return jsonData['image'] as String;
      } else {
        throw FormatException('Invalid JSON structure or missing image field');
      }
    } catch (e) {
      print('Error extracting image data URL: $e');
      print("tokenUri: ${tokenUri}, ${e}");
      rethrow;
    }
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(Icons.error, color: Colors.red),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context, double? value) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
            value: value,
          ),
          Text(
            'loading from\nIPFS...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          )
        ],
      );
}
