import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    initCamera();
    initTFile();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cameraController.dispose();
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  //late CameraImage cameraImage;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;

  var x = 0.0, y = 0.0, w = 0.0, h = 0.0;
  var label = "";

  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(cameras[0], ResolutionPreset.max,
          imageFormatGroup: ImageFormatGroup.jpeg);
      await cameraController.initialize().then((value) {
        // cameraCount++;
        // if (cameraCount % 10 == 0) {
        // cameraCount = 0;
        cameraController.startImageStream((image) {
          if (cameraCount % 10 == 0) {
            cameraCount++;
            cameraCount = 0;
            objectDetector(image);
          }
          update();
        });
      }
          //cameraController.startImageStream((image) {
          // objectDetector(image);
          //}
          );
      // update();

      isCameraInitialized(true);
      update();
    } else {
      print("Permission Denied");
    }
  }

  initTFile() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assts/labels.txt",
      isAsset: true,
      numThreads: 1,
      useGpuDelegate: false,
    );
  }

  objectDetector(CameraImage image) async {
    var detector = await Tflite.runPoseNetOnFrame(
      bytesList: image.planes.map((e) {
        return e.bytes;
      }).toList(),
      asynch: true,
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 1,
      rotation: 90,
      threshold: 0.4,
    );

    if (detector != null && detector.isNotEmpty) {
      var outDetectedObkect = detector.first;
      if (outDetectedObkect['confidenceInClass'] * 100 > 45) {
        label = detector.first['detectedClass'].toString();
        h = outDetectedObkect['react']['h'];
        w = outDetectedObkect['react']['w'];
        x = outDetectedObkect['react']['x'];
        y = outDetectedObkect['react']['y'];
      }
      update();
    }
  }
}
