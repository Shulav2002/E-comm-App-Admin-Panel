import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class AddProductImagesController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  RxList<XFile> selectedImages = <XFile>[].obs;
  final RxList<String> arrImagesUrl = <String>[].obs;
  final FirebaseStorage storageRef = FirebaseStorage.instance;

  Future<void> showImagesPickerDialog() async {
    PermissionStatus storageStatus;
    PermissionStatus cameraStatus;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;

    if (androidDeviceInfo.version.sdkInt <= 32) {
      storageStatus = await Permission.storage.request();
      cameraStatus = await Permission.camera.request();
    } else {
      storageStatus = await Permission.photos.request();
      cameraStatus = await Permission.camera.request();
    }

    if (storageStatus.isGranted && cameraStatus.isGranted) {
      Get.defaultDialog(
        title: "Choose Image",
        middleText: "Pick an image from the camera or gallery?",
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back();
              selectImages("camera");
            },
            child: Text('Camera'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              selectImages("gallery");
            },
            child: Text('Gallery'),
          ),
        ],
      );
    } else if (storageStatus.isDenied || cameraStatus.isDenied) {
      Get.snackbar(
        "Permission Denied",
        "Error: Please allow permission for further usage",
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } else if (storageStatus.isPermanentlyDenied ||
        cameraStatus.isPermanentlyDenied) {
      Get.snackbar(
        "Permission Permanently Denied",
        "Error: Permission is permanently denied. Please allow permission from settings",
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
        mainButton: TextButton(
          onPressed: () {
            openAppSettings();
          },
          child: Text('Settings', style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  Future<void> selectImages(String type) async {
    List<XFile> imgs = [];
    if (type == 'gallery') {
      try {
        imgs = await _picker.pickMultiImage(imageQuality: 80);
        update();
      } catch (e) {
        print('Error $e');
      }
    } else {
      final img =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);

      if (img != null) {
        imgs.add(img);
        update();
      }
    }

    if (imgs.isNotEmpty) {
      selectedImages.addAll(imgs);
      update();
      print(selectedImages.length);
    }
  }

  void removeImages(int index) {
    selectedImages.removeAt(index);
    update();
  }

  Future<void> uploadFunction(List<XFile> _images) async {
    arrImagesUrl.clear();
    for (int i = 0; i < _images.length; i++) {
      dynamic imageUrl = await uplaodFile(_images[i]);
      arrImagesUrl.add(imageUrl.toString());
    }
    update();
  }

  Future<String> uplaodFile(XFile _image) async {
    TaskSnapshot reference = await storageRef
        .ref()
        .child("product-images")
        .child(_image.name + DateTime.now().toString())
        .putFile(File(_image.path));

    return await reference.ref.getDownloadURL();
  }
}
