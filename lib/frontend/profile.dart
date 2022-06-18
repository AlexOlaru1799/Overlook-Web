// ignore_for_file: prefer_const_constructors, unnecessary_new

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:overlook/frontend/changeProfile.dart';
import 'package:overlook/frontend/imagedialog.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';

import 'dart:ui' as ui;

import 'package:overlook/utils/globals.dart';
import 'package:overlook/utils/numbers_widget.dart';
import 'package:shimmer/shimmer.dart';

int followers = 0;
int following = 0;
int posts = 0;

bool stopShimmer = true;
double topDistanceForUserDetails = 200;
bool aboutSet = false;
bool postsSet = true;

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    print("INIT");
    if (Globals.getFirstLoadProfile() == false) {
      Timer _timer = new Timer(const Duration(milliseconds: 2000), () {
        setState(() {
          stopShimmer = false;

          Globals.changeFirstLoadProfile();
        });
      });
      Timer _timer3 = new Timer(const Duration(milliseconds: 3500), () {
        setState(() {
          displayPostsProfile = true;
        });
      });
    } else {
      stopShimmer = false;
      Timer _timer2 = new Timer(const Duration(milliseconds: 1500), () {
        setState(() {
          displayPostsProfile = true;
        });
      });
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

              if (userDocument!["about"] != "") {
                aboutSet = true;
              }
              followers = userDocument["followers"].length;
              following = userDocument["following"].length;
              posts = userDocument["posts"].length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  new Positioned(
                    top: 0,
                    right: 0,
                    left: 0,
                    child: stopShimmer
                        ? Shimmer.fromColors(
                            baseColor: Colors.grey,
                            highlightColor: Colors.white,
                            enabled: stopShimmer,
                            child: Container(
                              height: MediaQuery.of(context).size.height / 2,
                              width: MediaQuery.of(context).size.width / 2,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  fit: BoxFit.fitHeight,
                                  image: NetworkImage(
                                      userDocument["backgroundImage"]),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            height: MediaQuery.of(context).size.height / 2,
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
                  new Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: stopShimmer
                          ? Shimmer.fromColors(
                              baseColor: Colors.grey,
                              highlightColor: Colors.white,
                              enabled: stopShimmer,
                              child: Container(
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
                    top: MediaQuery.of(context).size.height / 5,
                    right: MediaQuery.of(context).size.width / 2.4,
                    child: CircleAvatar(
                      backgroundColor: mainColor,
                      child: IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChangeProfile()),
                          );
                        },
                      ),
                    ),
                  ),
                  new Positioned(
                      top: MediaQuery.of(context).size.height / 2.5,
                      child: NumbersWidget(userDocument["FollowersNumber"],
                          userDocument["FollowingNumber"])),
                  Container(
                    height: 120,
                    margin: EdgeInsets.fromLTRB(15, 140, 5, 0),
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
                          aboutSet
                              ? TextField(
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
                                      hintStyle:
                                          TextStyle(color: Colors.white)),
                                )
                              : SizedBox(
                                  height: 20,
                                ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(100, 520, 100, 0),
                    height: 250,
                    child: StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .where("owner", isEqualTo: userDocument["username"])
                            .where("postType", isNotEqualTo: "profileChange")
                            .orderBy("postType", descending: true)
                            .orderBy("createdAt", descending: true)
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

                                return displayPostsProfile
                                    ? GestureDetector(
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
                                      )
                                    : Shimmer.fromColors(
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
                                      );
                              });
                        }),
                  ),
                ],
              );
            }),
      ),
    );
  }
}
