class AddressModel {
  final String id;
  final String title;
  final String address;
  final String? fullAddress;
  final String? formattedAddress;
  final bool isCurrentLocation;
  final double? lat;
  final double? lng;
  final String? createdAt;

  AddressModel({
    required this.id,
    required this.title,
    required this.address,
    this.fullAddress,
    this.formattedAddress,
    this.isCurrentLocation = false,
    this.lat,
    this.lng,
    this.createdAt,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    double? latVal;
    double? lngVal;

    if (map['location'] is Map) {
      latVal = (map['location']['lat'] as num?)?.toDouble() ?? (map['location']['latitude'] as num?)?.toDouble();
      lngVal = (map['location']['lng'] as num?)?.toDouble() ?? (map['location']['longitude'] as num?)?.toDouble();
    } else {
      latVal = (map['lat'] as num?)?.toDouble() ?? (map['latitude'] as num?)?.toDouble();
      lngVal = (map['lng'] as num?)?.toDouble() ?? (map['longitude'] as num?)?.toDouble();
    }

    return AddressModel(
      id: map['id']?.toString() ?? map['addressId']?.toString() ?? map['_id']?.toString() ?? 'ADR-${DateTime.now().millisecondsSinceEpoch}',
      title: map['title']?.toString() ?? 'Saved Address',
      address: map['address']?.toString() ?? '',
      fullAddress: map['fullAddress']?.toString() ?? map['address']?.toString(),
      formattedAddress: map['formattedAddress']?.toString() ?? map['address']?.toString(),
      isCurrentLocation: map['isCurrentLocation'] == true,
      lat: latVal,
      lng: lngVal,
      createdAt: map['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'addressId': id,
      'title': title,
      'address': address,
      'fullAddress': fullAddress ?? address,
      'formattedAddress': formattedAddress ?? address,
      'isCurrentLocation': isCurrentLocation,
      'location': lat != null && lng != null ? {'lat': lat, 'lng': lng} : null,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }
}
