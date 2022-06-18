// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:overlook/frontend/comments.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';
import 'package:share_plus/share_plus.dart';

import 'package:shimmer/shimmer.dart';

bool loadFavourites = false;

void showCustomDialog(BuildContext context, String postID) {
  showGeneralDialog(
    context: context,
    barrierLabel: "Barrier",
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) {
      return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("posts")
              .doc(postID)
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            DocumentSnapshot document = snapshot.data;

            return Container(
              width: MediaQuery.of(context).size.width / 3,
              height: MediaQuery.of(context).size.height / 10,
              child: Card(
                color: mainColor.withOpacity(0.05),
                child: Container(
                  width: MediaQuery.of(context).size.width / 3,
                  height: MediaQuery.of(context).size.height / 10,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 450,
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(document["imageURL"]),
                              fit: BoxFit.contain,
                            ),
                            borderRadius: BorderRadius.circular(40)),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Spacer(),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.thumb_up_alt_outlined),
                                  color: mainColor,
                                  onPressed: () {
                                    FirebaseApi.likePost(postID);
                                  },
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(document["likes"].toString(),
                                    style: TextStyle(color: Colors.white)),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "Likes",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            Comments(postID)));
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.comment_rounded, color: mainColor),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text("Comments",
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                                onTap: () async {
                                  String imageURL = document["imageURL"];

                                  // final url = Uri.parse(imageURL);
                                  // final response = await http.get(url);
                                  // final bytes = response.bodyBytes;

                                  // final temp = await getTemporaryDirectory();
                                  // final path = '${temp.path}/image.jpg';
                                  // File(path).writeAsBytesSync(bytes);

                                  await Share.share(
                                      "The user " +
                                          document["owner"] +
                                          " has posted a new image! Login now in order to see the coolest posts!\n https://overlook-64769.web.app/#/",
                                      subject: 'Check out what ' +
                                          document["owner"] +
                                          " has posted!");
                                },
                                child: Row(children: [
                                  Icon(
                                    Icons.link_rounded,
                                    color: mainColor,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text("Share",
                                      style: TextStyle(color: Colors.white)),
                                ])),
                            Spacer(),
                          ]),
                      IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            size: 35,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context))
                    ],
                  ),
                ),
              ),
            );
          });
    },
    transitionBuilder: (_, anim, __, child) {
      Tween<Offset> tween;
      if (anim.status == AnimationStatus.reverse) {
        tween = Tween(begin: Offset(-1, 0), end: Offset.zero);
      } else {
        tween = Tween(begin: Offset(1, 0), end: Offset.zero);
      }

      return SlideTransition(
        position: tween.animate(anim),
        child: FadeTransition(
          opacity: anim,
          child: child,
        ),
      );
    },
  );
}

class Favourites extends StatefulWidget {
  const Favourites({Key? key}) : super(key: key);

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  @override
  void initState() {
    super.initState();
    Timer _timer3 = new Timer(const Duration(milliseconds: 2250), () {
      setState(() {
        loadFavourites = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // if (changedColors == false) {
    //   const mainColorTemp = Color(0xffEB5325);
    //   const secColorTemp = Color.fromARGB(255, 14, 14, 14);
    // } else {
    //   const mainColorTemp = Color(0xff21A7EA);
    //   const secColorTemp = Color(0xff351c75);
    // }
    return Scaffold(
        body: Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: secondaryColor,
      child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("posts")
              .orderBy('createdAt', descending: true)
              .where("userLikes",
                  arrayContains: FirebaseApi.realUserLastData!.getUsername())
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasError)
              return new Text('Error: ${snapshot.error}');
            else {
              return SingleChildScrollView(
                  child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 350,
                              childAspectRatio: 1,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: ((context, index) {
                        DocumentSnapshot document = snapshot.data!.docs[index];
                        String postID = document.id;

                        List userLikes = document["userLikes"];

                        if (userLikes.contains(
                            FirebaseApi.realUserLastData!.getUsername())) {
                          return loadFavourites
                              ? GestureDetector(
                                  child: Container(
                                    child: Image.network(
                                      document["imageURL"],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  onTap: () {
                                    print("TAP");
                                    showCustomDialog(context, postID);
                                  },
                                )
                              : Shimmer.fromColors(
                                  baseColor: mainColor,
                                  highlightColor: Colors.white,
                                  enabled: true,
                                  child: Container(
                                    child: Image.network(
                                      document["imageURL"],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                        } else {
                          return SizedBox(
                            height: 1,
                          );
                        }
                      })));
            }
          }),
    ));
  }
}
