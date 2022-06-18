// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';

String searchText = "";

class friendsPage extends StatefulWidget {
  const friendsPage({Key? key}) : super(key: key);

  @override
  State<friendsPage> createState() => _friendsPageState();
}

class _friendsPageState extends State<friendsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      body: Row(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  color: secondaryColor,
                  height: MediaQuery.of(context).size.height / 10,
                  width: MediaQuery.of(context).size.width / 2,
                  child: Row(children: [
                    //TextField(),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        height: 100,
                        width: MediaQuery.of(context).size.width / 2.5,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search user..',
                            hintStyle: TextStyle(color: mainColor),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: mainColor),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: mainColor),
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                          onChanged: ((value) {
                            setState(() {
                              searchText = value;
                            });
                          }),
                        ),
                      ),
                    ),
                    Spacer(),
                    Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.search_rounded,
                          color: mainColor,
                          size: 50,
                        ))
                  ]),
                ),
                Container(
                  color: secondaryColor,
                  height: MediaQuery.of(context).size.height / 1.15,
                  width: MediaQuery.of(context).size.width / 2,
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("RegularUsers")
                        .doc(FirebaseApi.realUserUID)
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                            snapshot) {
                      if (snapshot.hasError)
                        return new Text('Error: ${snapshot.error}');
                      else {
                        List followingList = snapshot.data!["following"];
                        return ListView.builder(
                          itemCount: followingList.length,
                          itemBuilder: (context, index) {
                            //return Text(followingList[index]);
                            return StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection("RegularUsers")
                                  .where("username",
                                      isEqualTo: followingList[index])
                                  .snapshots(),
                              builder: (BuildContext context2,
                                  AsyncSnapshot<
                                          QuerySnapshot<Map<String, dynamic>>>
                                      snapshot2) {
                                DocumentSnapshot document =
                                    snapshot2.data!.docs[0];
                                String username = document["username"];
                                String email = document["email"];
                                double username_len = 17;
                                double email_len = 17;
                                if (username.length.toDouble() > 20) {
                                  username_len =
                                      username.length.toDouble() * 2 / 5;
                                }
                                if (email.length.toDouble() > 15) {
                                  email_len = 1 / email.length.toDouble() * 250;
                                }
                                if (snapshot2.hasError) {
                                  return Text("Error!");
                                } else {
                                  //return Text(document["username"]);

                                  if (searchText != "") {
                                    if (document["username"]
                                        .contains(searchText)) {
                                      return Container(
                                        height: 120,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              5, 5, 5, 5),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                primary: secondaryColor,
                                                onPrimary: secondaryColor,
                                                textStyle: TextStyle(
                                                    fontSize: 30,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            onPressed: () {
                                              FirebaseApi.seeOtherProfile(
                                                  document["UID"], context);
                                            },
                                            child: Column(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                      color: mainColor,
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 1.5,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  15))),
                                                  height: 100,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 40,
                                                          backgroundColor:
                                                              Colors.white,
                                                          child: CircleAvatar(
                                                              radius: 35.0,
                                                              backgroundColor:
                                                                  mainColor,
                                                              child: ClipOval(
                                                                child: Image
                                                                    .network(
                                                                  document[
                                                                      "profileImage"],
                                                                  width: 135,
                                                                  height: 135,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                              )),
                                                        ),
                                                        Spacer(),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .fromLTRB(
                                                                  5, 25, 1, 0),
                                                          child: Column(
                                                            children: [
                                                              Text(
                                                                document[
                                                                    "username"],
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      username_len,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                              Text(
                                                                document[
                                                                    "email"],
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      email_len,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                  decoration:
                                                                      TextDecoration
                                                                          .underline,
                                                                  decorationStyle:
                                                                      TextDecorationStyle
                                                                          .double,
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                        Spacer(),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      return SizedBox();
                                    }
                                  } else {
                                    return Container(
                                      height: 120,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            5, 5, 5, 5),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              primary: secondaryColor,
                                              onPrimary: secondaryColor,
                                              textStyle: TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.bold)),
                                          onPressed: () {
                                            FirebaseApi.seeOtherProfile(
                                                document["UID"], context);
                                          },
                                          child: Column(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                    color: mainColor,
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                15))),
                                                height: 100,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 40,
                                                        backgroundColor:
                                                            Colors.white,
                                                        child: CircleAvatar(
                                                            radius: 35.0,
                                                            backgroundColor:
                                                                mainColor,
                                                            child: ClipOval(
                                                              child:
                                                                  Image.network(
                                                                document[
                                                                    "profileImage"],
                                                                width: 135,
                                                                height: 135,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            )),
                                                      ),
                                                      Spacer(),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .fromLTRB(
                                                                5, 25, 1, 0),
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                              document[
                                                                  "username"],
                                                              style: TextStyle(
                                                                fontSize:
                                                                    username_len,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            Text(
                                                              document["email"],
                                                              style: TextStyle(
                                                                fontSize:
                                                                    email_len,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                                decoration:
                                                                    TextDecoration
                                                                        .underline,
                                                                decorationStyle:
                                                                    TextDecorationStyle
                                                                        .double,
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      Spacer(),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height / 1.5,
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/gifs/Together.gif'),
                  fit: BoxFit.contain),
              borderRadius: BorderRadius.all(Radius.circular(100)),
            ),
          ),
        ],
      ),
    );
  }
}
