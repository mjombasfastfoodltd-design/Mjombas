import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

const orange = Color(0xFFFF6B00);
const red = Color(0xFFD32F2F);
const dark = Color(0xFF171717);
const cream = Color(0xFFFFF7ED);

String money(num value) => 'KES ${value.toStringAsFixed(0)}';

class FoodItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageName;
  final String firestoreId;
  final double price;
  final double rating;
  final bool available;

  const FoodItem({
    this.id = '',
    this.name = '',
    this.description = '',
    this.category = 'Others',
    this.imageName = '',
    this.firestoreId = '',
    this.price = 0,
    this.rating = 0,
    this.available = true,
  });

  factory FoodItem.fromDoc(DocumentSnapshot d) {
    final raw = d.data();
    final x = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    return FoodItem(
      id: d.id,
      name: '${x['name'] ?? x['foodName'] ?? ''}'.trim(),
      description: '${x['description'] ?? ''}'.trim(),
      category: '${x['category'] ?? 'Others'}'.trim(),
      imageName: '${x['imageName'] ?? x['image'] ?? ''}'.trim(),
      firestoreId: d.id,
      price: asDouble(x['price']),
      rating: asDouble(x['rating']),
      available: x['available'] is bool ? x['available'] as bool : true,
    );
  }
}

final fallbackFoods = <FoodItem>[
  const FoodItem(name: 'Chicken', category: 'Chicken', price: 350, imageName: 'chicken.png', rating: 4.5, description: 'Tender chicken prepared MJOMBAS style.'),
  const FoodItem(name: 'Beef', category: 'Beef', price: 350, imageName: 'beef.png', rating: 4.4, description: 'Tasty beef served fresh.'),
  const FoodItem(name: 'Chips Plain', category: 'Chips', price: 180, imageName: 'chips_plain.png', rating: 4.3, description: 'Crispy golden chips.'),
  const FoodItem(name: 'Chips Masala', category: 'Chips', price: 250, imageName: 'chips_masala.png', rating: 4.5, description: 'Chips with MJOMBAS masala.'),
  const FoodItem(name: 'Chicken Biryani', category: 'Rice', price: 450, imageName: 'chicken_biryani.png', rating: 4.7, description: 'Aromatic chicken biryani.'),
  const FoodItem(name: 'Beef Biryani', category: 'Rice', price: 450, imageName: 'beef_biryani.png', rating: 4.6, description: 'Aromatic beef biryani.'),
  const FoodItem(name: 'Shawarma', category: 'Shawarma', price: 350, imageName: 'shawarma.png', rating: 4.6, description: 'Freshly prepared shawarma.'),
  const FoodItem(name: 'Pizza', category: 'Pizza', price: 700, imageName: 'pizza.png', rating: 4.5, description: 'Hot and fresh pizza.'),
  const FoodItem(name: 'Burger', category: 'Burgers', price: 350, imageName: 'burger.png', rating: 4.4, description: 'MJOMBAS burger.'),
  const FoodItem(name: 'Samosa', category: 'Snacks', price: 80, imageName: 'samosa.png', rating: 4.3, description: 'Crispy samosa.'),
  const FoodItem(name: 'Sausage', category: 'Snacks', price: 100, imageName: 'sausage.png', rating: 4.2, description: 'Grilled sausage.'),
  const FoodItem(name: 'Tea', category: 'Drinks', price: 80, imageName: 'tea.png', rating: 4.2, description: 'Hot Kenyan tea.'),
  const FoodItem(name: 'Coffee', category: 'Drinks', price: 120, imageName: 'coffee.png', rating: 4.2, description: 'Fresh coffee.'),
];

class CartLine {
  FoodItem food;
  int qty;
  CartLine(this.food, [this.qty = 1]);
  double get total => food.price * qty;
}

class CustomerProfile {
  final String fullName;
  final String phone;
  final String email;
  final String buildingName;
  final String deliveryAddress;

  const CustomerProfile({
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.buildingName = '',
    this.deliveryAddress = '',
  });

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'buildingName': buildingName,
        'deliveryAddress': deliveryAddress,
      };

  factory CustomerProfile.fromMap(Map<String, dynamic> x) => CustomerProfile(
        fullName: '${x['fullName'] ?? ''}',
        phone: '${x['phone'] ?? ''}',
        email: '${x['email'] ?? ''}',
        buildingName: '${x['buildingName'] ?? ''}',
        deliveryAddress: '${x['deliveryAddress'] ?? ''}',
      );
}

