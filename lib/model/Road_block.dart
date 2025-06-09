import 'package:cloud_firestore/cloud_firestore.dart';

class RoadBlock {
  String? id;
  String latitude;
  String longitude;
  String? description;
  String location;
  String type;
  String duration;
  String markerId;
  DocumentReference<Map<String, dynamic>> user;

  RoadBlock(
    this.id,
    this.latitude,
    this.longitude,
    this.description,
    this.location,
    this.type,
    this.duration,
    this.markerId,
    this.user,
  );

  static toMap(RoadBlock roadBlock) {
    return {
      'id': roadBlock.id,
      'latitude': roadBlock.latitude,
      'longitude': roadBlock.longitude,
      'description': roadBlock.description,
      'location': roadBlock.location,
      'type': roadBlock.type,
      'duration': roadBlock.duration,
      'marker': roadBlock.markerId,
      'user': roadBlock.user
    };
  }

  factory RoadBlock.fromMap(Map<String, dynamic> map) {
    return RoadBlock(
      map['id'],
      map['latitude'],
      map['longitude'],
      map['description'],
      map['location'],
      map['type'],
      map['duration'],
      map['marker'],
      map['user']
    );
  }
}
