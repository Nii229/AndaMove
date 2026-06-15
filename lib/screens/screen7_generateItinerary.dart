// ============================================================
// AndaMove — Generate Itinerary Screen
// File: lib/screens/screen7_generateItinerary.dart
//
// Changes vs previous version:
//   [CHANGED] preSelectedPoiName (String?) → preSelectedPoiNames (List<String>?)
//             Now supports pre-checking multiple POIs for Re-run Trip,
//             Continue Editing, and Edit Stops flows from screen8/screen11.
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_store.dart';
import 'screen8_itineraryResult.dart';

// ══════════════════════════════════════════════════════════════
// COLOR TOKENS
// ══════════════════════════════════════════════════════════════
class AppColors {
  static const Color oceanDeep = Color(0xFF0A7FAB);
  static const Color oceanMid = Color(0xFF1AAECF);
  static const Color oceanTint = Color(0xFFEAF8FD);
  static const Color gold = Color(0xFFC8912E);
  static const Color goldLight = Color(0xFFF0C060);
  static const Color goldTint = Color(0xFFFDF5E7);
  static const Color coral = Color(0xFFE8634C);
  static const Color coralTint = Color(0xFFFDF0EE);
  static const Color green = Color(0xFF16A34A);
  static const Color greenTint = Color(0xFFEEF5EE);
  static const Color bg = Color(0xFFFBF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF5F1EB);
  static const Color border = Color(0xFFE6DDD1);
  static const Color borderLight = Color(0xFFF0EBE2);
  static const Color text1 = Color(0xFF0A1E28);
  static const Color text2 = Color(0xFF5A7A8A);
  static const Color text3 = Color(0xFF9AB0B8);
}

class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;
}

List<BoxShadow> get shadowSm => [
  BoxShadow(
    color: const Color(0xFF0A1F28).withOpacity(0.06),
    blurRadius: 4,
    offset: const Offset(0, 1),
  ),
];
List<BoxShadow> get shadowOcean => [
  BoxShadow(
    color: AppColors.oceanDeep.withOpacity(0.25),
    blurRadius: 20,
    offset: const Offset(0, 8),
  ),
];

// ══════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════
class _TransportMode {
  final String label;
  final IconData icon;
  const _TransportMode(this.label, this.icon);
}

class _CategoryChip {
  final String label;
  final IconData icon;
  const _CategoryChip(this.label, this.icon);
}

class PoiItem {
  final String name;
  final String category;
  final double rating;
  String distance;
  final IconData thumbIcon;
  final List<Color> thumbGradient;
  final String imagePath;
  bool isSavedPoi;
  bool checked;
  final double latitude;
  final double longitude;
  int stayMinutes;
  final String openHours; // ← NEW: real hours, drives scheduling

  PoiItem({
    required this.name,
    required this.category,
    required this.rating,
    required this.distance,
    required this.thumbIcon,
    required this.thumbGradient,
    required this.imagePath,
    this.isSavedPoi = false,
    this.checked = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.stayMinutes = 60,
    this.openHours = 'Open 24 hours', // ← NEW: fail-open default
  });
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class GenerateItineraryScreen extends StatefulWidget {
  // [CHANGED] Now accepts a list of POI names to pre-check.
  // Used by: Re-run Trip, Continue Editing, Edit Stops.
  final List<String>? preSelectedPoiNames;

  // Pre-fill date/time/transport for Continue Editing and Edit Stops flows.
  final DateTime? preSelectedDate;
  final TimeOfDay? preSelectedTime;
  final String? preSelectedTransport;

  const GenerateItineraryScreen({
    super.key,
    this.preSelectedPoiNames,
    this.preSelectedDate,
    this.preSelectedTime,
    this.preSelectedTransport,
  });

  @override
  State<GenerateItineraryScreen> createState() =>
      _GenerateItineraryScreenState();
}

class _GenerateItineraryScreenState extends State<GenerateItineraryScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTransport = 0;
  String _poiSearchQuery = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  late final AnimationController _sheenCtrl;
  late final Animation<double> _sheenAnim;

  // ── Transport modes ───────────────────────────────────────
  static const _transports = [
    _TransportMode('Scooter', Icons.moped_rounded),
    _TransportMode('Tuk-tuk', Icons.electric_rickshaw_rounded),
    _TransportMode('Car', Icons.directions_car_rounded),
    _TransportMode('Walk', Icons.directions_walk_rounded),
  ];

  // ── Category chips ────────────────────────────────────────
  static const _categories = [
    _CategoryChip('Beach', Icons.beach_access_rounded),
    _CategoryChip('Temple', Icons.temple_buddhist_rounded),
    _CategoryChip('Nature', Icons.forest_rounded),
    _CategoryChip('Culture', Icons.account_balance_rounded),
    _CategoryChip('Food', Icons.restaurant_rounded),
    _CategoryChip('Adventure', Icons.surfing_rounded),
    _CategoryChip('Nightlife', Icons.nightlife_rounded),
    _CategoryChip('Heritage', Icons.museum_rounded),
    _CategoryChip('Viewpoint', Icons.landscape_rounded),
    _CategoryChip('Attraction', Icons.attractions_rounded),
    _CategoryChip('Shopping', Icons.shopping_bag_rounded),
  ];