class DeliveryLocation {
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double deliveryFee;
  final String address;
  final String branchId;
  final String branchName;
  final double branchLatitude;
  final double branchLongitude;
  final int estimatedMinutes;

  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.deliveryFee,
    required this.address,
    required this.branchId,
    required this.branchName,
    required this.branchLatitude,
    required this.branchLongitude,
    required this.estimatedMinutes,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'distanceMeters': distanceMeters,
        'deliveryFee': deliveryFee,
        'address': address,
        'branchId': branchId,
        'branchName': branchName,
        'branchLatitude': branchLatitude,
        'branchLongitude': branchLongitude,
        'estimatedMinutes': estimatedMinutes,
      };

  factory DeliveryLocation.fromMap(Map<String, dynamic> x) => DeliveryLocation(
        latitude: _doubleValue(x['latitude']),
        longitude: _doubleValue(x['longitude']),
        distanceMeters: _doubleValue(x['distanceMeters']),
        deliveryFee: _doubleValue(x['deliveryFee']),
        address: '${x['address'] ?? ''}',
        branchId: '${x['branchId'] ?? ''}',
        branchName: '${x['branchName'] ?? ''}',
        branchLatitude: _doubleValue(x['branchLatitude']),
        branchLongitude: _doubleValue(x['branchLongitude']),
        estimatedMinutes: _intValue(x['estimatedMinutes']),
      );
}

class Branch {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  const Branch({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Branch.fromDoc(DocumentSnapshot d) {
    final raw = d.data();
    final x = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    double coordinate(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    final geo = x['location'];
    double lat = coordinate(x['latitude']);
    double lng = coordinate(x['longitude']);

    if (geo is GeoPoint) {
      lat = geo.latitude;
      lng = geo.longitude;
    }

    return Branch(
      id: d.id,
      name: '${x['name'] ?? x['branchName'] ?? 'MJOMBAS Branch'}'.trim(),
      latitude: lat,
      longitude: lng,
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'time': time,
        'read': read,
      };

  factory AppNotification.fromMap(Map<String, dynamic> x) => AppNotification(
        id: '${x['id'] ?? ''}',
        title: '${x['title'] ?? ''}',
        message: '${x['message'] ?? ''}',
        time: '${x['time'] ?? ''}',
        read: x['read'] == true,
      );
}

class OrderSummary {
  final String id;
  final DateTime? createdAt;
  final String deliveryAddress;
  final double total;
  final String branchName;
  final String status;
  final String paymentStatus;
  final String mpesaCode;
  final int estimatedMinutes;

  const OrderSummary({
    required this.id,
    required this.createdAt,
    required this.deliveryAddress,
    required this.total,
    required this.branchName,
    required this.status,
    required this.paymentStatus,
    required this.mpesaCode,
    required this.estimatedMinutes,
  });

  factory OrderSummary.fromDoc(DocumentSnapshot d) {
    final raw = d.data();
    final x = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    DateTime? date;
    final created = x['createdAt'];
    if (created is Timestamp) {
      date = created.toDate();
    } else if (created is DateTime) {
      date = created;
    } else {
      final text = '${x['orderDate'] ?? ''}'.trim();
      date = DateTime.tryParse(text);
    }

    final total = _doubleValue(
      x['grandTotal'] ?? x['totalPrice'] ?? x['total'] ?? x['subtotal'],
    );

    return OrderSummary(
      id: '${x['orderNumber'] ?? d.id}',
      createdAt: date,
      deliveryAddress: '${x['deliveryAddress'] ?? x['address'] ?? ''}',
      total: total,
      branchName: '${x['branchName'] ?? ''}',
      status: '${x['status'] ?? 'Payment Pending'}',
      paymentStatus: '${x['paymentStatus'] ?? 'PENDING'}',
      mpesaCode: '${x['mpesaCode'] ?? ''}',
      estimatedMinutes: _intValue(x['estimatedMinutes'], fallback: 30),
    );
  }
}

class LocationService {
  static Future<Position> currentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Location services are disabled. Turn on GPS and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is permanently denied. Enable it in Android Settings.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  static Future<List<Branch>> branches() async {
    final firestore = FirebaseFirestore.instance;

    QuerySnapshot snap;
    try {
      snap = await firestore
          .collection('branches')
          .where('active', isEqualTo: true)
          .get();
    } catch (_) {
      snap = await firestore.collection('branches').get();
    }

    final result = snap.docs
        .map(Branch.fromDoc)
        .where((b) => b.latitude != 0 && b.longitude != 0)
        .toList();

    return result;
  }

  static Branch nearest(List<Branch> branches, double latitude, double longitude) {
    if (branches.isEmpty) {
      throw Exception('No active MJOMBAS branch was found.');
    }

    Branch best = branches.first;
    var bestDistance = distance(
      best.latitude,
      best.longitude,
      latitude,
      longitude,
    );

    for (final branch in branches.skip(1)) {
      final d = distance(
        branch.latitude,
        branch.longitude,
        latitude,
        longitude,
      );
      if (d < bestDistance) {
        best = branch;
        bestDistance = d;
      }
    }

    return best;
  }

  static double distance(
    double branchLatitude,
    double branchLongitude,
    double userLatitude,
    double userLongitude,
  ) {
    return Geolocator.distanceBetween(
      branchLatitude,
      branchLongitude,
      userLatitude,
      userLongitude,
    );
  }

  static double deliveryFee(double meters) {
    if (meters <= 600) return 0;
    if (meters <= 1000) return 100;
    if (meters <= 2000) return 200;

    final additionalStartedKm = ((meters - 2000) / 1000).ceil();
    return 200 + (additionalStartedKm * 100);
  }

  static int estimatedMinutes(double meters) {
    if (meters <= 600) return 20;
    if (meters <= 2000) return 30;
    return 30 + (((meters - 2000) / 1000).ceil() * 10);
  }

  static Future<String> reverseGeocode(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=jsonv2&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'MJOMBAS/1.0 (delivery location)',
      );
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Reverse geocoding failed.');
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      final display = '${json['display_name'] ?? ''}'.trim();
      if (display.isEmpty) throw Exception('Address unavailable.');
      return display;
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<LatLng>> route(
    double branchLatitude,
    double branchLongitude,
    double userLatitude,
    double userLongitude,
  ) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$branchLongitude,$branchLatitude;$userLongitude,$userLatitude'
      '?overview=full&geometries=geojson',
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'MJOMBAS/1.0 (delivery routing)',
      );
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Routing failed.');
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      final routes = json['routes'];
      if (routes is! List || routes.isEmpty) {
        throw Exception('No route found.');
      }

      final coordinates = routes.first['geometry']?['coordinates'];
      if (coordinates is! List) throw Exception('Route geometry unavailable.');

      return coordinates
          .whereType<List>()
          .where((p) => p.length >= 2)
          .map(
            (p) => LatLng(
              (p[1] as num).toDouble(),
              (p[0] as num).toDouble(),
            ),
          )
          .toList();
    } finally {
      client.close(force: true);
    }
  }
}

class PhoneService {
  static Future<void> callMjombas() async {
    final uri = Uri.parse('tel:0704646628');
    await launchUrl(uri);
  }
}

class AppState extends ChangeNotifier {
  final List<CartLine> lines = [];
  final Set<String> favorites = {};
  final List<AppNotification> notifications = [];

