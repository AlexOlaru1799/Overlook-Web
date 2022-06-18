// ignore_for_file: unnecessary_new, prefer_const_constructors

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:overlook/frontend/imagedialog.dart';
import 'package:overlook/frontend/singleChat.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';
import 'package:overlook/utils/numbers_widget.dart';

import 'package:shimmer/shimmer.dart';

String? currentUID;

double topDistanceForUserDetails = 200;
bool aboutSet = false;
bool? tempBoolForFollowUnfollow;
String? currentUsername;
String? roomUID;

class OtherProfilePage extends StatefulWidget {
  OtherProfilePage(
      String UID, bool tempBoolForFollowUnfollow2, String username) {
    currentUID = UID;
    tempBoolForFollowUnfollow = tempBoolForFollowUnfollow2;
    currentUsername = username;
  }

  @override
  _OtherProfilePageState createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 2000), () {
      setState(() {
        displayOtherProfile = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: mainColor,
        body: Scaffold(
          backgroundColor: secondaryColor,
          body: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('RegularUsers')
                  .doc(currentUID)
                  .snapshots(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Text("Loading");
                }

                var userDocument = snapshot.data;
                currentUsername = userDocument!["username"];
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    new Positioned(
                      top: 0,
                      right: 0,
                      left: 0,
                      child: displayOtherProfile
                          ? Shimmer.fromColors(
                              baseColor: Colors.grey,
                              highlightColor: Colors.white,
                              enabled: displayOtherProfile,
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height / 2.5,
                                width: MediaQuery.of(context).size.width / 2,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    fit: BoxFit.fitHeight,
                                    image: NetworkImage(
                                        userDocument["profileImage"]),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: MediaQuery.of(context).size.height / 2.5,
                              width: MediaQuery.of(context).size.width / 2,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.fitHeight,
                                  image: NetworkImage(
                                      userDocument["backgroundImage"]),
                                ),
                              ),
                            ),
                    ),

                    // ignore: unnecessary_new

                    new Positioned.fill(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: displayOtherProfile
                            ? Shimmer.fromColors(
                                baseColor: Colors.grey,
                                highlightColor: Colors.white,
                                enabled: displayOtherProfile,
                                child: Container(
                                  //padding: EdgeInsets.all(90.0),
                                  width: MediaQuery.of(context).size.width / 4,
                                  height:
                                      MediaQuery.of(context).size.height / 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: secondaryColor,
                                    image: DecorationImage(
                                      fit: BoxFit.contain,
                                      image: NetworkImage(
                                          userDocument["profileImage"]),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                //padding: EdgeInsets.all(90.0),
                                width: MediaQuery.of(context).size.width / 4,
                                height: MediaQuery.of(context).size.height / 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: secondaryColor,
                                  image: DecorationImage(
                                    fit: BoxFit.contain,
                                    image: NetworkImage(
                                        userDocument["profileImage"]),
                                  ),
                                ),
                              ),
                      ),
                    ),

                    new Positioned(
                        top: MediaQuery.of(context).size.height / 3.65,
                        child: NumbersWidget(userDocument["FollowersNumber"],
                            userDocument["FollowingNumber"])),
                    Container(
                      height: 120,
                      margin: EdgeInsets.fromLTRB(15, 30, 5, 0),
                      alignment: Alignment.center,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            TextField(
                              textAlign: TextAlign.center,
                              readOnly: true,
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
                            TextField(
                              textAlign: TextAlign.center,
                              readOnly: true,
                              decoration: InputDecoration(
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
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
                            )
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(5, 420, 5, 0),
                      height: 250,
                      child: StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('posts')
                              .orderBy("createdAt", descending: true)
                              .where("owner",
                                  isEqualTo: userDocument["username"])
                              .snapshots(),
                          builder: (BuildContext context2,
                              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                                  snapshot2) {
                            int docLen = snapshot2.data!.docs.length;

                            return GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 200,
                                        childAspectRatio: 1,
                                        crossAxisSpacing: 20,
                                        mainAxisSpacing: 20),
                                itemCount: docLen,
                                itemBuilder: (BuildContext ctx, index) {
                                  DocumentSnapshot document2 =
                                      snapshot2.data!.docs[index];

                                  String postID = document2.id;
                                  String likes = document2["likes"].toString();

                                  print(document2["owner"]);

                                  return displayOtherProfile
                                      ? Shimmer.fromColors(
                                          baseColor: mainColor,
                                          highlightColor: Colors.white,
                                          enabled: true,
                                          child: Container(
                                            //padding: EdgeInsets.all(90.0),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2.2,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                2,
                                            decoration: BoxDecoration(
                                              color: mainColor,
                                              image: DecorationImage(
                                                fit: BoxFit.cover,
                                                image: NetworkImage(
                                                    document2["imageURL"]),
                                              ),
                                            ),
                                          ),
                                        )
                                      : GestureDetector(
                                          onTap: () async {
                                            await showDialog(
                                                context: context,
                                                builder: (_) => ImageDialog(
                                                    postID,
                                                    document2["imageURL"],
                                                    likes,
                                                    true));
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                                image: DecorationImage(
                                              image: NetworkImage(
                                                  document2["imageURL"]),
                                              fit: BoxFit.cover,
                                            )),
                                          ),
                                        );
                                });
                          }),
                    ),
                  ],
                );
              }),
        ),
        bottomNavigationBar: Container(
          color: secondaryColor,
          height: 100,
          child: BottomAppBar(
            color: secondaryColor,
            child: Stack(
              alignment: Alignment.center,
              children: [
                new Positioned(
                    left: 10,
                    top: 10,
                    child: tempBoolForFollowUnfollow!
                        ? ElevatedButton(
                            onPressed: () {
                              FirebaseApi.addFollower(currentUsername!);
                              setState(() {
                                tempBoolForFollowUnfollow = false;
                              });
                            },
                            child: Text("Follow"),
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                primary: mainColor,
                                fixedSize: Size(
                                    MediaQuery.of(context).size.width / 2.2,
                                    50)),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              FirebaseApi.removeFollower(currentUsername!);
                              setState(() {
                                tempBoolForFollowUnfollow = true;
                              });
                            },
                            child: Text("Unfollow"),
                            style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                primary: mainColor,
                                fixedSize: Size(
                                    MediaQuery.of(context).size.width / 2.2,
                                    50)),
                          )),
                new Positioned(
                    right: 10,
                    top: 10,
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseApi.createRoom(currentUsername!);

                        roomUID = await FirebaseApi.getRoomUID(currentUID!);
                        if (roomUID != "null") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => singleChat(
                                    currentUID!, currentUsername!, roomUID!)),
                          );
                        }
                      },
                      child: Text("Send Message"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        primary: mainColor,
                        fixedSize:
                            Size(MediaQuery.of(context).size.width / 2.2, 50),
                      ),
                    )),
              ],
            ),
          ),
        ));
  }
}
