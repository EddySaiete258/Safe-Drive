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
  DocumentReference<Map<String, dynamic>>? user;
  List<String>? images;

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
    [this.images]
  );

  static toMap(RoadBlock roadBlock) {
    return {
      roadBlock.id ?? 'id': roadBlock.id,
      'latitude': roadBlock.latitude,
      'longitude': roadBlock.longitude,
      roadBlock.description ?? 'description': roadBlock.description,
      'location': roadBlock.location,
      'type': roadBlock.type,
      'duration': roadBlock.duration,
      'marker': roadBlock.markerId,
      'user': roadBlock.user,
      'images': roadBlock.images,
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
      map['user'],
      map['images'] != null ? List<String>.from(map['images']) : null,
    );
  }
}
