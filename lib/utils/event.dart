import 'package:cloud_firestore/cloud_firestore.dart';

class myEvent {
  String? creator;
  String? date;
  String? description;
  String? eventType;
  GeoPoint? location;
  String? id;
  List coming = [];

  myEvent(String creator, String date, String description, String eventType,
      GeoPoint location, List coming, String id) {
    this.creator = creator;
    this.date = date;
    this.description = description;
    this.eventType = eventType;
    this.location = location;
    this.coming = coming;
    this.id = id;
  }

  String? getCreator() {
    return this.creator;
  }

  String? getDate() {
    return this.date;
  }

  String? getDescription() {
    return this.description;
  }

  String? getEventType() {
    return this.eventType;
  }

  String? getID() {
    return this.id;
  }

  GeoPoint? getLocation() {
    return this.location;
  }

  List getComing() {
    return this.coming;
  }
}