  List<FoodItem> foods = [];
  bool loading = true;
  String? menuError;
  DeliveryLocation? location;
  CustomerProfile profile = const CustomerProfile();

  int get count => lines.fold(0, (sum, line) => sum + line.qty);
  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);
  double get deliveryFee => location?.deliveryFee ?? 0;
  double get total => subtotal + deliveryFee;
  int get unread => notifications.where((n) => !n.read).length;

  bool isFavorite(FoodItem food) {
    final key = food.firestoreId.isNotEmpty ? food.firestoreId : food.name;
    return favorites.contains(key);
  }

  void add(FoodItem food) {
    // Items shown in the customer menu are addable. Keep the cart action
    // independent of a stale availability flag from a previous cache.
    final cartFood = food.available ? food : FoodItem(
      id: food.id,
      name: food.name,
      description: food.description,
      category: food.category,
      imageName: food.imageName,
      firestoreId: food.firestoreId,
      price: food.price,
      rating: food.rating,
      available: true,
    );

    final index = lines.indexWhere(
      (line) => line.food.firestoreId.isNotEmpty && food.firestoreId.isNotEmpty
          ? line.food.firestoreId == food.firestoreId
          : line.food.name == food.name,
    );

    if (index < 0) {
      lines.add(CartLine(cartFood));
    } else {
      lines[index].qty++;
    }
    notifyListeners();
    _persist();
  }

  void minus(CartLine line) {
    if (line.qty > 1) {
      line.qty--;
    } else {
      lines.remove(line);
    }
    notifyListeners();
    _persist();
  }

  void plus(CartLine line) {
    line.qty++;
    notifyListeners();
    _persist();
  }

  void remove(CartLine line) {
    lines.remove(line);
    notifyListeners();
    _persist();
  }

  void clearCart() {
    lines.clear();
    notifyListeners();
    _persist();
  }

  void toggleFav(FoodItem food) {
    final key = food.firestoreId.isNotEmpty ? food.firestoreId : food.name;
    if (!favorites.add(key)) favorites.remove(key);
    notifyListeners();
    _persist();
  }

  void setLocation(DeliveryLocation value) {
    location = value;
    notifyListeners();
    _persist();
  }

  Future<void> saveProfile(CustomerProfile value) async {
    profile = value;
    notifyListeners();
    await _persist();
  }

