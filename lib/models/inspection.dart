class Inspection {
  final int? id;
  final String propertyName;
  final String description;
  final String rating;
  final double latitude;
  final double longitude;
  final String dateCreated;
  final List<String> photos;

  Inspection({
    this.id,
    required this.propertyName,
    required this.description,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.dateCreated,
    required this.photos,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_name': propertyName,
      'description': description,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'date_created': dateCreated,
      'photos': photos.join(','), 
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      id: map['id'],
      propertyName: map['property_name'],
      description: map['description'],
      rating: map['rating'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      dateCreated: map['date_created'],
      photos: (map['photos'] as String).split(','),
    );
  }
}
