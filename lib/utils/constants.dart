import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:overlook/utils/event.dart';

const kPrimaryColor = Color(0xFF6F35A5);
const kPrimaryLightColor = Color(0xFFF1E6FF);
const mainColor = Color(0xffEB5325);
const secondaryColor = Color.fromARGB(255, 14, 14, 14);
const thirdColor = Colors.white;

const mainColorSec = Color(0xff21A7EA);
const secondaryColorSec = Color(0xff351c75);

bool changedColors = true;

bool displayPostsProfile = false;

bool displayNavbar = false;

bool displayOtherProfile = true;

bool loadNews = false;

List<String> otherUIDS = [];
List<String> otherUsernames = [];
List<String> otherProfileImages = [];
List<GeoPoint> otherLocations = [];
List<myEvent> allEvents = [];
