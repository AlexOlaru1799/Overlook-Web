import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart' if (kIsWeb) "";
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/services.dart' show rootBundle;

class Storage {
  final firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  Future<void> upldoadFile(
      String filePath, String username, String option, String imgName) async {
    File file = File(filePath);

    try {
      if (option == "profile") {
        await storage.ref('$username/profileImage').putFile(file);
      } else if (option == "background") {
        await storage.ref('$username/backgroundImage').putFile(file);
      } else if (option == "posts") {
        await storage.ref('$username/posts/$imgName').putFile(file);
      }
    } on firebase_core.FirebaseException catch (e) {
      print(e);
    }
  }

  Future<String> downloadURLProfile(
      String username, String option, String imageName) async {
    if (option == "profile") {
      String downloadURL =
          await storage.ref('$username/profileImage').getDownloadURL();
      return downloadURL;
    } else if (option == "background") {
      String downloadURL =
          await storage.ref('$username/backgroundImage').getDownloadURL();
      return downloadURL;
    } else if (option == "posts") {
      String downloadURL =
          await storage.ref('$username/posts/$imageName').getDownloadURL();
      return downloadURL;
    }

    return "error";
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/images/$path');

    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }
}
