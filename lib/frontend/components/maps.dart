import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps/google_maps.dart' as GM;
import 'dart:ui' as ui;
import 'package:location/location.dart';
import 'package:overlook/frontend/otherProfile.dart';
import 'package:overlook/frontend/profile.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/event.dart';
import 'package:overlook/utils/firebase_api.dart';

String? profileURL;
GeoPoint? userLocation;
String? username;
String? UID;

class GoogleMap extends StatefulWidget {
  @override
  State<GoogleMap> createState() => _GoogleMapState();

  GoogleMap(String urlProfileMainUser, GeoPoint loc, String usern, String uid) {
    profileURL = urlProfileMainUser;
    userLocation = loc;
    UID = uid;
    username = usern;
  }
}

Widget _buildPopupDialog(BuildContext context, String username, String uid) {
  return AlertDialog(
    title: Text(username),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("You have discovered the user " + username + " nearby!"),
      ],
    ),
    actions: <Widget>[
      ElevatedButton(
        onPressed: () {
          if (username == FirebaseApi.realUserLastData!.getUsername()) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          } else {
            FirebaseApi.seeOtherProfile(uid, context);
          }
        },
        style: ElevatedButton.styleFrom(
            primary: mainColor,
            //padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            textStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        child: const Text('Go to Profile'),
      ),
    ],
  );
}

