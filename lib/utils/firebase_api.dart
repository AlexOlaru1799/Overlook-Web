// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypt/crypt.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebaseStorage;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'package:location/location.dart';
import 'package:overlook/frontend/main_map.dart';
import 'package:overlook/frontend/otherProfile.dart';
import 'package:overlook/utils/constants.dart';
import 'package:overlook/utils/event.dart';
import 'package:overlook/utils/storage.dart';

import 'package:overlook/utils/user.dart';
import 'package:overlook/utils/utils.dart';

import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class FirebaseApi {
  static Stream? realUserStream;
  static String? realUserUID;
  static myUser? realUserLastData;
  static String? realUsername;
  static String? realUserImageURL;

  static Future<User?> signInWithGoogle() async {
    // Initialize Firebase

    User? user;

    // The `GoogleAuthProvider` can only be used while running on the web
    GoogleAuthProvider authProvider = GoogleAuthProvider();

    try {
      final UserCredential userCredential =
          await _auth.signInWithPopup(authProvider);

      user = userCredential.user;
    } catch (e) {
      print(e);
    }

    if (user != null) {
      realUserUID = user.uid;
      realUsername = user.displayName;
      realUserImageURL = user.photoURL;
    }

    return user;
  }

  static Future<UserCredential?> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    if (result.status == LoginStatus.success) {
      // Create a credential from the access token
      final OAuthCredential credential =
          FacebookAuthProvider.credential(result.accessToken!.token);
      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    }
    return null;
  }

  static Future<void> readDatabaseOnce(String UID) async {
    QuerySnapshot querySnap = await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where('UID', isEqualTo: UID)
        .get();
    QueryDocumentSnapshot doc = querySnap.docs[0];

    myUser temp = myUser(doc["username"], doc["email"], doc["location"],
        doc["FollowersNumber"], doc["FollowingNumber"]);

    temp.setProfileURL(doc["profileImage"]);
    temp.setBackgroulURL(doc["backgroundImage"]);
    temp.updateAbout(doc["about"]);

    realUserLastData = temp;
  }

  static Future<void> userBasicRegistration(
      String email, String pass, BuildContext context, String authType) async {
    UserCredential? userCredential;

    CollectionReference users =
        FirebaseFirestore.instance.collection('RegularUsers');

    var username = "";
    if (authType == "email") {
      try {
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: pass);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          Utils2.showAlertDialog(context, "Weak password",
              "The password provided is too weak.Try something that has 6+ characters");
          return;
        } else if (e.code == 'email-already-in-use') {
          Utils2.showAlertDialog(context, "Email already in use",
              "The account already exists for that email.");
          return;
        } else if (e.code == 'invalid-email') {
          Utils2.showAlertDialog(context, "Email format is wrong",
              "The email you provided is not in the right format! Check for spaces at the end and try again with this formmat emailname@emailprovider.region");
          return;
        }
        print(e.code);
      }
    } else if (authType == "facebook") {
      await FacebookAuth.i.webInitialize(
        appId: "482876533395869",
        cookie: true,
        xfbml: true,
        version: "v13.0",
      );

      UserCredential? user = await FirebaseApi.signInWithFacebook();
      print(user!.user!.email);

      pass = user.user!.uid.toString();

      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('RegularUsers')
          .where('email', isEqualTo: user.user!.email)
          .get();

      if (querySnap.docs.isEmpty == false) {
        Utils2.showAlertDialog(context, "Email already in use",
            "The account already exists for that email.");
        return;
      }

      print("===>" + user.user!.email!);

      pass = user.user!.uid.toString();
      username = user.user!.email!.split('@')[0];

      final hashedWithSalt = Crypt.sha256(pass);

      DateTime now = DateTime.now();

      LocationData location = await Utils2.getLocationWithPermissions(context);

      List<Map<String, dynamic>> list = <Map<String, dynamic>>[];

      String? profileURL = await Utils2.uploadImage(
          'assets/images/profilePlaceholder.png', username, "profile");

      String? backgroundURL = await Utils2.uploadImage(
          'assets/images/backgroundPlaceholder.jpg', username, "background");

      await users
          .doc(user.user!.uid.toString())
          .set({
            'username': username,
            'imagesNumber': 0,
            'password': hashedWithSalt.toString(),
            'salt': hashedWithSalt.salt.toString(),
            'email': user.user!.email.toString(),
            'UID': user.user!.uid.toString(),
            'FollowersNumber': 0,
            'FollowingNumber': 0,
            'creationDate': now,
            'location': GeoPoint(location.latitude!, location.longitude!),
            'followers': list,
            'following': list,
            'posts': list,
            'profileImage': profileURL,
            'backgroundImage': backgroundURL,
            'about': "not specified",
            'disabledLocation': false
          })
          .then((value) => print("User Added"))
          .catchError((error) => print("Failed to add user: $error"));

      await Future.delayed(const Duration(seconds: 1), () {});

      realUserUID = user.user!.uid.toString();

      readDatabaseOnce(realUserUID!);

      await Future.delayed(const Duration(seconds: 2), () {});

      otherProfileImages = await FirebaseApi.getProfileURLS();
      otherUIDS = await FirebaseApi.getUIDS();
      otherUsernames = await FirebaseApi.getUsernames();
      otherLocations = await FirebaseApi.getlocations();
      allEvents = await FirebaseApi.getEvents();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainMap()),
      );
    } else if (authType == "google") {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      User? user = await FirebaseApi.signInWithGoogle();

      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('RegularUsers')
          .where('email', isEqualTo: user!.email)
          .get();

      if (querySnap.docs.isEmpty == false) {
        Utils2.showAlertDialog(context, "Email already in use",
            "The account already exists for that email.");
        return;
      }

      print("===>" + user.email!);

      pass = user.uid.toString();
      username = user.email!.split('@')[0];

      final hashedWithSalt = Crypt.sha256(pass);

      DateTime now = DateTime.now();

      LocationData location = await Utils2.getLocationWithPermissions(context);

      List<Map<String, dynamic>> list = <Map<String, dynamic>>[];

      String? profileURL = await Utils2.uploadImage(
          'assets/images/profilePlaceholder.png', username, "profile");

      String? backgroundURL = await Utils2.uploadImage(
          'assets/images/backgroundPlaceholder.jpg', username, "background");

      await users
          .doc(user.uid.toString())
          .set({
            'username': username,
            'imagesNumber': 0,
            'password': hashedWithSalt.toString(),
            'salt': hashedWithSalt.salt.toString(),
            'email': user.email.toString(),
            'UID': user.uid.toString(),
            'FollowersNumber': 0,
            'FollowingNumber': 0,
            'creationDate': now,
            'location': GeoPoint(location.latitude!, location.longitude!),
            'followers': list,
            'following': list,
            'posts': list,
            'profileImage': profileURL,
            'backgroundImage': backgroundURL,
            'about': "not specified",
            'disabledLocation': false
          })
          .then((value) => print("User Added"))
          .catchError((error) => print("Failed to add user: $error"));

      await Future.delayed(const Duration(seconds: 1), () {});

      realUserUID = user.uid.toString();

      readDatabaseOnce(realUserUID!);

      await Future.delayed(const Duration(seconds: 2), () {});

      otherProfileImages = await FirebaseApi.getProfileURLS();
      otherUIDS = await FirebaseApi.getUIDS();
      otherUsernames = await FirebaseApi.getUsernames();
      otherLocations = await FirebaseApi.getlocations();
      allEvents = await FirebaseApi.getEvents();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainMap()),
      );
    }

    print("SUCCES!");

    username = userCredential!.user!.email.toString().split('@')[0];

    String? profileURL = await Utils2.uploadImage(
        'assets/images/profilePlaceholder.png', username, "profile");

    String? backgroundURL = await Utils2.uploadImage(
        'assets/images/backgroundPlaceholder.jpg', username, "background");

    final hashedWithSalt = Crypt.sha256(pass);

    DateTime now = DateTime.now();

    LocationData location = await Utils2.getLocationWithPermissions(context);

    print("lat : " +
        location.latitude.toString() +
        "  -   long : " +
        location.longitude.toString());

    List<Map<String, dynamic>> list = <Map<String, dynamic>>[];

    await users
        .doc(userCredential.user!.uid.toString())
        .set({
          'username': username,
          'imagesNumber': 0,
          'password': hashedWithSalt.toString(),
          'salt': hashedWithSalt.salt.toString(),
          'email': userCredential.user!.email.toString(),
          'UID': userCredential.user!.uid.toString(),
          'FollowersNumber': 0,
          'FollowingNumber': 0,
          'creationDate': now,
          'location': GeoPoint(location.latitude!, location.longitude!),
          'followers': list,
          'following': list,
          'posts': list,
          'profileImage': profileURL,
          'backgroundImage': backgroundURL,
          'about': "not specified",
          'disabledLocation': false
        })
        .then((value) => print("User Added"))
        .catchError((error) => print("Failed to add user: $error"));

    await Future.delayed(const Duration(seconds: 1), () {});

    realUserUID = userCredential.user!.uid;

    readDatabaseOnce(realUserUID!);

    await Future.delayed(const Duration(seconds: 2), () {});

    otherProfileImages = await FirebaseApi.getProfileURLS();
    otherUIDS = await FirebaseApi.getUIDS();
    otherUsernames = await FirebaseApi.getUsernames();
    otherLocations = await FirebaseApi.getlocations();
    allEvents = await FirebaseApi.getEvents();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainMap()),
    );
  }

  static Future<void> userBasicLogin(
      String email, String pass, BuildContext context, String authType) async {
    LocationData location = await Utils2.getLocationWithPermissions(context);
    UserCredential? userCredential;
    CollectionReference users =
        FirebaseFirestore.instance.collection('RegularUsers');
    if (authType == "email") {
      try {
        userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: pass);

        pass = userCredential.user!.uid.toString();
        String username = userCredential.user!.email!.split('@')[0];

        realUserStream = FirebaseFirestore.instance
            .collection('RegularUsers')
            .doc(userCredential.user!.uid)
            .snapshots();

        realUserUID = userCredential.user!.uid;

        await Future.delayed(const Duration(seconds: 1), () {});

        realUserUID = userCredential.user!.uid.toString();

        readDatabaseOnce(realUserUID!);

        await Future.delayed(const Duration(seconds: 2), () {});

        otherProfileImages = await FirebaseApi.getProfileURLS();
        otherUIDS = await FirebaseApi.getUIDS();
        otherUsernames = await FirebaseApi.getUsernames();
        otherLocations = await FirebaseApi.getlocations();
        allEvents = await FirebaseApi.getEvents();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainMap()),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          Utils2.showAlertDialog(context, "User not found",
              "The provided username does not exist in our database. Please create an account or verify your username.");
          return;
        } else if (e.code == 'wrong-password') {
          Utils2.showAlertDialog(
              context, "Wrong password", "The password provided is incorrect!");
          return;
        }
      }
    } else if (authType == "facebook") {
      // final LoginResult loginResult = await FacebookAuth.instance.login();

      // final OAuthCredential facebookAuthCredential =
      //     FacebookAuthProvider.credential(loginResult.accessToken!.token);

      // userCredential = await FirebaseAuth.instance
      //     .signInWithCredential(facebookAuthCredential);

      await FacebookAuth.i.webInitialize(
        appId: "482876533395869",
        cookie: true,
        xfbml: true,
        version: "v13.0",
      );

      UserCredential? user = await FirebaseApi.signInWithFacebook();
      print(user!.user!.email);

      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('RegularUsers')
          .where('email', isEqualTo: user.user!.email)
          .get();

      if (querySnap.docs.isEmpty == true) {
        Utils2.showAlertDialog(context, "Google account not registered",
            "The google account provided does not have an entry in the database. Please register it first!");
        return;
      }

      pass = user.user!.uid.toString();
      String username = user.user!.email!.split('@')[0];

      realUserStream = FirebaseFirestore.instance
          .collection('RegularUsers')
          .doc(user.user!.uid)
          .snapshots();

      realUserUID = user.user!.uid;

      await Future.delayed(const Duration(seconds: 1), () {});

      realUserUID = user.user!.uid.toString();

      readDatabaseOnce(realUserUID!);

      await Future.delayed(const Duration(seconds: 2), () {});

      otherProfileImages = await FirebaseApi.getProfileURLS();
      otherUIDS = await FirebaseApi.getUIDS();
      otherUsernames = await FirebaseApi.getUsernames();
      otherLocations = await FirebaseApi.getlocations();
      allEvents = await FirebaseApi.getEvents();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainMap()),
      );
    } else if (authType == "google") {
      String username = "";

      final GoogleSignIn googleSignIn = GoogleSignIn();

      User? user = await FirebaseApi.signInWithGoogle();

      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('RegularUsers')
          .where('email', isEqualTo: user!.email)
          .get();

      if (querySnap.docs.isEmpty == true) {
        Utils2.showAlertDialog(context, "Google account not registered",
            "The google account provided does not have an entry in the database. Please register it first!");
        return;
      }

      print("===>" + user.email!);

      pass = user.uid.toString();
      username = user.email!.split('@')[0];

      realUserStream = FirebaseFirestore.instance
          .collection('RegularUsers')
          .doc(user.uid)
          .snapshots();

      realUserUID = user.uid;

      Location location = Location();
      GeoPoint? geoP;

      LocationData position = await location.getLocation();
      geoP = GeoPoint(position.latitude!, position.longitude!);

      await FirebaseFirestore.instance
          .collection('RegularUsers')
          .doc(user.uid)
          .update({"location": geoP});

      print(geoP.latitude.toString() + " " + geoP.longitude.toString());

      await Future.delayed(const Duration(seconds: 1), () {});

      realUserUID = user.uid.toString();

      readDatabaseOnce(realUserUID!);

      await Future.delayed(const Duration(seconds: 2), () {});

      otherProfileImages = await FirebaseApi.getProfileURLS();
      otherUIDS = await FirebaseApi.getUIDS();
      otherUsernames = await FirebaseApi.getUsernames();
      otherLocations = await FirebaseApi.getlocations();
      allEvents = await FirebaseApi.getEvents();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainMap()),
      );
    }

    realUserStream = FirebaseFirestore.instance
        .collection('RegularUsers')
        .doc(userCredential!.user!.uid.toString())
        .snapshots();

    realUserUID = userCredential.user!.uid;

    await Future.delayed(const Duration(seconds: 2), () {});

    readDatabaseOnce(realUserUID!);

    await Future.delayed(const Duration(seconds: 2), () {});

    otherProfileImages = await FirebaseApi.getProfileURLS();
    otherUIDS = await FirebaseApi.getUIDS();
    otherUsernames = await FirebaseApi.getUsernames();
    otherLocations = await FirebaseApi.getlocations();
    allEvents = await FirebaseApi.getEvents();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainMap()),
    );
  }

  static Future<void> likePost(String postID) async {
    DocumentSnapshot documentSnapshot =
        await FirebaseFirestore.instance.collection('posts').doc(postID).get();

    int likes = documentSnapshot['likes'];

    List userLikes = documentSnapshot['userLikes'];

    if (userLikes.contains(FirebaseApi.realUserLastData!.getUsername())) {
      likes = likes - 1;
      userLikes.remove(FirebaseApi.realUserLastData!.getUsername());
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postID)
          .update({"likes": likes, "userLikes": userLikes});
    } else {
      likes = likes + 1;
      userLikes.add(FirebaseApi.realUserLastData!.getUsername());
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postID)
          .update({"likes": likes, "userLikes": userLikes});
    }
  }

  static Future<void> likeComment(String commentID, String postID) async {
    var doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postID)
        .collection("comments")
        .doc(commentID)
        .get();

    List likes = doc["usersLikes"];

    if (likes.contains(FirebaseApi.realUserLastData!.getUsername())) {
      likes.remove(FirebaseApi.realUserLastData!.getUsername());
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postID)
          .collection("comments")
          .doc(commentID)
          .update({"likes": FieldValue.increment(-1), "usersLikes": likes});
    } else {
      likes.add(FirebaseApi.realUserLastData!.getUsername());
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postID)
          .collection("comments")
          .doc(commentID)
          .update({"likes": FieldValue.increment(1), "usersLikes": likes});
    }
  }

  static Future<void> addComment(
      String postID, String comment, String username) async {
    List userLikes = [];
    var date = DateTime.now();
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postID)
        .collection("comments")
        .add({
      "authorID": username,
      "comment": comment,
      "createdAT": date,
      "likes": 0,
      "usersLikes": userLikes
    });
  }

  static Future<void> seeOtherProfile(String UID, BuildContext context) async {
    QuerySnapshot querySnap = await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where('UID', isEqualTo: UID)
        .get();
    QueryDocumentSnapshot docOther = querySnap.docs[0];
    DocumentReference docRef = docOther.reference;

    QuerySnapshot querySnap2 = await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where('UID', isEqualTo: realUserUID)
        .get();
    QueryDocumentSnapshot docReal = querySnap2.docs[0];
    DocumentReference docRef2 = docReal.reference;

    List following = docReal["following"];

    bool tempBoolForFollowUnfollow;

    await Future.delayed(const Duration(milliseconds: 50), () {});

    if (following.contains(docOther["username"]) == true) {
      tempBoolForFollowUnfollow = false;
    } else {
      tempBoolForFollowUnfollow = true;
    }

    await Future.delayed(const Duration(milliseconds: 50), () {});

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return OtherProfilePage(
              docOther["UID"], tempBoolForFollowUnfollow, docOther["username"]);
        },
      ),
    );
  }

  static Future<List> getFollowingList() async {
    QuerySnapshot querySnap = await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where('UID', isEqualTo: realUserUID)
        .get();
    QueryDocumentSnapshot doc = querySnap.docs[0];
    DocumentReference docRef = doc.reference;

    List temp = await doc["following"];

    return temp;
  }

  static Future<void> updateAboutForUser(String aboutNEW) async {
    QuerySnapshot querySnap = await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where('UID', isEqualTo: realUserUID)
        .get();
    QueryDocumentSnapshot doc = querySnap.docs[0];
    DocumentReference docRef = doc.reference;

    await docRef.update({
      "about": aboutNEW,
    });
  }

  static Future<void> addFollower(String userGuest) async {
    QuerySnapshot querySnap = await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where('username',
            isEqualTo: FirebaseApi.realUserLastData!.getUsername())
        .get();
    QueryDocumentSnapshot doc = querySnap.docs[0];
    DocumentReference docRef = doc.reference;

    List followingList = doc["following"];

    int followingNr = doc["FollowingNumber"];

    followingNr++;

    if (followingList.contains(userGuest) == false) {
      followingList.add(userGuest);
      docRef.update({"following": FieldValue.arrayUnion(followingList)});
      docRef.update({"FollowingNumber": followingNr});
    }

    QuerySnapshot querySnap2 = await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where('username', isEqualTo: userGuest)
        .get();
    QueryDocumentSnapshot doc2 = querySnap2.docs[0];
    DocumentReference docRef2 = doc2.reference;

    List followersList = doc2["followers"];

    int followersNr = doc2["FollowersNumber"];
    followersNr++;

    if (followersList.contains(FirebaseApi.realUserLastData!.getUsername()) ==
        false) {
      followersList.add(FirebaseApi.realUserLastData!.getUsername());
      docRef2.update({"followers": FieldValue.arrayUnion(followersList)});
      docRef2.update({"FollowersNumber": followersNr});
    }
  }

  static Future<void> removeFollower(String guestUser) async {
    QuerySnapshot querySnap = await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where('username',
            isEqualTo: FirebaseApi.realUserLastData!.getUsername())
        .get();
    QueryDocumentSnapshot doc = querySnap.docs[0];
    DocumentReference docRef = doc.reference;

    List followingList = [];
    followingList.add(guestUser);

    int followingNr = doc["FollowingNumber"];

    print("following - " + followingNr.toString() + "\n");

    followingNr--;

    if (followingList.contains(guestUser) == true) {
      followingList.add(guestUser);
      docRef.update({"following": FieldValue.arrayRemove(followingList)});
      docRef.update({"FollowingNumber": followingNr});
      print("following - " + followingNr.toString() + "\n");
    }

    QuerySnapshot querySnap2 = await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where('username', isEqualTo: guestUser)
        .get();
    QueryDocumentSnapshot doc2 = querySnap2.docs[0];
    DocumentReference docRef2 = doc2.reference;

    List followersList = doc2["followers"];
    int followersNr = doc2["FollowersNumber"];

    followersNr--;

    if (followersList.contains(FirebaseApi.realUserLastData!.getUsername()) ==
        true) {
      followersList.add(FirebaseApi.realUserLastData!.getUsername());
      docRef2.update({"followers": FieldValue.arrayRemove(followersList)});
      docRef2.update({"FollowersNumber": followersNr});
    }
  }

  static Future<void> createRoom(String currentUsername) async {
    QuerySnapshot querySnap = await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where('username', isEqualTo: currentUsername)
        .get();
    QueryDocumentSnapshot docOther = querySnap.docs[0];
    DocumentReference docOtherRef = docOther.reference;

    String otherUID = docOther["UID"];

    String roomName = realUserUID!.substring(0, 10) + otherUID.substring(0, 10);

    String roomNameVerification =
        otherUID.substring(0, 10) + realUserUID!.substring(0, 10);

    DocumentSnapshot check1 = await FirebaseFirestore.instance
        .collection("rooms")
        .doc(roomName)
        .get();

    DocumentSnapshot check2 = await FirebaseFirestore.instance
        .collection("rooms")
        .doc(roomNameVerification)
        .get();

    if (check1.exists == false && check2.exists == false) {
      DateTime now = DateTime.now();

      CollectionReference rooms =
          FirebaseFirestore.instance.collection('rooms');

      List list = [];

      list.add(realUserUID);
      list.add(otherUID);

      await rooms
          .doc(roomName)
          .set({
            'createdAT': now,
            'updatedAT': now,
            'UserUIDs': FieldValue.arrayUnion(list),
          })
          .then((value) => print("Room Created"))
          .catchError((error) => print("Failed to add room: $error"));

      FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomName)
          .collection('messages')
          .doc()
          .set({
        "authorID": realUserUID,
        "createdAT": now,
        "text": "TEST MESS",
        "emote": 0
      });

      // FirebaseFirestore.instance
      //     .collection('rooms')
      //     .doc(roomName)
      //     .collection('messages')
      //     .doc()
      //     .set({"authorID": realUserUID, "createdAT": now, "text": "Hello"});
    }
  }

  static Future<String> getRoomUID(String guestUID) async {
    String roomName = realUserUID!.substring(0, 10) + guestUID.substring(0, 10);

    String roomNameVerification =
        guestUID.substring(0, 10) + realUserUID!.substring(0, 10);

    DocumentSnapshot check1 = await FirebaseFirestore.instance
        .collection("rooms")
        .doc(roomName)
        .get();

    DocumentSnapshot check2 = await FirebaseFirestore.instance
        .collection("rooms")
        .doc(roomNameVerification)
        .get();

    if (check1.exists == true) {
      return roomName;
    } else if (check2.exists == true) {
      return roomNameVerification;
    } else {
      return "null";
    }
  }

  static Future<List<myEvent>> getEvents() async {
    List<myEvent> list = [];

    await FirebaseFirestore.instance.collection('events').get().then((value) {
      value.docs.forEach((element) {
        List tempList = element["coming"];
        myEvent temp = myEvent(
            element["creator"],
            element["date"],
            element["description"],
            element["eventType"],
            element["location"],
            tempList,
            element.id);
        list.add(temp);
      });
    });

    return list;
  }

  static Future<List<String>> getUIDS() async {
    List<String> list = [];

    await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where("username",
            isNotEqualTo: FirebaseApi.realUserLastData!.getUsername())
        .get()
        .then((value) {
      value.docs.forEach((element) {
        if (element["disabledLocation"] != true) {
          list.add(element["UID"]);
        }
      });
    });

    return list;
  }

  static Future<List<GeoPoint>> getlocations() async {
    List<GeoPoint> list = [];

    await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where("username",
            isNotEqualTo: FirebaseApi.realUserLastData!.getUsername())
        .get()
        .then((value) {
      value.docs.forEach((element) {
        if (element["disabledLocation"] != true) {
          list.add(element["location"]);
        }
      });
    });

    return list;
  }

  static Future<List<String>> getUsernames() async {
    List<String> list = [];

    await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where("username",
            isNotEqualTo: FirebaseApi.realUserLastData!.getUsername())
        .get()
        .then((value) {
      value.docs.forEach((element) {
        if (element["disabledLocation"] != true) {
          list.add(element["username"]);
        }
      });
    });

    print(list);
    return list;
  }

  static Future<List<String>> getProfileURLS() async {
    List<String> list = [];

    await FirebaseFirestore.instance
        .collection('RegularUsers')
        .where("username",
            isNotEqualTo: FirebaseApi.realUserLastData!.getUsername())
        .get()
        .then((value) {
      value.docs.forEach((element) {
        if (element["disabledLocation"] != true) {
          list.add(element["profileImage"]);
        }
      });
    });

    return list;
  }

  static Future<void> sendMessage(String message, String guestUID) async {
    String roomName = realUserUID!.substring(0, 10) + guestUID.substring(0, 10);

    String roomNameVerification =
        guestUID.substring(0, 10) + realUserUID!.substring(0, 10);

    DocumentSnapshot check1 = await FirebaseFirestore.instance
        .collection("rooms")
        .doc(roomName)
        .get();

    DocumentSnapshot check2 = await FirebaseFirestore.instance
        .collection("rooms")
        .doc(roomNameVerification)
        .get();

    DateTime now = DateTime.now();

    if (check1.exists == true) {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomName)
          .collection('messages')
          .doc()
          .set({
        "authorID": realUserUID,
        "createdAT": now,
        "text": message,
        "emote": 0
      });

      FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomName)
          .update({"lastMessage": now});
    } else if (check2.exists == true) {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomNameVerification)
          .collection('messages')
          .doc()
          .set({
        "authorID": realUserUID,
        "createdAT": now,
        "text": message,
        "emote": 0
      });

      FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomNameVerification)
          .update({"lastMessage": now});
    }
  }

  static void sendEmote(int value, String id_mess, String id_room) {
    FirebaseFirestore.instance
        .collection("rooms")
        .doc(id_room)
        .collection("messages")
        .doc(id_mess)
        .update({"emote": value});
  }
}