  // ── Full 25-POI static list ───────────────────────────────
  static final _staticPois = <PoiItem>[
    // Beaches
    PoiItem(
      name: 'Kata Beach',
      category: 'Beach',
      rating: 4.7,
      distance: '2.4 km',
      thumbIcon: Icons.beach_access_rounded,
      thumbGradient: [Color(0xFF6B3FA0), Color(0xFFE8634C)],
      imagePath: 'assets/images/kata_beach.jpg',
      latitude: 7.8206,
      longitude: 98.2985,
      openHours: 'Open 24 hours',
    ),
    PoiItem(
      name: 'Patong Beach',
      category: 'Beach',
      rating: 4.5,
      distance: '5.1 km',
      thumbIcon: Icons.waves_rounded,
      thumbGradient: [Color(0xFF0A7FAB), Color(0xFF38BDF8)],
      imagePath: 'assets/images/patong_beach.jpg',
      latitude: 7.8907,
      longitude: 98.2963,
      openHours: 'Open 24 hours',
    ),
    PoiItem(
      name: 'Freedom Beach',
      category: 'Beach',
      rating: 4.8,
      distance: '6.2 km',
      thumbIcon: Icons.beach_access_rounded,
      thumbGradient: [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
      imagePath: 'assets/images/freedom_beach.jpg',
      latitude: 7.8773,
      longitude: 98.2745,
      openHours: 'Open 24 hours',
    ),
    PoiItem(
      name: 'Surin Beach',
      category: 'Beach',
      rating: 4.6,
      distance: '8.4 km',
      thumbIcon: Icons.beach_access_rounded,
      thumbGradient: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
      imagePath: 'assets/images/surin_beach.jpg',
      latitude: 7.9772,
      longitude: 98.2786,
      openHours: 'Open 24 hours',
    ),
    PoiItem(
      name: 'Nai Harn Beach',
      category: 'Beach',
      rating: 4.8,
      distance: '9.7 km',
      thumbIcon: Icons.waves_rounded,
      thumbGradient: [Color(0xFF0F766E), Color(0xFF14B8A6)],
      imagePath: 'assets/images/nai_harn_beach.jpg',
      latitude: 7.7747,
      longitude: 98.3060,
      openHours: 'Open 24 hours',
    ),
    // Temples
    PoiItem(
      name: 'The Big Buddha',
      category: 'Temple',
      rating: 4.8,
      distance: '2.4 km',
      thumbIcon: Icons.temple_buddhist_rounded,
      thumbGradient: [Color(0xFF0A7FAB), Color(0xFF1AAECF)],
      imagePath: 'assets/images/the_big_buddha.jpg',
      latitude: 7.8276,
      longitude: 98.3120,
      openHours: '8:00 AM - 7:30 PM',
    ),
    PoiItem(
      name: 'Wat Chalong',
      category: 'Temple',
      rating: 4.8,
      distance: '5.1 km',
      thumbIcon: Icons.account_balance_rounded,
      thumbGradient: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      imagePath: 'assets/images/wat_chalong.jpg',
      latitude: 7.8466,
      longitude: 98.3376,
      openHours: '7:00 AM - 5:00 PM',
    ),
    // Nature
    PoiItem(
      name: 'Elephant Sanctuary',
      category: 'Nature',
      rating: 4.9,
      distance: '12.3 km',
      thumbIcon: Icons.pets_rounded,
      thumbGradient: [Color(0xFF16A34A), Color(0xFF22C55E)],
      imagePath: 'assets/images/phuket_elephant_sanctuary.jpg',
      latitude: 7.9519,
      longitude: 98.3700,
      openHours: '9:00 AM - 5:00 PM',
    ),
    PoiItem(
      name: 'Sirinat Natl Park',
      category: 'Nature',
      rating: 4.6,
      distance: '18.1 km',
      thumbIcon: Icons.park_rounded,
      thumbGradient: [Color(0xFF15803D), Color(0xFF22C55E)],
      imagePath: 'assets/images/sirinat_national_park.jpg',
      latitude: 8.1050,
      longitude: 98.2950,
      openHours: '8:00 AM - 6:00 PM',
    ),
    PoiItem(
      name: 'Koh Sirey',
      category: 'Nature',
      rating: 4.3,
      distance: '3.8 km',
      thumbIcon: Icons.forest_rounded,
      thumbGradient: [Color(0xFF166534), Color(0xFF4ADE80)],
      imagePath: 'assets/images/koh_sirey.jpg',
      latitude: 7.8939,
      longitude: 98.4203,
      openHours: 'Open 24 hours',
    ),
    // Culture
    PoiItem(
      name: 'Old Phuket Town',
      category: 'Culture',
      rating: 4.9,
      distance: '4.2 km',
      thumbIcon: Icons.location_city_rounded,
      thumbGradient: [Color(0xFF8B4513), Color(0xFFC8912E)],
      imagePath: 'assets/images/old_phuket_town.jpg',
      latitude: 7.8841,
      longitude: 98.3880,
      openHours: 'Open 24 hours',
    ),
    PoiItem(
      name: 'Phuket Fantasea',
      category: 'Culture',
      rating: 4.5,
      distance: '14.6 km',
      thumbIcon: Icons.celebration_rounded,
      thumbGradient: [Color(0xFF7C3AED), Color(0xFFA855F7)],
      imagePath: 'assets/images/phuket_fantasea.jpg',
      latitude: 7.9512,
      longitude: 98.2862,
      openHours: '5:30 PM - 11:30 PM',
    ),
    // Food
    PoiItem(
      name: 'Rawai Seafood Mkt',
      category: 'Food',
      rating: 4.6,
      distance: '10.2 km',
      thumbIcon: Icons.set_meal_rounded,
      thumbGradient: [Color(0xFFE8634C), Color(0xFFF97316)],
      imagePath: 'assets/images/rawai_seafood_market.jpg',
      latitude: 7.7757,
      longitude: 98.3265,
      openHours: '9:00 AM - 9:00 PM',
    ),
    PoiItem(
      name: 'Walking Street',
      category: 'Food',
      rating: 4.7,
      distance: '4.5 km',
      thumbIcon: Icons.restaurant_rounded,
      thumbGradient: [Color(0xFFD97706), Color(0xFFF59E0B)],
      imagePath: 'assets/images/phuket_town_walking_street.jpg',
      latitude: 7.8838,
      longitude: 98.3877,
      openHours: 'Sun 4:00 PM - 10:00 PM',
    ),
    PoiItem(
      name: 'Blue Elephant',
      category: 'Food',
      rating: 4.7,
      distance: '4.1 km',
      thumbIcon: Icons.dining_rounded,
      thumbGradient: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
      imagePath: 'assets/images/blue_elephant_restaurant.jpg',
      latitude: 7.8830,
      longitude: 98.3835,
      openHours: '11:30 AM - 10:00 PM',
    ),
    // Adventure
    PoiItem(
      name: 'Tiger Kingdom',
      category: 'Adventure',
      rating: 4.2,
      distance: '7.3 km',
      thumbIcon: Icons.pets_rounded,
      thumbGradient: [Color(0xFFEA580C), Color(0xFFF97316)],
      imagePath: 'assets/images/tiger_kingdom.jpg',
      latitude: 7.9214,
      longitude: 98.3573,
      openHours: '9:00 AM - 6:00 PM',
    ),
    PoiItem(
      name: 'ATV & Zipline',
      category: 'Adventure',
      rating: 4.5,
      distance: '8.0 km',
      thumbIcon: Icons.directions_bike_rounded,
      thumbGradient: [Color(0xFF166534), Color(0xFF16A34A)],
      imagePath: 'assets/images/atv_&_zipline.jpg',
      latitude: 7.9000,
      longitude: 98.3500,
      openHours: '8:00 AM - 5:00 PM',
    ),
    PoiItem(
      name: 'Phi Phi Day Trip',
      category: 'Adventure',
      rating: 4.9,
      distance: '2.1 km',
      thumbIcon: Icons.sailing_rounded,
      thumbGradient: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
      imagePath: 'assets/images/phi_phi_island.jpg',
      latitude: 7.7407,
      longitude: 98.7784,
      openHours: '7:30 AM - 6:00 PM',
    ),
    // Nightlife
    PoiItem(
      name: 'Bangla Road',
      category: 'Nightlife',
      rating: 4.3,
      distance: '5.8 km',
      thumbIcon: Icons.nightlife_rounded,
      thumbGradient: [Color(0xFF7C3AED), Color(0xFFDB2777)],
      imagePath: 'assets/images/bangla_road.jpg',
      latitude: 7.8930,
      longitude: 98.2965,
      openHours: '6:00 PM - Late',
    ),
    PoiItem(
      name: 'Illuzion Club',
      category: 'Nightlife',
      rating: 4.4,
      distance: '5.9 km',
      thumbIcon: Icons.music_note_rounded,
      thumbGradient: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
      imagePath: 'assets/images/illuzion_club.jpg',
      latitude: 7.8925,
      longitude: 98.2960,
      openHours: '9:00 PM - Late',
    ),
    // Heritage
    PoiItem(
      name: 'Thalang Museum',
      category: 'Heritage',
      rating: 4.3,
      distance: '16.4 km',
      thumbIcon: Icons.museum_rounded,
      thumbGradient: [Color(0xFF92400E), Color(0xFFB45309)],
      imagePath: 'assets/images/thalang_national_museum.jpg',
      latitude: 8.0010,
      longitude: 98.3360,
      openHours: '9:00 AM - 4:00 PM',
    ),
    // Viewpoints
    PoiItem(
      name: 'Promthep Cape',
      category: 'Viewpoint',
      rating: 4.9,
      distance: '11.5 km',
      thumbIcon: Icons.wb_sunny_rounded,
      thumbGradient: [Color(0xFFF59E0B), Color(0xFFF97316)],
      imagePath: 'assets/images/promthep_cape.jpg',
      latitude: 7.7625,
      longitude: 98.3050,
      openHours: 'Open 24 hours',
    ),
    PoiItem(
      name: 'Karon Viewpoint',
      category: 'Viewpoint',
      rating: 4.7,
      distance: '3.1 km',
      thumbIcon: Icons.landscape_rounded,
      thumbGradient: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
      imagePath: 'assets/images/karon_viewpoint.jpg',
      latitude: 7.8076,
      longitude: 98.3050,
      openHours: 'Open 24 hours',
    ),
    // Attraction + Shopping
    PoiItem(
      name: 'Phuket Aquarium',
      category: 'Attraction',
      rating: 4.4,
      distance: '9.3 km',
      thumbIcon: Icons.set_meal_rounded,
      thumbGradient: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      imagePath: 'assets/images/phuket_aquarium.jpg',
      latitude: 7.8160,
      longitude: 98.4030,
      openHours: '8:30 AM - 4:30 PM',
    ),
    PoiItem(
      name: 'Jungceylon',
      category: 'Shopping',
      rating: 4.3,
      distance: '5.7 km',
      thumbIcon: Icons.shopping_bag_rounded,
      thumbGradient: [Color(0xFF475569), Color(0xFF64748B)],
      imagePath: 'assets/images/jungceylon.jpg',
      latitude: 7.8920,
      longitude: 98.2970,
      openHours: '11:00 AM - 10:00 PM',
    ),
  ];

  late List<PoiItem> _allPois;
  bool _loadingPois = true;

  double? _userLat;
  double? _userLng;
  bool _locationLoading = true;
  String _locationStatus = 'Getting your location...';

  static const _mapsApiKey = 'AIzaSyB0CTGhgMeEQczyD3N1aM6ynx7hY3HO6kw';

  @override
  void initState() {
    super.initState();
    final savedNames = AppStore.savedPois.map((p) => p.name).toSet();

    final savedItems = AppStore.savedPois
        .map(
          (p) => PoiItem(
            name: p.name,
            category: p.category,
            rating: p.rating,
            distance: '2.4 km',
            thumbIcon: p.icon,
            thumbGradient: p.gradientColors.take(2).toList(),
            imagePath:
                'assets/images/${p.name.toLowerCase().replaceAll(' ', '_')}.jpg',
            isSavedPoi: true,
            checked: false,
            openHours: p.openHours, // ← NEW
          ),
        )
        .toList();

    final staticItems = _staticPois
        .where((p) => !savedNames.contains(p.name))
        .toList();

    _allPois = [...savedItems, ...staticItems];

    // ── [CHANGED] Pre-select multiple POIs passed from screen8/screen11 ──
    if (widget.preSelectedPoiNames != null &&
        widget.preSelectedPoiNames!.isNotEmpty) {
      final nameSet = widget.preSelectedPoiNames!.toSet();
      for (final poi in _allPois) {
        if (nameSet.contains(poi.name)) {
          poi.checked = true;
        }
      }
    }
    // ─────────────────────────────────────────────────────────

    // ── Pre-fill date/time/transport for Continue Editing / Edit Stops ──
    if (widget.preSelectedDate != null) _selectedDate = widget.preSelectedDate!;
    if (widget.preSelectedTime != null) _selectedTime = widget.preSelectedTime!;
    if (widget.preSelectedTransport != null) {
      final idx = _transports.indexWhere((t) => t.label == widget.preSelectedTransport);
      if (idx >= 0) _selectedTransport = idx;
    }
    // ─────────────────────────────────────────────────────────

    _loadingPois = false; // static data is ready as fallback
    _loadPoisFromFirestore();
    _getUserLocation();

    _sheenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _sheenAnim = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _sheenCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _sheenCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPoisFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pois')
          .where('status', isEqualTo: 'active')
          .get();

      final firestorePois = snapshot.docs.map((doc) {
        final d = doc.data();
        final category = d['category'] as String? ?? '';
        final name = d['name'] as String? ?? '';
        final imagePath = d['imagePath'] as String? ?? '';

        IconData icon;
        switch (category.toLowerCase()) {
          case 'beach': icon = Icons.beach_access_rounded; break;
          case 'temple': icon = Icons.temple_buddhist_rounded; break;
          case 'nature': icon = Icons.forest_rounded; break;
          case 'culture': icon = Icons.account_balance_rounded; break;
          case 'food': icon = Icons.restaurant_rounded; break;
          case 'adventure': icon = Icons.surfing_rounded; break;
          case 'nightlife': icon = Icons.nightlife_rounded; break;
          case 'heritage': icon = Icons.location_city_rounded; break;
          case 'viewpoint': icon = Icons.landscape_rounded; break;
          case 'attraction': icon = Icons.attractions_rounded; break;
          case 'shopping': icon = Icons.shopping_bag_rounded; break;
          default: icon = Icons.place_rounded;
        }

        List<Color> gradient;
        switch (category.toLowerCase()) {
          case 'beach': gradient = [Color(0xFF0A7FAB), Color(0xFF38BDF8)]; break;
          case 'temple': gradient = [Color(0xFFFBBF24), Color(0xFFF59E0B)]; break;
          case 'nature': gradient = [Color(0xFF16A34A), Color(0xFF22C55E)]; break;
          case 'culture': gradient = [Color(0xFF7C3AED), Color(0xFFA855F7)]; break;
          case 'food': gradient = [Color(0xFFE8634C), Color(0xFFF97316)]; break;
          case 'adventure': gradient = [Color(0xFF166534), Color(0xFF16A34A)]; break;
          case 'nightlife': gradient = [Color(0xFF7C3AED), Color(0xFFDB2777)]; break;
          case 'heritage': gradient = [Color(0xFF92400E), Color(0xFFB45309)]; break;
          case 'viewpoint': gradient = [Color(0xFFF59E0B), Color(0xFFF97316)]; break;
          case 'attraction': gradient = [Color(0xFF06B6D4), Color(0xFF0891B2)]; break;
          case 'shopping': gradient = [Color(0xFF475569), Color(0xFF64748B)]; break;
          default: gradient = [Color(0xFF0A7FAB), Color(0xFF1AAECF)];
        }

        return PoiItem(
          name: name,
          category: category,
          rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
          distance: '',
          thumbIcon: icon,
          thumbGradient: gradient,
          imagePath: imagePath,
          latitude: (d['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (d['longitude'] as num?)?.toDouble() ?? 0.0,
          openHours: d['openHours'] as String? ?? 'Open 24 hours', // ← NEW
        );
      }).toList();

      if (firestorePois.isNotEmpty && mounted) {
        final savedNames = AppStore.savedPois.map((p) => p.name).toSet();
        for (final poi in firestorePois) {
          if (savedNames.contains(poi.name)) {
            poi.isSavedPoi = true;
          }
        }

        if (widget.preSelectedPoiNames != null) {
          final nameSet = widget.preSelectedPoiNames!.toSet();
          for (final poi in firestorePois) {
            if (nameSet.contains(poi.name)) {
              poi.checked = true;
            }
          }
        }

        setState(() {
          _allPois.clear();
          _allPois.addAll(firestorePois);
          _loadingPois = false;
        });
      } else {
        if (mounted) setState(() => _loadingPois = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPois = false);
    }
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() {
            _locationLoading = false;
            _locationStatus = 'Location denied — using Phuket center';
            _userLat = 7.8804;
            _userLng = 98.3923;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() {
          _locationLoading = false;
          _locationStatus = 'Location disabled — using Phuket center';
          _userLat = 7.8804;
          _userLng = 98.3923;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _locationLoading = false;
        _locationStatus = 'Location found';
      });
    } catch (e) {
      if (mounted) setState(() {
        _locationLoading = false;
        _locationStatus = 'Location unavailable — using Phuket center';
        _userLat = 7.8804;
        _userLng = 98.3923;
      });
    }
  }

  static int _suggestedStayMinutes(String category) {
    switch (category.toLowerCase()) {
      case 'beach': return 120;       // 2 hours
      case 'temple': return 60;       // 1 hour
      case 'nature': return 90;       // 1.5 hours
      case 'culture': return 90;      // 1.5 hours
      case 'food': return 60;         // 1 hour
      case 'adventure': return 120;   // 2 hours
      case 'nightlife': return 120;   // 2 hours
      case 'heritage': return 60;     // 1 hour
      case 'viewpoint': return 45;    // 45 mins
      case 'attraction': return 90;   // 1.5 hours
      case 'shopping': return 120;    // 2 hours
      default: return 60;
    }
  }

  List<PoiItem> get _checkedPois => _allPois.where((p) => p.checked).toList();

  bool get _hasSavedPois => _allPois.any((p) => p.isSavedPoi);

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  ThemeData _pickerTheme(BuildContext ctx) => Theme.of(ctx).copyWith(
    colorScheme: const ColorScheme.light(
      primary: AppColors.oceanDeep,
      onPrimary: Colors.white,
      onSurface: AppColors.text1,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.oceanDeep),
    ),
  );

  Future<void> _onGenerate() async {
    final checked = _checkedPois;
    debugPrint('CHECKED COORDS: ${checked.map((p) => "${p.name}=${p.latitude},${p.longitude}").toList()}');
    if (checked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one place.',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.oceanDeep, strokeWidth: 3),
              const SizedBox(height: 16),
              Text('Optimizing your route...', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
              const SizedBox(height: 4),
              Text('Calculating travel times', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.text2)),
            ],
          ),
        ),
      ),
    );

    try {
      final transportLabel = _transports[_selectedTransport].label;
      String travelMode;
      switch (transportLabel.toLowerCase()) {
        case 'walk': travelMode = 'walking'; break;
        case 'scooter': case 'tuk-tuk': case 'car': default: travelMode = 'driving'; break;
      }

      final hasCoords = checked.every((p) => p.latitude != 0.0 && p.longitude != 0.0);

      if (hasCoords && checked.length > 1) {
        final userLoc = '${_userLat ?? 7.8804},${_userLng ?? 98.3923}';
        final poiLocs = checked.map((p) => '${p.latitude},${p.longitude}').toList();
        final allLocations = [userLoc, ...poiLocs].join('|');

        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/distancematrix/json'
          '?origins=$allLocations'
          '&destinations=$allLocations'
          '&mode=$travelMode'
          '&key=$_mapsApiKey',
        );

        final response = await http.get(url);
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final totalPoints = checked.length + 1; // +1 for user location
          final rows = data['rows'] as List;
          final visited = <int>{0}; // Start from user location (index 0)
          final order = <int>[]; // Only POI indices (1-based)
          int current = 0;

          while (order.length < checked.length) {
            final elements = rows[current]['elements'] as List;
            int bestNext = -1;
            int bestDuration = 999999;

            for (int j = 1; j < totalPoints; j++) {
              if (visited.contains(j)) continue;
              final el = elements[j];
              if (el['status'] == 'OK') {
                final dur = el['duration']['value'] as int;
                if (dur < bestDuration) {
                  bestDuration = dur;
                  bestNext = j;
                }
              }
            }

            if (bestNext == -1) {
              for (int j = 1; j < totalPoints; j++) {
                if (!visited.contains(j)) {
                  order.add(j - 1);
                  visited.add(j);
                }
              }
            } else {
              order.add(bestNext - 1); // Convert back to checked[] index
              visited.add(bestNext);
              current = bestNext;
            }
          }

          final optimized = order.map((i) => checked[i]).toList();

          // [NEW] Parallel list of REAL travel minutes into each stop.
          final travelMinutes = List<int>.filled(optimized.length, 0);

          // First stop: travel time from user location
          final firstEl = rows[0]['elements'][order.first + 1];
          if (firstEl['status'] == 'OK') {
            optimized.first.distance = firstEl['duration']['text'] as String;
            travelMinutes[0] =
                ((firstEl['duration']['value'] as int) / 60).round();
          }
          // Subsequent stops
          for (int i = 1; i < optimized.length; i++) {
            final fromIdx = order[i - 1] + 1;
            final toIdx = order[i] + 1;
            final el = rows[fromIdx]['elements'][toIdx];
            if (el['status'] == 'OK') {
              optimized[i].distance = el['duration']['text'] as String;
              travelMinutes[i] =
                  ((el['duration']['value'] as int) / 60).round();
            }
          }
          optimized.last.distance = optimized.last.distance.isEmpty ? 'Last stop' : optimized.last.distance;

          if (mounted) Navigator.pop(context);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItineraryResultScreen(
                  transport: transportLabel,
                  categories: [],
                  selectedPois: optimized,
                  date: _selectedDate,
                  time: _selectedTime,
                  travelMinutes: travelMinutes, // ← NEW
                ),
              ),
            );
          }
          return;
        }
      }

      // Fallback: no coords or API failed
      if (mounted) Navigator.pop(context);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItineraryResultScreen(
              transport: transportLabel,
              categories: [],
              selectedPois: checked,
              date: _selectedDate,
              time: _selectedTime,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItineraryResultScreen(
              transport: _transports[_selectedTransport].label,
              categories: [],
              selectedPois: checked,
              date: _selectedDate,
              time: _selectedTime,
            ),
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: _buildBottomCta(),
      body: Column(
        children: [
          _buildHeader(),
          _buildLocationBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    number: '1',
                    color: AppColors.oceanDeep,
                    title: 'Transport Mode',
                    child: _buildTransportGrid(),
                  ),
                  _divider(),
                  _buildSection(
                    number: '2',
                    color: AppColors.text2,
                    title: 'Date & Start Time',
                    child: _buildDateTimeRow(),
                  ),
                  _divider(),
                  _buildPoiSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 14),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 19,
                    color: AppColors.text1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Your Day',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text1,
                      ),
                    ),
                    Text(
                      'Craft your perfect Phuket route',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              ClipRect(
                child: Transform.scale(
                  scale: 1.6,
                  child: Image.asset(
                    'assets/images/andamove_logo.png',
                    width: 60,
                    height: 60,
                    color: AppColors.text1,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // LOCATION BANNER
  // ══════════════════════════════════════════════════════════
  Widget _buildLocationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: _locationLoading ? AppColors.oceanTint : AppColors.greenTint,
      child: Row(
        children: [
          if (_locationLoading)
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.oceanDeep),
            )
          else
            Icon(
              _locationStatus == 'Location found'
                  ? Icons.my_location_rounded
                  : Icons.location_disabled_rounded,
              size: 14,
              color: _locationStatus == 'Location found' ? AppColors.green : AppColors.coral,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _locationLoading ? 'Getting your location...' : _locationStatus,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _locationLoading ? AppColors.oceanDeep : AppColors.green,
              ),
            ),
          ),
          if (!_locationLoading && _userLat != null)
            Text(
              '${_userLat!.toStringAsFixed(4)}, ${_userLng!.toStringAsFixed(4)}',
              style: GoogleFonts.outfit(fontSize: 10, color: AppColors.text3),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION BLOCK WRAPPER
  // ══════════════════════════════════════════════════════════
  Widget _buildSection({
    required String number,
    required Color color,
    required String title,
    required Widget child,
    Widget? trailing,
    double bottomPad = 0,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text1,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _divider() => Container(
    height: 1,
    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    color: AppColors.borderLight,
  );

  // ══════════════════════════════════════════════════════════
  // SECTION 1 — TRANSPORT GRID
  // ══════════════════════════════════════════════════════════
  Widget _buildTransportGrid() {
    return Row(
      children: List.generate(_transports.length, (i) {
        final t = _transports[i];
        final isSel = _selectedTransport == i;
        final isLast = i == _transports.length - 1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTransport = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: isLast ? 0 : 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              decoration: BoxDecoration(
                color: isSel ? AppColors.oceanTint : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isSel ? AppColors.oceanDeep : AppColors.border,
                  width: 2,
                ),
                boxShadow: shadowSm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    t.icon,
                    size: 26,
                    color: isSel ? AppColors.oceanDeep : AppColors.text3,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    t.label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSel ? AppColors.oceanDeep : AppColors.text3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSel ? AppColors.oceanDeep : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION 2 — POI CHECKLIST
  // ══════════════════════════════════════════════════════════
  Widget _buildPoiSection() {
    final checkedCount = _checkedPois.length;
    final countPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.oceanTint,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '$checkedCount selected',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.oceanDeep,
        ),
      ),
    );

    return _buildSection(
      number: '3',
      color: AppColors.coral,
      title: 'Must-See POIs',
      trailing: countPill,
      child: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: AppColors.text3),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _poiSearchQuery = v),
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.text1),
                    decoration: InputDecoration(
                      hintText: 'Search attractions, beaches...',
                      hintStyle: GoogleFonts.outfit(fontSize: 13, color: AppColors.text3),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_poiSearchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _poiSearchQuery = ''),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.text3),
                  ),
              ],
            ),
          ),
          _buildPoiList(),
        ],
      ),
    );
  }

  Widget _buildPoiList() {
    bool matchesSearch(PoiItem p) {
      if (_poiSearchQuery.trim().isEmpty) return true;
      final q = _poiSearchQuery.trim().toLowerCase();
      return p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q);
    }

    final savedPois = _allPois.where((p) => p.isSavedPoi && matchesSearch(p)).toList();
    final staticPois = _allPois.where((p) => !p.isSavedPoi && matchesSearch(p)).toList();

    if (savedPois.isEmpty && staticPois.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 30,
              color: AppColors.text3,
            ),
            const SizedBox(height: 10),
            Text(
              'No attractions for selected categories',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a category above to add it',
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.text3),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (savedPois.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.goldTint,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.gold.withOpacity(0.30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 12,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Saved Places',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...savedPois.map((poi) => _buildPoiRow(poi)),
          if (staticPois.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: AppColors.borderLight),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'All Attractions',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text3,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: AppColors.borderLight),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
        ...staticPois.map((poi) => _buildPoiRow(poi)),
      ],
    );
  }

  void _showCustomDurationSheet(PoiItem poi) {
    int tempMinutes = poi.stayMinutes;
    final suggested = _suggestedStayMinutes(poi.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Custom Stay Duration', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1)),
              const SizedBox(height: 4),
              Text(poi.name, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.text2)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.oceanTint,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text('Suggested: ${suggested}min for ${poi.category}',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.oceanDeep)),
              ),
              const SizedBox(height: 20),
              Text('${tempMinutes} minutes',
                style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.oceanDeep)),
              Slider(
                value: tempMinutes.toDouble(),
                min: 15,
                max: 300,
                divisions: 19,
                label: '${tempMinutes}min',
                activeColor: AppColors.oceanDeep,
                inactiveColor: AppColors.oceanTint,
                onChanged: (v) => setModal(() => tempMinutes = v.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('15 min', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.text3)),
                  Text('5 hours', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.text3)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => poi.stayMinutes = tempMinutes);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.oceanDeep,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                  ),
                  child: Text('Set Duration', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoiRow(PoiItem poi) {
    final idx = _allPois.indexOf(poi);
    final checked = poi.checked;

    return GestureDetector(
      onTap: () => setState(() {
        _allPois[idx].checked = !checked;
        if (!checked) {
          // Auto-set suggested stay when first checked
          _allPois[idx].stayMinutes = _suggestedStayMinutes(_allPois[idx].category);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: checked ? AppColors.oceanTint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: checked ? AppColors.oceanDeep : AppColors.border,
            width: 1.5,
          ),
          boxShadow: shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.asset(
                      poi.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: poi.thumbGradient.length >= 2
                                ? poi.thumbGradient
                                : [
                                    poi.thumbGradient.first,
                                    poi.thumbGradient.first,
                                  ],
                          ),
                        ),
                        child: Icon(
                          poi.thumbIcon,
                          size: 26,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              poi.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text1,
                              ),
                            ),
                          ),
                          if (poi.isSavedPoi)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.goldTint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Saved',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              poi.category,
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.near_me_rounded,
                            size: 11,
                            color: AppColors.oceanMid,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            poi.distance,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppColors.text2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star_rounded, size: 11, color: AppColors.gold),
                          const SizedBox(width: 2),
                          Text(
                            poi.rating.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: checked ? AppColors.oceanDeep : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: checked ? AppColors.oceanDeep : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: checked
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            if (checked) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.oceanDeep.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.oceanDeep),
                        const SizedBox(width: 6),
                        Text('Stay duration:', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...[30, 60, 90, 120].map((mins) {
                            final isSelected = poi.stayMinutes == mins;
                            final label = mins < 60
                                ? '${mins}m'
                                : '${mins ~/ 60}h${mins % 60 > 0 ? " ${mins % 60}m" : ""}';
                            return GestureDetector(
                              onTap: () => setState(() => poi.stayMinutes = mins),
                              child: Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.oceanDeep : AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                  border: Border.all(
                                    color: isSelected ? AppColors.oceanDeep : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppColors.text2,
                                  ),
                                ),
                              ),
                            );
                          }),
                          GestureDetector(
                            onTap: () => _showCustomDurationSheet(poi),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ![30, 60, 90, 120].contains(poi.stayMinutes) ? AppColors.oceanDeep : AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                border: Border.all(color: ![30, 60, 90, 120].contains(poi.stayMinutes) ? AppColors.oceanDeep : AppColors.border),
                              ),
                              child: Text(
                                ![30, 60, 90, 120].contains(poi.stayMinutes) ? '${poi.stayMinutes}m' : 'Other',
                                style: GoogleFonts.outfit(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: ![30, 60, 90, 120].contains(poi.stayMinutes) ? Colors.white : AppColors.text2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION 4 — DATE & TIME
  // ══════════════════════════════════════════════════════════
  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _dtCard(
            label: 'DATE',
            icon: Icons.calendar_today_rounded,
            value: _formatDate(_selectedDate),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) =>
                    Theme(data: _pickerTheme(ctx), child: child!),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _dtCard(
            label: 'START TIME',
            icon: Icons.schedule_rounded,
            value: _formatTime(_selectedTime),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
                builder: (ctx, child) =>
                    Theme(data: _pickerTheme(ctx), child: child!),
              );
              if (picked != null) setState(() => _selectedTime = picked);
            },
          ),
        ),
      ],
    );
  }

  Widget _dtCard({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.text3,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(icon, size: 17, color: AppColors.oceanDeep),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BOTTOM CTA
  // ══════════════════════════════════════════════════════════
  Widget _buildBottomCta() {
    final count = _checkedPois.length;

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.text3,
                ),
                const SizedBox(width: 6),
                Text(
                  () {
                    if (count == 0) return 'Select at least one place to continue';
                    final totalStayMins = _checkedPois.fold<int>(0, (acc, p) => acc + p.stayMinutes);
                    final stayH = totalStayMins ~/ 60;
                    final stayM = totalStayMins % 60;
                    final stayText = stayM == 0 ? '${stayH}h stay' : '${stayH}h ${stayM}m stay';
                    return '$count place${count == 1 ? '' : 's'} · $stayText + travel time';
                  }(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.text3,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _sheenAnim,
              builder: (_, child) => GestureDetector(
                onTap: _onGenerate,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: count > 0
                          ? [AppColors.oceanDeep, AppColors.oceanMid]
                          : [AppColors.text3, AppColors.text3],
                    ),
                    boxShadow: count > 0 ? shadowOcean : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Stack(
                      children: [
                        Positioned.fill(child: Center(child: child!)),
                        if (count > 0)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: SheenPainter(position: _sheenAnim.value),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generate My Itinerary',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'AI-powered route planning',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SHEEN PAINTER
// ══════════════════════════════════════════════════════════════
class SheenPainter extends CustomPainter {
  final double position;
  const SheenPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final stripeW = size.width * 0.30;
    final left = position * size.width;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(left, 0, stripeW, size.height), paint);
  }

  @override
  bool shouldRepaint(SheenPainter old) => old.position != position;
}