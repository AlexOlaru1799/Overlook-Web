import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

class myUser {
  String? username;
  String? email;
  GeoPoint? location;

  int? followers;
  int? following;
  String? about;

  String? profileURL;
  String? backgroundURL;

  myUser.empty() {}

  myUser(String _username, String _email, GeoPoint _location, int _followers,
      int _following) {
    this.username = _username;
    this.email = _email;
    this.location = _location;
    this.followers = _followers;
    this.following = _following;
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'followers': followers,
    };
  }

  void setEmail(String email) {
    this.email = email;
  }

  void setUsername(String _username) {
    this.username = _username;
  }

  String? getUsername() {
    return this.username;
  }

  String? getEmail() {
    return this.email;
  }

  int? getFollowers() {
    return this.followers;
  }

  int? getFollowing() {
    return this.following;
  }

  GeoPoint? getLocation() {
    return this.location;
  }

  String? getLocationString() {
    return this.location.toString();
  }

  void changeDetailsData(String username, String email) {
    this.username = username;
    this.email = email;
  }

  void updateFollowing(int newFollowers) {
    this.following = newFollowers;
  }

  void updateAbout(String about) {
    this.about = about;
  }

  String? getAbout() {
    return this.about;
  }

  void setProfileURL(String url) {
    this.profileURL = url;
  }

  String? getProfileURL() {
    return this.profileURL;
  }

  void setBackgroulURL(String url) {
    this.backgroundURL = url;
  }

  String? getBackgrundURL() {
    return this.backgroundURL;
  }
}
