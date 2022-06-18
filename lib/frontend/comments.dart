// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unnecessary_new

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';

String _postID = "";
String comment_text = "";

class Comments extends StatefulWidget {
  Comments(String post) {
    this.postID = post;
    _postID = post;
  }

  String postID = "";

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  TextEditingController textarea = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Container(
        color: secondaryColor,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  color: secondaryColor,
                  height: MediaQuery.of(context).size.height / 1.4,
                  width: MediaQuery.of(context).size.width / 2,
                  child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection("posts")
                          .doc(_postID)
                          .collection("comments")
                          .orderBy("createdAT", descending: true)
                          .snapshots(),
                      builder: (BuildContext context3,
                          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                              snapshot3) {
                        if (snapshot3.data!.size == 1) {
                          return Text(
                            "No comments yet",
                            style: TextStyle(color: thirdColor, fontSize: 30),
                          );
                        } else {
                          return SingleChildScrollView(
                            child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: snapshot3.data!.docs.length,
                                itemBuilder: ((context, index) {
                                  DocumentSnapshot document2 =
                                      snapshot3.data!.docs[index];

                                  String authorID = document2["authorID"];

                                  Timestamp timestamp = document2['createdAT'];
                                  String commentID = document2.id;
                                  DateTime date = timestamp.toDate();

                                  var _today = DateTime.parse(date.toString());
                                  var pre_format =
                                      DateFormat.Hms().format(date);
                                  var _formatToday =
                                      DateFormat.yMMMd().format(date) +
                                          " " +
                                          pre_format;

                                  if (authorID == "") {
                                    return SizedBox(
                                      height: 1,
                                    );
                                  } else {
                                    return StreamBuilder(
                                        stream: FirebaseFirestore.instance
                                            .collection("RegularUsers")
                                            .where("username",
                                                isEqualTo: authorID)
                                            .snapshots(),
                                        builder: (BuildContext context4,
                                            AsyncSnapshot<
                                                    QuerySnapshot<
                                                        Map<String, dynamic>>>
                                                snapshot4) {
                                          if (snapshot4.hasData == true) {
                                            DocumentSnapshot document3 =
                                                snapshot4.data!.docs[0];
                                            String username =
                                                document3["username"];
                                            double username_len = 17;

                                            if (username.length.toDouble() >
                                                20) {
                                              username_len =
                                                  username.length.toDouble() *
                                                      2 /
                                                      5;
                                            }

                                            // return Text(
                                            //   document2["comment"],
                                            //   style: TextStyle(fontSize: 30),
                                            // );

                                            return Card(
                                              color: secondaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      Radius.circular(12.0),
                                                  topRight:
                                                      Radius.circular(12.0),
                                                ),
                                              ),
                                              elevation: 0.8,
                                              child: Container(
                                                color: secondaryColor,
                                                margin:
                                                    EdgeInsets.only(bottom: 4),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text.rich(
                                                          TextSpan(
                                                            children: [
                                                              WidgetSpan(
                                                                child:
                                                                    Container(
                                                                  margin: EdgeInsets
                                                                      .only(
                                                                          right:
                                                                              8.0),
                                                                  width: 45,
                                                                  height: 45,
                                                                  decoration:
                                                                      new BoxDecoration(
                                                                    color:
                                                                        secondaryColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            100),
                                                                    image:
                                                                        new DecorationImage(
                                                                      image:
                                                                          NetworkImage(
                                                                        document3[
                                                                            "profileImage"],
                                                                      ),
                                                                      fit: BoxFit
                                                                          .fill,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                  text: document3[
                                                                      "username"],
                                                                  style:
                                                                      GoogleFonts
                                                                          .roboto(
                                                                    fontSize:
                                                                        username_len +
                                                                            5,
                                                                    color:
                                                                        mainColor,
                                                                  )),
                                                            ],
                                                          ),
                                                        ),
                                                        Text(
                                                          _formatToday,
                                                          style: TextStyle(
                                                              color:
                                                                  thirdColor),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: 10,
                                                    ),
                                                    Text(
                                                      document2["comment"],
                                                      style: GoogleFonts.roboto(
                                                          fontSize: 16,
                                                          color: thirdColor),
                                                    ),
                                                    Container(
                                                      color: secondaryColor,
                                                      margin: EdgeInsets.only(
                                                          bottom: 10, top: 10),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .fromLTRB(
                                                                0, 10, 45, 0),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            SizedBox(
                                                              height: 10,
                                                            ),
                                                            Text.rich(
                                                              TextSpan(
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .button,
                                                                children: [
                                                                  WidgetSpan(
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        Container(
                                                                          child:
                                                                              IconButton(
                                                                            icon:
                                                                                Icon(Icons.thumb_up_alt_outlined),
                                                                            color:
                                                                                mainColor,
                                                                            onPressed:
                                                                                () {
                                                                              FirebaseApi.likeComment(commentID, _postID);
                                                                            },
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          document2["likes"]
                                                                              .toString(),
                                                                          style: GoogleFonts.roboto(
                                                                              fontSize: 14,
                                                                              color: thirdColor),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 35,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          } else {
                                            return SizedBox(
                                              height: 10,
                                            );
                                          }
                                        });
                                  }
                                })),
                          );
                        }
                      }),
                ),
                SizedBox(
                  height: 20,
                ),
                Container(
                  color: secondaryColor,
                  width: MediaQuery.of(context).size.width / 2,
                  height: MediaQuery.of(context).size.height / 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Leave a comment bellow!",
                          style: TextStyle(fontSize: 20, color: mainColor),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            color: secondaryColor,
                            height: MediaQuery.of(context).size.height / 6,
                            width: MediaQuery.of(context).size.width / 2.5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: textarea,
                                keyboardType: TextInputType.multiline,
                                maxLines: 5,
                                decoration: InputDecoration(
                                    hintText: "Enter description",
                                    filled: true,
                                    fillColor: thirdColor,
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            width: 2, color: mainColor))),
                                onChanged: (value) {
                                  comment_text = value;
                                },
                              ),
                            ),
                          ),
                          Transform.rotate(
                            angle: 5.2,
                            child: IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                size: 40,
                              ),
                              color: mainColor,
                              onPressed: () async {
                                await FirebaseApi.addComment(
                                    _postID,
                                    comment_text,
                                    FirebaseApi.realUserLastData!
                                        .getUsername()!);

                                textarea.clear();
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height / 1.5,
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/gifs/Comments.gif'),
                    fit: BoxFit.contain),
                borderRadius: BorderRadius.all(Radius.circular(100)),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
