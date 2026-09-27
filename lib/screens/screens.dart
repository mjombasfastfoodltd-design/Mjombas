import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mjombas/app_state.dart';

const String _mpesaTill = '3429801';
const String _businessName = 'MJOMBAS FAST FOOD';
const String _phone = '0704646628';

String _foodAsset(FoodItem food) {
  var name = food.imageName.trim().split('/').last;
  if (name.isEmpty) {
    name = food.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
  if (!name.contains('.')) name = '$name.png';
  return 'assets/images/$name';
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String text;
  const StatusChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final rejected = text.toUpperCase().contains('REJECT');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: rejected ? Colors.red.withValues(alpha: .10) : orange.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: rejected ? Colors.red : orange,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String a;
  final String b;
  final bool bold;

  const SummaryRow(this.a, this.b, {super.key, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final weight = bold ? FontWeight.w900 : FontWeight.w500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(a, style: TextStyle(fontWeight: weight)),
          const Spacer(),
          Text(
            b,
            style: TextStyle(
              fontWeight: weight,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  String category = 'All';
  String query = '';
  late final TextEditingController search;

  @override
  void initState() {
    super.initState();
    search = TextEditingController();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>{
      'All',
      ...appState.foods
          .map((e) => e.category)
          .where((e) => e.trim().isNotEmpty),
    }.toList();

    final foods = appState.foods.where((food) {
      final q = query.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          food.name.toLowerCase().contains(q) ||
          food.category.toLowerCase().contains(q);
      final matchesCategory =
          category == 'All' || food.category == category;
      return matchesQuery && matchesCategory;
    }).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 215,
          backgroundColor: orange,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [red, orange],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'DELIVERING TO',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Your current delivery location',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            color: Colors.white,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LocationScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.location_on),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: search,
                        onChanged: (value) => setState(() => query = value),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search food',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
              icon: Badge(
                isLabelVisible: appState.unread > 0,
                child: const Icon(Icons.notifications_none),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 58,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final value = categories[index];
                return ChoiceChip(
                  label: Text(value),
                  selected: category == value,
                  onSelected: (_) => setState(() => category = value),
                  selectedColor: orange,
                  labelStyle: TextStyle(
                    color: category == value ? Colors.white : dark,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
        ),
        if (appState.menuError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                appState.menuError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Featured',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        // Never hide an already available menu behind the Firebase spinner.
        // The AppState supplies fallback foods immediately and refreshes them
        // from Firestore in the background.
        if (foods.isEmpty && appState.loading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        if (!appState.loading && foods.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: EmptyState(
                icon: Icons.restaurant_menu,
                title: 'No food available',
                message: 'There are no meals matching your search.',
              ),
            ),
          ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => FoodCard(food: foods[index]),
            childCount: foods.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
      ],
    );
  }
}

class FoodCard extends StatelessWidget {
  final FoodItem food;
  const FoodCard({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final key = food.firestoreId.isNotEmpty ? food.firestoreId : food.name;
        final favourite = appState.favorites.contains(key);

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FoodDetailsScreen(food: food),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _foodAsset(food),
                      width: 105,
                      height: 105,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 105,
                        height: 105,
                        color: Colors.black12,
                        child: const Icon(Icons.restaurant, size: 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          food.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Text(
                              money(food.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: favourite ? 'Remove favourite' : 'Favourite',
                              onPressed: () => appState.toggleFav(food),
                              icon: Icon(
                                favourite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: favourite ? orange : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FoodDetailsScreen extends StatefulWidget {
  final FoodItem food;
  const FoodDetailsScreen({super.key, required this.food});

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsState();
}

class _FoodDetailsState extends State<FoodDetailsScreen> {
  int qty = 1;

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final key = food.firestoreId.isNotEmpty ? food.firestoreId : food.name;
    final favourite = appState.favorites.contains(key);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food details'),
        actions: [
          IconButton(
            onPressed: () {
              appState.toggleFav(food);
              setState(() {});
            },
            icon: Icon(
              favourite ? Icons.favorite : Icons.favorite_border,
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          Image.asset(
            _foodAsset(food),
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 300,
              color: Colors.black12,
              child: const Icon(Icons.fastfood, size: 80),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  food.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  food.category,
                  style: const TextStyle(
                    color: orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  money(food.price),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    IconButton(
                      onPressed: qty > 1 ? () => setState(() => qty--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$qty',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => qty++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        for (var i = 0; i < qty; i++) {
                          appState.add(food);
                        }
                        Navigator.pop(context);
                      },
                      child: Text('ADD • ${money(food.price * qty)}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Compatibility name used by the earlier screen implementation.
class FoodDetail extends StatelessWidget {
  final FoodItem food;
  const FoodDetail({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    return FoodDetailsScreen(food: food);
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final foods = appState.foods.where(appState.isFavorite).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Your Favorites')),
          body: foods.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'No favourites yet',
                  message: 'Tap the heart on any meal to save it here.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: foods.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: .70,
                  ),
                  itemBuilder: (_, index) => FoodCard(food: foods[index]),
                ),
        );
      },
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (appState.lines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Cart')),
        body: const EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Your cart is empty',
          message: 'Add something delicious from the menu.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: appState.lines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final line = appState.lines[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            _foodAsset(line.food),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.restaurant, size: 50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.food.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              Text(money(line.total)),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => appState.minus(line),
                                    icon: const Icon(
                                        Icons.remove_circle_outline),
                                  ),
                                  Text(
                                    '${line.qty}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900),
                                  ),
                                  IconButton(
                                    onPressed: () => appState.plus(line),
                                    icon: const Icon(
                                        Icons.add_circle_outline),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => appState.remove(line),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                SummaryRow('Food total', money(appState.subtotal)),
                SummaryRow(
                  'Delivery',
                  appState.location == null
                      ? 'Calculated at checkout'
                      : money(appState.deliveryFee),
                ),
                const Divider(),
                SummaryRow('Total', money(appState.total), bold: true),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    ),
                    child: const Text('CHECKOUT'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class LocationScreen extends StatefulWidget {
  final DeliveryLocation? initial;
  const LocationScreen({super.key, this.initial});

  @override
  State<LocationScreen> createState() => _LocationState();
}

class _LocationState extends State<LocationScreen> {
  final MapController map = MapController();
  Position? pos;
  Branch? branch;
  List<Branch> branches = [];
  List<LatLng> route = [];
  String address = '';
  String error = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final x = widget.initial!;
      pos = Position(
        latitude: x.latitude,
        longitude: x.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      address = x.address;
      loading = false;
      _locate();
    } else {
      _locate();
    }
  }

  Future<void> _locate() async {
    if (mounted) setState(() => loading = true);

    try {
      final p = await LocationService.currentPosition();
      final bs = await LocationService.branches();

      if (bs.isEmpty) {
        throw Exception('No active MJOMBAS branch was found.');
      }

      final b = LocationService.nearest(bs, p.latitude, p.longitude);
      final d =
          LocationService.distance(b.latitude, b.longitude, p.latitude, p.longitude);

      String a;
      try {
        a = await LocationService.reverseGeocode(p.latitude, p.longitude);
      } catch (_) {
        a =
            'GPS ${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
      }

      List<LatLng> r = [];
      try {
        r = await LocationService.route(
          b.latitude,
          b.longitude,
          p.latitude,
          p.longitude,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        pos = p;
        branches = bs;
        branch = b;
        address = a;
        route = r;
        error = '';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  void _confirm() {
    if (pos == null || branch == null) return;

    final d = LocationService.distance(
      branch!.latitude,
      branch!.longitude,
      pos!.latitude,
      pos!.longitude,
    );

    final location = DeliveryLocation(
      latitude: pos!.latitude,
      longitude: pos!.longitude,
      distanceMeters: d,
      deliveryFee: LocationService.deliveryFee(d),
      address: address,
      branchId: branch!.id,
      branchName: branch!.name,
      branchLatitude: branch!.latitude,
      branchLongitude: branch!.longitude,
      estimatedMinutes: LocationService.estimatedMinutes(d),
    );

    appState.setLocation(location);
    Navigator.pop(context, location);
  }

  @override
  Widget build(BuildContext context) {
    final center = pos == null
        ? const LatLng(-1.286389, 36.817223)
        : LatLng(pos!.latitude, pos!.longitude);

    final markers = <Marker>[
      for (final b in branches)
        Marker(
          point: LatLng(b.latitude, b.longitude),
          width: 44,
          height: 44,
          child: Tooltip(
            message: b.name,
            child: const Icon(
              Icons.storefront,
              color: orange,
              size: 34,
            ),
          ),
        ),
      if (pos != null)
        Marker(
          point: center,
          width: 48,
          height: 48,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 48,
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: map,
            options: MapOptions(
              initialCenter: center,
              initialZoom: pos == null ? 11 : 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mjomba.app',
              ),
              if (route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      strokeWidth: 5,
                      color: orange,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (loading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (error.isNotEmpty)
                      Text(
                        error,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (branch != null && pos != null) ...[
                      Text(
                        branch!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${(LocationService.distance(branch!.latitude, branch!.longitude, pos!.latitude, pos!.longitude) / 1000).toStringAsFixed(2)} km • ${money(LocationService.deliveryFee(LocationService.distance(branch!.latitude, branch!.longitude, pos!.latitude, pos!.longitude)))} delivery • ${LocationService.estimatedMinutes(LocationService.distance(branch!.latitude, branch!.longitude, pos!.latitude, pos!.longitude))} min',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _locate,
                              icon: const Icon(Icons.my_location),
                              label: const Text('UPDATE'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: _confirm,
                              child: const Text('CONFIRM'),
                            ),
                          ),
                        ],
                      ),
                    ] else if (!loading)
                      FilledButton.icon(
                        onPressed: _locate,
                        icon: const Icon(Icons.location_on),
                        label: const Text('GET MY LOCATION'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutState();
}

class _CheckoutState extends State<CheckoutScreen> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController building;
  late final TextEditingController code;

  DeliveryLocation? location;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final profile = appState.profile;
    name = TextEditingController(text: profile.fullName);
    phone = TextEditingController(text: profile.phone);
    email = TextEditingController(text: profile.email);
    building = TextEditingController(text: profile.buildingName);
    code = TextEditingController();
    location = appState.location;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    building.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> chooseLocation() async {
    final selected = await Navigator.push<DeliveryLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationScreen(initial: location),
      ),
    );
    if (selected != null && mounted) {
      setState(() => location = selected);
    }
  }

  Future<void> submit() async {
    if (appState.lines.isEmpty) {
      _showSnack(context, 'Your cart is empty.');
      return;
    }

    if (name.text.trim().isEmpty || phone.text.trim().isEmpty) {
      _showSnack(context, 'Please enter your full name and phone number.');
      return;
    }

    if (location == null) {
      _showSnack(context, 'Choose your GPS delivery location first.');
      return;
    }

    final mp = code.text.trim().toUpperCase();
    if (mp.isEmpty) {
      _showSnack(context, 'Enter the M-PESA transaction code.');
      return;
    }

    setState(() => saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Your Firebase session is not ready.');
      }

      final now = DateTime.now();
      final orderNumber =
          'MJ-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${1000 + (now.microsecond % 9000)}';

      final selected = location!;
      final subtotal = appState.subtotal;
      final total = subtotal + selected.deliveryFee;

      final ref =
          FirebaseFirestore.instance.collection('orders').doc(orderNumber);

      await ref.set({
        'orderNumber': orderNumber,
        'orderDate':
            '${now.day.toString().padLeft(2, '0')} ${now.month.toString().padLeft(2, '0')} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'createdAt': FieldValue.serverTimestamp(),
        'customerUid': user.uid,
        'userId': user.uid,
        'customerName': name.text.trim(),
        'fullName': name.text.trim(),
        'customerFullName': name.text.trim(),
        'customerPhone': phone.text.trim(),
        'phoneNumber': phone.text.trim(),
        'customerEmail': email.text.trim(),
        'buildingName': building.text.trim(),
        'deliveryAddress': selected.address,
        'latitude': selected.latitude,
        'longitude': selected.longitude,
        'branchId': selected.branchId,
        'branchName': selected.branchName,
        'distanceMeters': selected.distanceMeters,
        'branchLatitude': selected.branchLatitude,
        'branchLongitude': selected.branchLongitude,
        'estimatedMinutes': selected.estimatedMinutes,
        'paymentMethod': 'M-PESA',
        'mpesaCode': mp,
        'mpesaTill': _mpesaTill,
        'businessName': _businessName,
        'paymentStatus': 'PENDING',
        'status': 'Payment Pending',
        'subtotal': subtotal,
        'totalPrice': subtotal,
        'deliveryFee': selected.deliveryFee,
        'grandTotal': total,
        'rejectionReason': '',
        'items': appState.lines
            .map(
              (line) => {
                'foodId': line.food.id,
                'name': line.food.name,
                'description': line.food.description,
                'category': line.food.category,
                'imageName': line.food.imageName,
                'price': line.food.price,
                'quantity': line.qty,
                'totalPrice': line.total,
              },
            )
            .toList(),
      });

      await appState.saveProfile(
        CustomerProfile(
          fullName: name.text.trim(),
          phone: phone.text.trim(),
          email: email.text.trim(),
          buildingName: building.text.trim(),
          deliveryAddress: selected.address,
        ),
      );

      appState.clearCart();
      await appState.addNotification(
        'Order received',
        '$orderNumber is waiting for M-PESA payment verification.',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderPlacedScreen(
            orderNumber: orderNumber,
            total: total,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = location;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Your details'),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: building,
            decoration: const InputDecoration(
              labelText: 'Building / apartment (optional)',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Delivery'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.my_location, color: orange),
              title: Text(
                selected == null
                    ? 'Choose your delivery location'
                    : selected.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: selected == null
                  ? const Text('GPS location and nearest branch required')
                  : Text(
                      '${(selected.distanceMeters / 1000).toStringAsFixed(2)} km • ${money(selected.deliveryFee)} delivery • ${selected.estimatedMinutes} min',
                    ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: chooseLocation,
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('M-PESA'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pay to MJOMBAS FAST FOOD',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Till Number $_mpesaTill',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'M-PESA transaction code',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SummaryRow('Food', money(appState.subtotal)),
                  SummaryRow(
                    'Delivery',
                    selected == null
                        ? 'Select location'
                        : money(selected.deliveryFee),
                  ),
                  const Divider(),
                  SummaryRow(
                    'TOTAL',
                    money(
                      selected == null
                          ? appState.subtotal
                          : appState.subtotal + selected.deliveryFee,
                    ),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: saving ? null : submit,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(
                saving ? 'PLACING ORDER...' : 'PLACE ORDER',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderPlacedScreen extends StatelessWidget {
  final String orderNumber;
  final double total;

  const OrderPlacedScreen({
    super.key,
    required this.orderNumber,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Placed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: orange,
                child: Icon(Icons.check, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 20),
              const Text(
                'Order received',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                orderNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${money(total)}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your M-PESA payment is pending verification.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  ),
                  child: const Text('BACK TO MJOMBAS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.receipt_long,
          title: 'No account session',
          message: 'Restart the app to reconnect to Firebase.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('customerUid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Orders unavailable. Check Firestore rules.\n\n${snapshot.error}',
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs.map(OrderSummary.fromDoc).toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime(1970))
                  .compareTo(a.createdAt ?? DateTime(1970)),
            );

          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Your completed orders will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}


String _formatOrderDate(DateTime? value) {
  if (value == null) return 'Date unavailable';
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class OrderCard extends StatelessWidget {
  final OrderSummary order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final rejected = order.paymentStatus.toUpperCase() == 'REJECTED';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: order.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.id,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  StatusChip(
                    text: rejected ? 'PAYMENT REJECTED' : order.status,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatOrderDate(order.createdAt),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                order.deliveryAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    money(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Track order →',
                    style: TextStyle(
                      color: orange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _TrackState();
}

class _TrackState extends State<OrderTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = OrderSummary.fromDoc(snapshot.data!);
          final rejected =
              order.paymentStatus.toUpperCase() == 'REJECTED';

          final steps = rejected
              ? ['Payment Pending', 'Payment Rejected']
              : [
                  'Payment Pending',
                  'Order Received',
                  'Preparing',
                  'Ready',
                  'Picked Up',
                  'On The Way',
                  'Delivered',
                ];

          final current =
              rejected ? 1 : _statusIndex(order.status);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.id,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(order.deliveryAddress),
                      const SizedBox(height: 10),
                      Text(
                        '${money(order.total)} • ${order.branchName.isEmpty ? 'MJOMBAS' : order.branchName}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      for (var i = 0; i < steps.length; i++)
                        _TrackStep(
                          label: steps[i],
                          active: i <= current,
                          last: i == steps.length - 1,
                        ),
                    ],
                  ),
                ),
              ),
              if (rejected && order.mpesaCode.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                      ),
                      title: const Text('Payment rejected'),
                      subtitle:
                          Text('M-PESA code: ${order.mpesaCode}'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (!rejected)
                Text(
                  'Estimated delivery: ${order.estimatedMinutes} minutes',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
            ],
          );
        },
      ),
    );
  }
}

int _statusIndex(String status) {
  switch (status.toLowerCase()) {
    case 'payment pending':
      return 0;
    case 'order received':
      return 1;
    case 'preparing':
      return 2;
    case 'ready':
      return 3;
    case 'picked up':
      return 4;
    case 'on the way':
      return 5;
    case 'delivered':
      return 6;
    default:
      return 0;
  }
}

class _TrackStep extends StatelessWidget {
  final String label;
  final bool active;
  final bool last;

  const _TrackStep({
    required this.label,
    required this.active,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor:
                  active ? orange : Colors.grey.shade300,
              child: active
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!last)
              Container(
                width: 2,
                height: 34,
                color: active ? orange : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            label,
            style: TextStyle(
              fontWeight:
                  active ? FontWeight.w800 : FontWeight.w500,
              color: active ? dark : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController building;
  late final TextEditingController address;

  @override
  void initState() {
    super.initState();
    final profile = appState.profile;
    name = TextEditingController(text: profile.fullName);
    phone = TextEditingController(text: profile.phone);
    email = TextEditingController(text: profile.email);
    building = TextEditingController(text: profile.buildingName);
    address = TextEditingController(text: profile.deliveryAddress);
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    building.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> save() async {
    await appState.saveProfile(
      CustomerProfile(
        fullName: name.text,
        phone: phone.text,
        email: email.text,
        buildingName: building.text,
        deliveryAddress: address.text,
      ),
    );

    if (mounted) _showSnack(context, 'Profile saved.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
            icon: Badge(
              isLabelVisible: appState.unread > 0,
              child: const Icon(Icons.notifications_none),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor:
                        orange.withValues(alpha: .14),
                    child: const Icon(
                      Icons.person,
                      color: orange,
                      size: 35,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.text.isEmpty
                              ? 'MJOMBAS Customer'
                              : name.text,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          phone.text.isEmpty
                              ? 'Add your phone number'
                              : phone.text,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Customer information'),
          TextField(
            controller: name,
            decoration:
                const InputDecoration(labelText: 'Full name'),
          ),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration:
                const InputDecoration(labelText: 'Phone'),
          ),
          TextField(
            controller: email,
            decoration:
                const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: building,
            decoration: const InputDecoration(
              labelText: 'Building / apartment',
            ),
          ),
          TextField(
            controller: address,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Saved delivery address',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: save,
              child: const Text('SAVE PROFILE'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LocationScreen(),
              ),
            ),
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('UPDATE DELIVERY LOCATION'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: PhoneService.callMjombas,
            icon: const Icon(Icons.phone_outlined),
            label: const Text('CALL MJOMBAS 0704 646 628'),
          ),
          const SizedBox(height: 20),
          const SectionTitle('More'),
          ListTile(
            leading:
                const Icon(Icons.support_agent, color: orange),
            title: const Text('Customer Care'),
            subtitle: const Text(
              'Help with payment, orders and delivery',
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerCareScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.admin_panel_settings_outlined,
              color: orange,
            ),
            title: const Text('Admin Panel'),
            subtitle: const Text(
              'For authorized MJOMBAS staff',
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed:
                appState.unread == 0 ? null : appState.markAllRead,
            child: const Text('READ ALL'),
          ),
        ],
      ),
      body: appState.notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications',
              message: 'Order updates will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: appState.notifications.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 7),
              itemBuilder: (_, index) {
                final notification =
                    appState.notifications[index];

                return Card(
                  color: notification.read
                      ? Colors.white
                      : cream,
                  child: ListTile(
                    onTap: () =>
                        appState.markRead(notification),
                    leading: CircleAvatar(
                      backgroundColor:
                          orange.withValues(alpha: .13),
                      child: const Icon(
                        Icons.notifications,
                        color: orange,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${notification.message}\n${notification.time.replaceFirst('T', ' ').split('.').first}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CustomerCareScreen extends StatelessWidget {
  const CustomerCareScreen({super.key});

  Future<void> _call() async {
    final uri = Uri.parse('tel:$_phone');
    await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final uri =
        Uri.parse('https://wa.me/254704646628');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Care')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'We are here to help.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'For payment, order or delivery support, contact MJOMBAS directly.',
          ),
          const SizedBox(height: 22),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.phone, color: orange),
              title: const Text('0704 646 628'),
              subtitle: const Text('Call MJOMBAS'),
              onTap: _call,
            ),
          ),
          const Card(
            child: ListTile(
              leading:
                  Icon(Icons.payments, color: orange),
              title:
                  Text('M-PESA Till 3429801'),
              subtitle:
                  Text('MJOMBAS FAST FOOD'),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _call,
            icon: const Icon(Icons.call),
            label: const Text('CALL CUSTOMER CARE'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _whatsapp,
            icon: const Icon(Icons.chat),
            label: const Text('WHATSAPP CUSTOMER CARE'),
          ),
        ],
      ),
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminState();
}

class _AdminState extends State<AdminScreen> {
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MJOMBAS ADMIN')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('paymentStatus', isEqualTo: 'PENDING')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            error = snapshot.error.toString();
          }

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_outlined,
              title: 'No pending payments',
              message: 'There are no M-PESA payments awaiting review.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final doc = orders[index];
              final data =
                  doc.data() as Map<String, dynamic>;

              final orderNumber =
                  '${data['orderNumber'] ?? doc.id}';
              final customer =
                  '${data['customerName'] ?? ''}';
              final phone =
                  '${data['customerPhone'] ?? ''}';
              final code =
                  '${data['mpesaCode'] ?? ''}';
              final address =
                  '${data['deliveryAddress'] ?? ''}';
              final total =
                  data['grandTotal'] is num
                      ? (data['grandTotal'] as num).toDouble()
                      : double.tryParse(
                            '${data['grandTotal'] ?? 0}',
                          ) ??
                          0;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              orderNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const StatusChip(
                            text: 'PAYMENT PENDING',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(customer),
                      Text(phone),
                      const SizedBox(height: 5),
                      Text('M-PESA: $code'),
                      Text('Total: ${money(total)}'),
                      const SizedBox(height: 5),
                      Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _reject(doc.id),
                              child:
                                  const Text('REJECT'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () =>
                                  _approve(doc.id),
                              child:
                                  const Text('APPROVE'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approve(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(id)
          .update({
        'paymentStatus': 'APPROVED',
        'status': 'Order Received',
        'approvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) _showSnack(context, '$e');
    }
  }

  Future<void> _reject(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(id)
          .update({
        'paymentStatus': 'REJECTED',
        'status': 'Payment Rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) _showSnack(context, '$e');
    }
  }
}
