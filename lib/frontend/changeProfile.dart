// ignore_for_file: unnecessary_new, prefer_const_constructors

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';
import 'package:overlook/utils/numbers_widget.dart';
import 'package:overlook/utils/utils.dart';

String? aboutNEW;

class ChangeProfile extends StatelessWidget {
  const ChangeProfile({Key? key}) : super(key: key);

  Future imgFromGallery(String type) async {
    final ImagePicker _picker = ImagePicker();
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    var f = await image!.readAsBytes();

    Uint8List temp2 = f;

    String? url = await Utils2.updateProfileImages(
      FirebaseApi.realUserLastData!.getUsername()!,
      temp2,
      type,
    );

    if (type == "profile") {
      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('RegularUsers')
          .where('UID', isEqualTo: FirebaseApi.realUserUID)
          .get();
      QueryDocumentSnapshot doc = querySnap.docs[0];
      DocumentReference docRef = doc.reference;

      docRef.update({"profileImage": url});

      QuerySnapshot querySnap2 = await FirebaseFirestore.instance
          .collection('RegularUsers')
          .where('username',
              isEqualTo: FirebaseApi.realUserLastData!.getUsername())
          .get();
      QueryDocumentSnapshot doc2 = querySnap.docs[0];
      DocumentReference docRef2 = doc.reference;

      String docID = docRef2.id;

      int currentImage = doc["imagesNumber"];
      int lastNr = currentImage;

      DateTime now = DateTime.now();

      GeoPoint location = doc["location"];

      List userLikes = [];

      String postID = docID + "_profile";

      String imageDesc = "";

      FirebaseFirestore.instance.collection('posts').doc(postID).set({
        "createdAt": now,
        "postLocation": location,
        "imageURL": url,
        "text": imageDesc,
        "owner": FirebaseApi.realUserLastData!.getUsername(),
        "userLikes": userLikes,
        "likes": 0,
        "postType": "profileChange"
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
    } else if (type == "background") {
      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('RegularUsers')
          .where('username',
              isEqualTo: FirebaseApi.realUserLastData!.getUsername()!)
          .get();
      QueryDocumentSnapshot doc = querySnap.docs[0];
      DocumentReference docRef = doc.reference;

      docRef.update({"backgroundImage": url});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      body: Scaffold(
        backgroundColor: secondaryColor,
        body: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('RegularUsers')
                .doc(FirebaseApi.realUserUID)
                .snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Text("Loading");
              }

              var userDocument = snapshot.data;

              return SingleChildScrollView(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    new Positioned(
                      top: 0,
                      right: 0,
                      left: 0,
                      child: Container(
                        height: MediaQuery.of(context).size.height / 2.5,
                        width: MediaQuery.of(context).size.width / 2,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.fitHeight,
                            image:
                                NetworkImage(userDocument!["backgroundImage"]),
                          ),
                        ),
                      ),
                    ),

                    // ignore: unnecessary_new

                    new Positioned.fill(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          //padding: EdgeInsets.all(90.0),
                          width: MediaQuery.of(context).size.width / 4,
                          height: MediaQuery.of(context).size.height / 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mainColor,
                            image: DecorationImage(
                              fit: BoxFit.contain,
                              image: NetworkImage(userDocument["profileImage"]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    new Positioned(
                      top: MediaQuery.of(context).size.height / 7,
                      left: MediaQuery.of(context).size.width / 3,
                      child: CircleAvatar(
                        backgroundColor: mainColor,
                        child: IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              imgFromGallery("background");
                            }),
                      ),
                    ),
                    new Positioned(
                      top: MediaQuery.of(context).size.height / 5,
                      right: MediaQuery.of(context).size.width / 2.4,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 370, left: 150),
                        child: CircleAvatar(
                          backgroundColor: mainColor,
                          child: IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              imgFromGallery("profile");
                            },
                          ),
                        ),
                      ),
                    ),
                    new Positioned(
                        top: MediaQuery.of(context).size.height / 2.5,
                        child: NumbersWidget(userDocument["FollowersNumber"],
                            userDocument["FollowingNumber"])),
                    Container(
                      height: 350,
                      margin: EdgeInsets.fromLTRB(10, 400, 0, 0),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          TextField(
                            readOnly: true,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                                label: Center(
                                  child: Text(
                                    "Username",
                                    style: TextStyle(
                                      color: mainColor,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                hintText: userDocument["username"],
                                hintStyle: TextStyle(color: Colors.white)),
                          ),
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                            height: 5 * 24.0,
                            child: TextField(
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                              maxLines: 5,
                              decoration: InputDecoration(
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  border: InputBorder.none,
                                  label: Center(
                                    child: Text(
                                      "About",
                                      style: TextStyle(
                                        color: mainColor,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                  hintText: userDocument["about"],
                                  hintStyle: TextStyle(color: Colors.white)),
                              onChanged: (value) {
                                aboutNEW = value;
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: mainColor,
          onPressed: () {
            FirebaseApi.updateAboutForUser(aboutNEW!);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.edit),
          label: const Text('Save Changes'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
