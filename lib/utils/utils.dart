import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart' as firebaseStorage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:overlook/utils/storage.dart';
import 'package:path/path.dart' as Path;

class Post {
  String? description;
  DateTime? time;
  String? URL;
  GeoPoint? location;

  Post(String desc, String url, DateTime _time, GeoPoint loc) {
    this.description = desc;
    this.location = loc;
    this.URL = url;
    this.time = _time;
  }

  String? getURL() {
    return this.URL;
  }

  String? getDescription() {
    return this.description;
  }

  GeoPoint? getLocation() {
    return this.location;
  }

  DateTime? getTime() {
    return this.time;
  }
}

class Utils2 {
  static void showAlertDialog(
      BuildContext context, String title, String message) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static Future<LocationData> getLocationWithPermissions(
      BuildContext context) async {
    Location location = new Location();
    PermissionStatus? _permissionGranted;

    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        // set up the AlertDialog
        // set up the button
        Widget okButton = TextButton(
          child: Text("OK"),
          onPressed: () {},
        );
        AlertDialog alert = AlertDialog(
          title: Text("Location Permissions"),
          content: Text(
              "In order to use this application you need to allow permissions for location."),
          actions: [
            okButton,
          ],
        );

        // show the dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        );
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        // set up the AlertDialog
        // set up the button
        Widget okButton = TextButton(
          child: Text("OK"),
          onPressed: () {},
        );
        AlertDialog alert = AlertDialog(
          title: Text("Location Permissions"),
          content: Text(
              "In order to use this application you need to allow permissions for location."),
          actions: [
            okButton,
          ],
        );

        // show the dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        );
      }
    }

    return location.getLocation();
  }

  static Future<String?> selectPicture(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    XFile? image = await _picker.pickImage(
      source: source,
      maxHeight: 1000,
      maxWidth: 1000,
    );

    return image?.path;
  }

  static Future<String?> uploadImagePost(
      String username, Uint8List uList, String index, String imageName) async {
    final firebaseStorage.FirebaseStorage storage =
        firebaseStorage.FirebaseStorage.instance;

    final storage_ref = storage
        .refFromURL("gs://overlook-64769.appspot.com")
        .child(username + "/posts/post" + index);

    storage_ref.putData(
      uList,
      firebaseStorage.SettableMetadata(contentType: 'image/jpeg'),
    );

    Storage storage2 = new Storage();

    await Future.delayed(const Duration(seconds: 2), () {});

    String profileURL =
        await storage2.downloadURLProfile(username, "posts", imageName);

    return profileURL;
  }

  static Future<String?> updateProfileImages(
      String username, Uint8List uList, String type) async {
    final firebaseStorage.FirebaseStorage storage =
        firebaseStorage.FirebaseStorage.instance;

    if (type == "profile") {
      final storage_ref = storage
          .refFromURL("gs://overlook-64769.appspot.com")
          .child(username + "/profileImage");
      storage_ref.putData(
        uList,
        firebaseStorage.SettableMetadata(contentType: 'image/jpeg'),
      );
      Storage storage2 = new Storage();

      await Future.delayed(const Duration(seconds: 2), () {});

      String profileURL =
          await storage2.downloadURLProfile(username, "profile", "");

      return profileURL;
    } else if (type == "background") {
      final storage_ref = storage
          .refFromURL("gs://overlook-64769.appspot.com")
          .child(username + "/backgroundImage");
      storage_ref.putData(
        uList,
        firebaseStorage.SettableMetadata(contentType: 'image/jpeg'),
      );
      Storage storage2 = new Storage();

      await Future.delayed(const Duration(seconds: 2), () {});

      String profileURL =
          await storage2.downloadURLProfile(username, "background", "");
      return profileURL;
    }
  }

  static Future<String?> uploadImage(
      String path, String username, String type) async {
    final ByteData bytes = await rootBundle.load(path);
    final Uint8List uList = bytes.buffer.asUint8List();

    final firebaseStorage.FirebaseStorage storage =
        firebaseStorage.FirebaseStorage.instance;

    if (type == "profile") {
      final storage_ref = storage
          .refFromURL("gs://overlook-64769.appspot.com")
          .child(username + "/profileImage");

      storage_ref.putData(
        uList,
        firebaseStorage.SettableMetadata(contentType: 'image/jpeg'),
      );

      Storage storage2 = new Storage();

      await Future.delayed(const Duration(seconds: 2), () {});

      String profileURL =
          await storage2.downloadURLProfile(username, "profile", "");

      return profileURL;
    } else {
      final storage_ref = storage
          .refFromURL("gs://overlook-64769.appspot.com")
          .child(username + "/backgroundImage");

      storage_ref.putData(
        uList,
        firebaseStorage.SettableMetadata(contentType: 'image/jpeg'),
      );

      Storage storage2 = new Storage();

      await Future.delayed(const Duration(seconds: 2), () {});

      String profileURL =
          await storage2.downloadURLProfile(username, "background", "");

      return profileURL;
    }
  }

//   uploadImageToStorage(PickedFile? pickedFile) async {
//     if (kIsWeb) {
//       Reference _reference = _firebaseStorage
//           .ref()
//           .child('images/${Path.basename(pickedFile!.path)}');
//       await _reference
//           .putData(
//         await pickedFile!.readAsBytes(),
//         SettableMetadata(contentType: 'image/jpeg'),
//       )
//           .whenComplete(() async {
//         await _reference.getDownloadURL().then((value) {
//           uploadedPhotoUrl = value;
//         });
//       });
//     } else {
// //write a code for android or ios
//     }
//   }
}
