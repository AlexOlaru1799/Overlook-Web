// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';

import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:overlook/frontend/components/maps.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/firebase_api.dart';
import 'package:overlook/utils/navbar.dart';
import 'package:overlook/utils/utils.dart';

var eventTypes = [
  "Cultural",
  "Social Gathering",
  "Party",
  "Opening",
  "Sports",
];

bool cameraFollow = true;

final pages = [
  Container(),
  Container(),
  Container(),
];

int pointerNumber = 1;
bool loaded = false;

Size size = WidgetsBinding.instance!.window.physicalSize;
int postIndex = 0;

List followings = [];

bool changed = false;

bool localDisabledLocation = true;
Timer? timer;

GeoPoint? lastLoc;

bool loadCameraOnce = true;

bool showOthers = false;

bool showEvents = true;

class MainMap extends StatefulWidget {
  @override
  _MainMapState createState() => _MainMapState();

  static final style = TextStyle(
    fontSize: 10,
    fontFamily: "Billy",
    fontWeight: FontWeight.w600,
  );
}

class _MainMapState extends State<MainMap> {
  @override
  void initState() {
    initFunction();

    super.initState();
  }

  void initFunction() async {}

  @override
  Widget build(BuildContext context) {
    // to hide system navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    var tempMarker;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
      drawer: NavBar(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(45),
        child: AppBar(
          elevation: 0.0,
          backgroundColor: secondaryColor,
        ),
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height / 1.1,
            // child:
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("RegularUsers")
                  .where("username",
                      isEqualTo: FirebaseApi.realUserLastData!.getUsername())
                  .snapshots(),
              builder: (context, AsyncSnapshot<dynamic> snapshot) {
                print(snapshot);
                if (snapshot.hasData) {
                  //Extract the location from document
                  DocumentSnapshot doc = snapshot.data!.docs[0];
                  GeoPoint location = snapshot.data!.docs.first.get("location");

                  lastLoc = location;
                  String username = doc["username"];
                  String UID = doc["UID"];
                  String profileURL = doc["profileImage"];
                  return GoogleMap(profileURL, location, username, UID);
                } else {
                  return SizedBox();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
