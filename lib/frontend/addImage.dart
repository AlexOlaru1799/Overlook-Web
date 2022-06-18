// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:overlook/main.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';
import 'package:overlook/utils/utils.dart';

class AddImage extends StatefulWidget {
  const AddImage({Key? key}) : super(key: key);

  @override
  State<AddImage> createState() => _AddImageState();
}

class _AddImageState extends State<AddImage> {
  String tempImage = "assets/images/tempPhoto.jpg";
  XFile? fileChosen;
  Uint8List? temp2;
  bool chosenImage = false;
  TextEditingController textarea = TextEditingController();
  String imageDesc = "";

  @override
  Widget build(BuildContext context) {
    File? _photo;
    final ImagePicker _picker = ImagePicker();

    Future PreimgFromGallery(String option) async {
      //final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      var f = await image!.readAsBytes();
      setState(() {
        if (image != null) {
          temp2 = f;
          chosenImage = true;
        }
      });
    }

    Future imgFromGallery() async {
      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('RegularUsers')
          .where('username',
              isEqualTo: FirebaseApi.realUserLastData!.getUsername())
          .get();
      QueryDocumentSnapshot doc = querySnap.docs[0];
      DocumentReference docRef = doc.reference;

      int currentImage = doc["imagesNumber"];
      int lastNr = currentImage;
      currentImage = currentImage + 1;

      String imageName = "post" + currentImage.toString();

      await docRef.update({
        "imagesNumber": currentImage,
      });

      String? url = await Utils2.uploadImagePost(
          FirebaseApi.realUserLastData!.getUsername()!,
          temp2!,
          currentImage.toString(),
          imageName);

      List posts = doc["posts"];
      String docID = docRef.id;
      posts.add(url);
      GeoPoint location = doc["location"];
      docRef.update({"posts": FieldValue.arrayUnion(posts)});

      DateTime now = DateTime.now();

      List userLikes = [];

      FirebaseFirestore.instance
          .collection('RegularUsers')
          .doc(docID)
          .collection('posts')
          .doc(imageName)
          .set({
        "createdAt": now,
        "postLocation": location,
        "imageURL": url,
        "text": imageDesc,
        "userLikes": userLikes,
        "likes": 0
      });

      String postID = docID + lastNr.toString();

      FirebaseFirestore.instance.collection('posts').doc(postID).set({
        "createdAt": now,
        "postLocation": location,
        "imageURL": url,
        "text": imageDesc,
        "owner": FirebaseApi.realUserLastData!.getUsername(),
        "userLikes": userLikes,
        "likes": 0,
        "postType": "addImage"
      });

      FirebaseFirestore.instance
          .collection('posts')
          .doc(postID)
          .collection('comments')
          .doc()
          .set({
        "authorID": "",
        "createdAT": now,
        "comment": "TEST MESS",
        "likes": 0
      });
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: secondaryColor,
          //height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: Container(
                    height: 125,
                    child: chosenImage
                        ? Image.memory(temp2!)
                        : Image.asset(tempImage)),
              ),
              Container(
                height: MediaQuery.of(context).size.height / 15,
                width: MediaQuery.of(context).size.width / 2,
                color: Colors.black,
                child: ElevatedButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Add an Image",
                            style: GoogleFonts.openSans(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.photo,
                          color: Colors.white,
                        ),
                        Spacer()
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: mainColor,
                    ),
                    onPressed: () => {PreimgFromGallery("posts")}),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                height: MediaQuery.of(context).size.height / 6,
                width: MediaQuery.of(context).size.width / 1.15,
                child: TextField(
                  controller: textarea,
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Enter description",
                    hintStyle: GoogleFonts.openSans(
                      color: mainColor,
                      fontSize: 12,
                    ),
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: mainColor, width: 1),
                        borderRadius: BorderRadius.circular(10)),
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: mainColor, width: 1),
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (value) {
                    imageDesc = value;
                  },
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height / 15,
                width: MediaQuery.of(context).size.width / 1.15,
                child: ElevatedButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Post",
                            style: GoogleFonts.openSans(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                        Spacer()
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: mainColor,
                    ),
                    onPressed: () {
                      imgFromGallery();
                      setState(() {
                        chosenImage = false;
                        tempImage = "assets/images/tempPhoto.jpg";
                      });

                      textarea.clear();
                    }),
              ),
              Container(
                height: MediaQuery.of(context).size.height / 2.2,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/gifs/locationTracking.gif'),
                      fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
