import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:edge_detection/edge_detection.dart';
import 'package:edge_detection/model/plugin_params.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String>? _imagePaths;

  @override
  void initState() {
    super.initState();
  }

  Future<void> getImageFromCamera() async {
    bool isCameraGranted = await Permission.camera.request().isGranted;
    if (!isCameraGranted) {
      isCameraGranted = await Permission.camera.request() == PermissionStatus.granted;
    }

    if (!isCameraGranted) {
      // Have not permission to camera
      return;
    }

    // Generate filepath for saving
    String imagePath = join(
      (await getApplicationSupportDirectory()).path,
      "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg",
    );

    bool success = false;

    try {
      //Make sure to await the call to detectEdge.
      success = await EdgeDetection.detectEdge(
        imagePath,
        canUseGallery: true,
        androidScanTitle: 'Scanning', // use custom localizations for android
        androidCropTitle: 'Crop',
        androidCropBlackWhiteTitle: 'Black White',
        androidCropReset: 'Reset',
      );
      print("success: $success");
    } catch (e) {
      print(e);
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
  }

  Future<void> getImageFromGallery() async {
    try {
      //Make sure to await the call to detectEdgeFromGallery.
      final images = await EdgeDetection.detectEdgeFromGallery(PluginParams());
      if (!mounted) return;

      setState(() {
        _imagePaths = images.cast<String>();
        log(' Cropped image paths: $_imagePaths');
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: ElevatedButton(onPressed: getImageFromCamera, child: Text('Scan')),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(onPressed: getImageFromGallery, child: Text('Upload')),
              ),
              SizedBox(height: 20),
              Text('Cropped image path:'),
              Padding(
                padding: const EdgeInsets.only(top: 0, left: 0, right: 0),
                child: Text(_imagePaths?.join() ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
              ),
              ...?_imagePaths
                  ?.map((path) => Padding(padding: const EdgeInsets.all(8.0), child: Image.file(File(path))))
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }
}