  Future<void> addNotification(String title, String message) async {
    notifications.insert(
      0,
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        message: message,
        time: DateTime.now().toIso8601String(),
      ),
    );
    notifyListeners();
    await _persist();
  }

  void markRead(AppNotification notification) {
    notification.read = true;
    notifyListeners();
    _persist();
  }

  void markAllRead() {
    for (final notification in notifications) {
      notification.read = true;
    }
    notifyListeners();
    _persist();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final profileJson = prefs.getString('mjombas_profile');
    if (profileJson != null) {
      try {
        profile = CustomerProfile.fromMap(
          Map<String, dynamic>.from(jsonDecode(profileJson)),
        );
      } catch (_) {}
    }

    final locationJson = prefs.getString('mjombas_location');
    if (locationJson != null) {
      try {
        location = DeliveryLocation.fromMap(
          Map<String, dynamic>.from(jsonDecode(locationJson)),
        );
      } catch (_) {}
    }

    final notificationsJson = prefs.getString('mjombas_notifications');
    if (notificationsJson != null) {
      try {
        final raw = jsonDecode(notificationsJson);
        if (raw is List) {
          notifications
            ..clear()
            ..addAll(
              raw.whereType<Map>().map(
                    (x) => AppNotification.fromMap(
                      Map<String, dynamic>.from(x),
                    ),
                  ),
            );
        }
      } catch (_) {}
    }

    favorites
      ..clear()
      ..addAll(prefs.getStringList('mjombas_favorites') ?? const []);

    final cartJson = prefs.getString('mjombas_cart');
    if (cartJson != null && cartJson.isNotEmpty) {
      try {
        final raw = jsonDecode(cartJson);
        if (raw is List) {
          lines
            ..clear()
            ..addAll(raw.whereType<Map>().map((x) => CartLine(
                  FoodItem(
                    id: '${x['id'] ?? ''}',
                    name: '${x['name'] ?? ''}',
                    description: '${x['description'] ?? ''}',
                    category: '${x['category'] ?? 'Others'}',
                    imageName: '${x['imageName'] ?? ''}',
                    firestoreId: '${x['firestoreId'] ?? x['id'] ?? ''}',
                    price: _doubleValue(x['price']),
                    rating: _doubleValue(x['rating']),
                    available: true,
                  ),
                  _intValue(x['qty'], fallback: 1),
                )).where((line) => line.food.name.trim().isNotEmpty && line.qty > 0));
        }
      } catch (_) {
        lines.clear();
      }
    }

    notifyListeners();
  }

  Future<void> loadFoods() async {
    loading = true;
    menuError = null;

    // Always give the UI an immediate menu so a slow/unreachable
    // Firestore request can never leave the customer on a spinner.
    if (foods.isEmpty) {
      foods = List<FoodItem>.from(fallbackFoods);
    }
    notifyListeners();

    try {
      // Anonymous Firebase authentication can take several seconds on a
      // fresh install. Do not query Firestore before the auth session exists.
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.authStateChanges()
            .firstWhere((user) => user != null)
            .timeout(const Duration(seconds: 30));
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('menu')
          .get()
          .timeout(const Duration(seconds: 30));

      final loaded = snapshot.docs
          .map(FoodItem.fromDoc)
          .where((food) => food.name.trim().isNotEmpty)
          .toList();

      if (loaded.isNotEmpty) {
        foods = loaded;
      } else {
        foods = List<FoodItem>.from(fallbackFoods);
        menuError = 'Showing the local menu. No menu items are in Firebase yet.';
      }
    } catch (e) {
      foods = foods.isNotEmpty
          ? foods
          : List<FoodItem>.from(fallbackFoods);
      debugPrint('MJOMBAS Firestore menu load failed: $e');
      menuError = 'Firebase menu could not be loaded: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'mjombas_profile',
        jsonEncode(profile.toMap()),
      );

      if (location != null) {
        await prefs.setString(
          'mjombas_location',
          jsonEncode(location!.toMap()),
        );
      }

      await prefs.setString(
        'mjombas_notifications',
        jsonEncode(notifications.map((n) => n.toMap()).toList()),
      );

      await prefs.setStringList(
        'mjombas_favorites',
        favorites.toList(),
      );

      await prefs.setString(
        'mjombas_cart',
        jsonEncode(lines.map((line) => {
          'id': line.food.id,
          'name': line.food.name,
          'description': line.food.description,
          'category': line.food.category,
          'imageName': line.food.imageName,
          'firestoreId': line.food.firestoreId,
          'price': line.food.price,
          'rating': line.food.rating,
          'qty': line.qty,
        }).toList()),
      );
    } catch (_) {}
  }
}

final appState = AppState();

double _doubleValue(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? fallback;
}

int _intValue(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}