Widget _buildPopupDialogEvent(BuildContext context, String id) {
  int width = (MediaQuery.of(context).size.width / 20).round();
  return StreamBuilder(
      stream:
          FirebaseFirestore.instance.collection('events').doc(id).snapshots(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        var doc = snapshot.data;
        List coming = doc!["coming"];
        bool emptyComing = false;

        bool alreadyParticipating = true;

        if (coming.isEmpty == true) {
          emptyComing = true;
        }

        if (coming.contains(FirebaseApi.realUserLastData!.getUsername())) {
          alreadyParticipating = false;
        }

        for (int i = 0; i < coming.length; i++) {
          print("coming : " + i.toString() + " - " + coming[i]);
        }
        return AlertDialog(
          titleTextStyle: GoogleFonts.lobster(
            color: mainColor,
            fontSize: 20,
          ),
          title: Text(
            doc["eventType"] + " Event by " + doc["creator"],
            style: GoogleFonts.openSans(
              color: mainColor,
              fontSize: 15,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: [
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    doc["date"],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    doc["description"],
                    style: GoogleFonts.openSans(
                      color: secondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    child: emptyComing
                        ? Text("Be the first one to participate!")
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Participating:",
                                style: GoogleFonts.openSans(
                                  color: secondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Container(
                                height: 100,
                                width: 400,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: coming.length,
                                    itemBuilder: (context, index) {
                                      return Center(
                                        child: Text(
                                          coming[index],
                                          style: GoogleFonts.openSans(
                                            color: mainColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                            ],
                          ),
                  )
                ],
              )
            ],
          ),
          actions: <Widget>[
            Row(
              children: [
                alreadyParticipating
                    ? ElevatedButton(
                        onPressed: () async {
                          DocumentSnapshot doc2 = await FirebaseFirestore
                              .instance
                              .collection('events')
                              .doc(id)
                              .get();

                          DocumentReference docRef2 = doc2.reference;
                          List newList = doc2["coming"];

                          if (newList.contains(FirebaseApi.realUserLastData!
                                  .getUsername()) ==
                              false) {
                            newList.add(
                                FirebaseApi.realUserLastData!.getUsername());
                            docRef2.update(
                                {"coming": FieldValue.arrayUnion(newList)});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            primary: mainColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            textStyle: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        child: const Text('Participate'),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          DocumentSnapshot doc2 = await FirebaseFirestore
                              .instance
                              .collection('events')
                              .doc(id)
                              .get();

                          DocumentReference docRef2 = doc2.reference;
                          List newList = [];
                          newList
                              .add(FirebaseApi.realUserLastData!.getUsername());

                          if (newList.contains(FirebaseApi.realUserLastData!
                                  .getUsername()) ==
                              true) {
                            newList.add(
                                FirebaseApi.realUserLastData!.getUsername());
                            docRef2.update(
                                {"coming": FieldValue.arrayRemove(newList)});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            primary: mainColor,
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            textStyle: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        child: const Text("Can't make it.."),
                      ),
                Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      primary: mainColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      textStyle:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  child: const Text('Close'),
                ),
              ],
            )
          ],
        );
      });
}

Widget _buildPopupDialog2(BuildContext context, myEvent myevent) {
  return AlertDialog(
    title: Text(
        myevent.getEventType()! + " Event created by " + myevent.getCreator()!),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(myevent.getDate()!),
        Text(myevent.getDescription()!),
      ],
    ),
    actions: <Widget>[
      ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
            primary: mainColor,
            //padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            textStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        child: const Text('Go to Profile'),
      ),
    ],
  );
}

LocationData? position;
Location location = Location();
GeoPoint? geoP;
GM.LatLng? finalPositionCurrentUser;

void getLocation() async {
  position = await location.getLocation();
  geoP = GeoPoint(position!.latitude!, position!.longitude!);
  finalPositionCurrentUser = GM.LatLng(geoP!.latitude, geoP!.longitude);
}

class _GoogleMapState extends State<GoogleMap> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String htmlId = "7";

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(htmlId, (int viewId) {
      // another location

      final mapOptions = GM.MapOptions()
        ..zoom = 25
        ..center = GM.LatLng(userLocation!.latitude, userLocation!.longitude);

      final elem = DivElement()
        ..id = htmlId
        ..style.width = "100%"
        ..style.height = "100%"
        ..style.border = 'none';

      final image = GM.Icon()
        ..url = profileURL
        // This marker is 20 pixels wide by 32 pixels tall.
        // This marker is 20 pixels wide by 32 pixels tall.
        ..size = GM.Size(50, 50)

        // The origin for this0 image is 0,0.
        //..origin = GM.Point(0, 0)
        ..scaledSize = GM.Size(35, 35);
      // The anchor for this image is the base of the flagpole at 0,32.
      //..anchor = GM.Point(0, 100);

      final map = GM.GMap(elem, mapOptions);

      final marker = GM.Marker(GM.MarkerOptions()
        ..position = GM.LatLng(userLocation!.latitude, userLocation!.longitude)
        ..map = map
        //..label = label
        ..icon = image);

      // Another marker

      print("===>" + otherUsernames.length.toString());

      for (int i = 0; i < allEvents.length; i++) {
        final image = GM.Icon()
          ..url =
              "https://firebasestorage.googleapis.com/v0/b/overlook-64769.appspot.com/o/pixelpic200802278.jpg?alt=media&token=750c69ae-d66e-40ff-829c-8c551841ef7e"
          // This marker is 20 pixels wide by 32 pixels tall.
          ..size = GM.Size(50, 50)

          // The origin for this0 image is 0,0.
          //..origin = GM.Point(0, 0)
          ..scaledSize = GM.Size(35, 35);

        final marker = GM.Marker(GM.MarkerOptions()
          ..position = GM.LatLng(allEvents[i].getLocation()!.latitude,
              allEvents[i].getLocation()!.longitude)
          ..map = map
          //..label = label
          ..icon = image);

        marker.onClick.listen((event) {
          showDialog(
            context: context,
            builder: (BuildContext context) =>
                _buildPopupDialogEvent(context, allEvents[i].getID()!),
          );
        });
      }

      for (int i = 0; i < otherUsernames.length; i++) {
        final image = GM.Icon()
          ..url = otherProfileImages[i]
          // This marker is 20 pixels wide by 32 pixels tall.
          ..size = GM.Size(50, 50)

          // The origin for this0 image is 0,0.
          //..origin = GM.Point(0, 0)
          ..scaledSize = GM.Size(35, 35);

        final marker = GM.Marker(GM.MarkerOptions()
          ..position =
              GM.LatLng(otherLocations[i].latitude, otherLocations[i].longitude)
          ..map = map
          //..label = label
          ..icon = image);

        marker.onClick.listen((event) {
          showDialog(
            context: context,
            builder: (BuildContext context) =>
                _buildPopupDialog(context, otherUsernames[i], otherUIDS[i]),
          );
        });
      }
      marker.onClick.listen((event) {
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              _buildPopupDialog(context, username!, UID!),
        );
      });
      return elem;
    });

    return HtmlElementView(viewType: htmlId);
  }
}
