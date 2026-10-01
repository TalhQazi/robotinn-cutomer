import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/area_helper.dart';

class OrderItemModel {
  final String name;
  final String category;
  final int quantity;
  final double price;
  final String store;
  final bool? isChecked;

  OrderItemModel({
    required this.name,
    this.category = 'General',
    this.quantity = 1,
    this.price = 0.0,
    this.store = '',
    this.isChecked = false,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      name: map['name']?.toString() ?? map['text']?.toString() ?? map['itemName']?.toString() ?? 'Item',
      category: map['category']?.toString() ?? 'General',
      quantity: (map['quantity'] as num?)?.toInt() ?? (map['qty'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? (map['cost'] as num?)?.toDouble() ?? (map['amount'] as num?)?.toDouble() ?? 0.0,
      store: map['store']?.toString() ?? map['selectedStore']?.toString() ?? '',
      isChecked: map['isChecked'] == true || map['checked'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'price': price,
      'store': store,
      'isChecked': isChecked,
    };
  }
}

class OrderModel {
  final String id;
  final String orderId;
  final String status;
  final String store;
  final String pickup;
  final String dropoff;
  final String area;
  final String notes;
  final double total;
  final double originalEstimate;
  final double estimatedSubtotal;
  final List<OrderItemModel> items;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? rider;
  final Map<String, dynamic>? bill;
  final Map<String, dynamic>? rating;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? riderLocation;
  final Map<String, dynamic>? adjustmentData;
  final Map<String, dynamic>? adjustmentNegotiation;
  final Map<String, dynamic>? billDispute;
  final String? cancellationReason;
  final dynamic createdAt;
  final dynamic updatedAt;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.status,
    this.store = '',
    this.pickup = '',
    this.dropoff = '',
    this.area = '',
    this.notes = '',
    this.total = 0.0,
    this.originalEstimate = 0.0,
    this.estimatedSubtotal = 0.0,
    this.items = const [],
    this.customer,
    this.rider,
    this.bill,
    this.rating,
    this.location,
    this.riderLocation,
    this.adjustmentData,
    this.adjustmentNegotiation,
    this.billDispute,
    this.cancellationReason,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawItems = map['items'];
    List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => i is Map<String, dynamic> ? OrderItemModel.fromMap(i) : null)
          .whereType<OrderItemModel>()
          .toList();
    }

    final double est = (map['originalEstimate'] as num?)?.toDouble() ??
        (map['estimatedSubtotal'] as num?)?.toDouble() ??
        (map['estimatedPrice'] as num?)?.toDouble() ??
        (map['budget'] as num?)?.toDouble() ??
        0.0;

    final double tot = (map['total'] as num?)?.toDouble() ??
        (map['amount'] as num?)?.toDouble() ??
        (map['price'] as num?)?.toDouble() ??
        est;

    final dropoffStr = map['dropoff']?.toString() ?? map['address']?.toString() ?? '';
    final areaStr = map['area']?.toString() ?? '';

    // Robust parsing for delivery location (GeoPoint or Map)
    Map<String, dynamic>? parsedLocation;
    final rawLoc = map['location'] ?? (map['customer'] is Map ? (map['customer'] as Map)['location'] : null) ?? map['destinationCoords'];
    if (rawLoc is GeoPoint) {
      parsedLocation = {'lat': rawLoc.latitude, 'lng': rawLoc.longitude};
    } else if (rawLoc is Map) {
      final lat = (rawLoc['lat'] ?? rawLoc['latitude'] as num?)?.toDouble();
      final lng = (rawLoc['lng'] ?? rawLoc['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        parsedLocation = {'lat': lat, 'lng': lng};
      }
    }
    if (parsedLocation == null && (areaStr.isNotEmpty || dropoffStr.isNotEmpty)) {
      final resolved = AreaHelper.resolveAreaCoords(areaStr.isNotEmpty ? areaStr : dropoffStr);
      if (resolved != null) {
        parsedLocation = {'lat': resolved['lat'], 'lng': resolved['lng']};
      }
    }

    // Robust parsing for rider live location (GeoPoint or Map)
    Map<String, dynamic>? parsedRiderLoc;
    final rawRiderLoc = map['riderLocation'] ?? (map['rider'] is Map ? (map['rider'] as Map)['location'] : null);
    if (rawRiderLoc is GeoPoint) {
      parsedRiderLoc = {'lat': rawRiderLoc.latitude, 'lng': rawRiderLoc.longitude};
    } else if (rawRiderLoc is Map) {
      final lat = (rawRiderLoc['lat'] ?? rawRiderLoc['latitude'] as num?)?.toDouble();
      final lng = (rawRiderLoc['lng'] ?? rawRiderLoc['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        parsedRiderLoc = {'lat': lat, 'lng': lng};
      }
    }

    return OrderModel(
      id: docId ?? map['id']?.toString() ?? map['orderId']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? docId ?? '',
      status: map['status']?.toString() ?? 'pending',
      store: map['store']?.toString() ?? map['pickup']?.toString() ?? '',
      pickup: map['pickup']?.toString() ?? map['store']?.toString() ?? '',
      dropoff: dropoffStr,
      area: areaStr,
      notes: map['notes']?.toString() ?? '',
      total: tot,
      originalEstimate: est,
      estimatedSubtotal: est,
      items: parsedItems,
      customer: map['customer'] is Map ? Map<String, dynamic>.from(map['customer']) : null,
      rider: map['rider'] is Map ? Map<String, dynamic>.from(map['rider']) : null,
      bill: map['bill'] is Map ? Map<String, dynamic>.from(map['bill']) : null,
      rating: map['rating'] is Map ? Map<String, dynamic>.from(map['rating']) : null,
      location: parsedLocation,
      riderLocation: parsedRiderLoc,
      adjustmentData: map['adjustmentData'] is Map ? Map<String, dynamic>.from(map['adjustmentData']) : null,
      adjustmentNegotiation: map['adjustmentNegotiation'] is Map ? Map<String, dynamic>.from(map['adjustmentNegotiation']) : null,
      billDispute: map['billDispute'] is Map ? Map<String, dynamic>.from(map['billDispute']) : null,
      cancellationReason: map['cancellationReason']?.toString(),
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'status': status,
      'store': store,
      'pickup': pickup,
      'dropoff': dropoff,
      'area': area,
      'notes': notes,
      'total': total,
      'originalEstimate': originalEstimate,
      'estimatedSubtotal': estimatedSubtotal,
      'items': items.map((i) => i.toMap()).toList(),
      'customer': customer,
      'rider': rider,
      'bill': bill,
      'rating': rating,
      'location': location,
      'riderLocation': riderLocation,
      'adjustmentData': adjustmentData,
      'adjustmentNegotiation': adjustmentNegotiation,
      'billDispute': billDispute,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }
}
