// ============================================================
// AndaMove Admin — Screen 2: Manage POIs
// File: lib/admin/screens/adminScreen2_managePOI.dart
//
// UPDATED:
//   • Hide/Show/Delete/Approve/Reject all work in REAL-TIME
//     via AppStore — no Firebase needed yet
//   • Admin-created POIs appear automatically
//   • Delete shows confirmation bottom sheet
//   • Hidden POIs are hidden from tourist app
//   • Status counts update live in summary strip
//   • Listens to AppStore for reactive rebuilds
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin_theme.dart';
import 'adminScreen3_createPOI.dart';
import 'adminScreen3b_editPOI.dart';
import '../../screens/screen6_POI.dart';
import '../../app_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Status enum ───────────────────────────────────────────────
enum PoiStatus { active, hidden, review }

// ── Admin POI wrapper ─────────────────────────────────────────
class _AdminPoi {
  final PoiModel poi;
  final String? viewsText;
  final String? firestoreDocId;
  final PoiStatus? firestoreStatus;
  final double latitude;
  final double longitude;
  const _AdminPoi({
    required this.poi,
    this.viewsText,
    this.firestoreDocId,
    this.firestoreStatus,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  PoiStatus get status {
    if (firestoreStatus != null) return firestoreStatus!;
    if (AppStore.hiddenPois.contains(poi.name)) return PoiStatus.hidden;
    if (AppStore.reviewPois.contains(poi.name)) return PoiStatus.review;
    return PoiStatus.active;
  }
}

// ══════════════════════════════════════════════════════════════
// BUILD ALL POIS (25 hardcoded + admin-created, minus deleted)
// ══════════════════════════════════════════════════════════════
List<_AdminPoi> _buildAllPois() {
  PoiModel m({
    required String name,
    required String location,
    required String category,
    required double rating,
    required String description,
    String longDescription = '',
    required String openHours,
    required String estimatedTime,
    String priceRange = 'Free',
    String imagePath = '',
    required IconData icon,
    required List<Color> gradientColors,
    List<PoiTag> tags = const [],
  }) => PoiModel(
    name: name,
    location: location,
    category: category,
    rating: rating,
    description: description,
    longDescription: longDescription,
    openHours: openHours,
    estimatedTime: estimatedTime,
    priceRange: priceRange,
    imagePath: imagePath,
    gradientColors: gradientColors,
    icon: icon,
    tags: tags,
  );

  final hardcoded = <_AdminPoi>[
    _AdminPoi(
      viewsText: '4.7 · 2,841 views',
      poi: m(
        name: 'Kata Beach',
        location: 'Kata, Phuket',
        category: 'Beach',
        rating: 4.7,
        description: 'A beautiful beach popular for swimming and sunsets.',
        longDescription: 'Kata Beach is giving soft-life paradise energy.',
        openHours: 'Open 24 hours',
        estimatedTime: '2 - 4 hours',
        imagePath: 'assets/images/kata_beach.jpg',
        icon: Icons.beach_access_rounded,
        gradientColors: [
          Color(0xFF6B3FA0),
          Color(0xFFE8634C),
          Color(0xFFF0A070),
        ],
        tags: [PoiTag('Beach', Color(0xFFEAF8FD), Color(0xFF0A7FAB))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.5 · 3,102 views',
      poi: m(
        name: 'Patong Beach',
        location: 'Patong, Phuket',
        category: 'Beach',
        rating: 4.5,
        description: 'A lively beach known for nightlife and shopping.',
        openHours: 'Open 24 hours',
        estimatedTime: '2 - 4 hours',
        imagePath: 'assets/images/patong_beach.jpg',
        icon: Icons.waves_rounded,
        gradientColors: [
          Color(0xFF0A7FAB),
          Color(0xFF38BDF8),
          Color(0xFF93C5FD),
        ],
        tags: [PoiTag('Popular', Color(0xFFEAF8FD), Color(0xFF0A7FAB))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.8 · 1,203 views',
      poi: m(
        name: 'Freedom Beach',
        location: 'Patong, Phuket',
        category: 'Beach',
        rating: 4.8,
        description: 'A quieter hidden beach with soft sand.',
        openHours: 'Open 24 hours',
        estimatedTime: '2 - 3 hours',
        imagePath: 'assets/images/freedom_beach.jpg',
        icon: Icons.beach_access_rounded,
        gradientColors: [
          Color(0xFF14B8A6),
          Color(0xFF0EA5E9),
          Color(0xFFBAE6FD),
        ],
        tags: [PoiTag('Hidden Gem', Color(0xFFEAF8FD), Color(0xFF0A7FAB))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.6 · 1,580 views',
      poi: m(
        name: 'Surin Beach',
        location: 'Surin, Phuket',
        category: 'Beach',
        rating: 4.6,
        description: 'Upscale beach with clear water and beach clubs.',
        openHours: 'Open 24 hours',
        estimatedTime: '2 - 3 hours',
        priceRange: '฿',
        imagePath: 'assets/images/surin_beach.jpg',
        icon: Icons.beach_access_rounded,
        gradientColors: [
          Color(0xFF0284C7),
          Color(0xFF0EA5E9),
          Color(0xFF7DD3FC),
        ],
        tags: [PoiTag('Upscale', Color(0xFFFDF5E7), Color(0xFFC8912E))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.8 · 2,014 views',
      poi: m(
        name: 'Nai Harn Beach',
        location: 'Nai Harn, Phuket',
        category: 'Beach',
        rating: 4.8,
        description: 'A scenic beach surrounded by hills.',
        openHours: 'Open 24 hours',
        estimatedTime: '2 - 3 hours',
        imagePath: 'assets/images/nai_harn_beach.jpg',
        icon: Icons.waves_rounded,
        gradientColors: [
          Color(0xFF0F766E),
          Color(0xFF14B8A6),
          Color(0xFF99F6E4),
        ],
        tags: [PoiTag('Peaceful', Color(0xFFEEF5EE), Color(0xFF16A34A))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.8 · 3,241 views',
      poi: m(
        name: 'The Big Buddha',
        location: 'Karon, Phuket',
        category: 'Temple',
        rating: 4.8,
        description: 'A famous landmark with panoramic views.',
        openHours: '8:00 AM - 7:30 PM',
        estimatedTime: '1 - 2 hours',
        imagePath: 'assets/images/the_big_buddha.jpg',
        icon: Icons.temple_buddhist_rounded,
        gradientColors: [
          Color(0xFF0A7FAB),
          Color(0xFF1AAECF),
          Color(0xFF7DD8EF),
        ],
        tags: [PoiTag('Must See', Color(0xFFEAF8FD), Color(0xFF0A7FAB))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.8 · 1,956 views',
      poi: m(
        name: 'Wat Chalong',
        location: 'Chalong, Phuket',
        category: 'Temple',
        rating: 4.8,
        description: 'A significant Buddhist temple complex.',
        openHours: '7:00 AM - 5:00 PM',
        estimatedTime: '1 hour',
        imagePath: 'assets/images/wat_chalong.jpg',
        icon: Icons.account_balance_rounded,
        gradientColors: [
          Color(0xFFFBBF24),
          Color(0xFFF59E0B),
          Color(0xFFFDE68A),
        ],
        tags: [PoiTag('Temple', Color(0xFFFDF5E7), Color(0xFFC8912E))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.9 · 2,670 views',
      poi: m(
        name: 'Phuket Elephant Sanctuary',
        location: 'Paklok, Phuket',
        category: 'Nature',
        rating: 4.9,
        description: 'An ethical elephant sanctuary.',
        openHours: '9:00 AM - 5:00 PM',
        estimatedTime: '2 - 3 hours',
        priceRange: '฿฿฿',
        imagePath: 'assets/images/phuket_elephant_sanctuary.jpg',
        icon: Icons.pets_rounded,
        gradientColors: [
          Color(0xFF16A34A),
          Color(0xFF22C55E),
          Color(0xFF86EFAC),
        ],
        tags: [PoiTag('Nature', Color(0xFFEEF5EE), Color(0xFF16A34A))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.6 · 890 views',
      poi: m(
        name: 'Sirinat National Park',
        location: 'North Phuket',
        category: 'Nature',
        rating: 4.6,
        description: 'A peaceful area with beaches and forest.',
        openHours: '8:00 AM - 6:00 PM',
        estimatedTime: '2 - 4 hours',
        priceRange: '฿',
        imagePath: 'assets/images/sirinat_national_park.jpg',
        icon: Icons.park_rounded,
        gradientColors: [
          Color(0xFF15803D),
          Color(0xFF22C55E),
          Color(0xFFBBF7D0),
        ],
        tags: [PoiTag('Nature', Color(0xFFEEF5EE), Color(0xFF16A34A))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.3 · 420 views',
      poi: m(
        name: 'Koh Sirey',
        location: 'East Phuket',
        category: 'Nature',
        rating: 4.3,
        description: 'A small island with mangrove forests.',
        openHours: 'Open 24 hours',
        estimatedTime: '1 - 2 hours',
        imagePath: 'assets/images/koh_sirey.jpg',
        icon: Icons.forest_rounded,
        gradientColors: [
          Color(0xFF166534),
          Color(0xFF4ADE80),
          Color(0xFFBBF7D0),
        ],
        tags: [PoiTag('Nature', Color(0xFFEEF5EE), Color(0xFF16A34A))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.9 · 2,103 views',
      poi: m(
        name: 'Old Phuket Town',
        location: 'Phuket City',
        category: 'Culture',
        rating: 4.9,
        description: 'Historic streets, colorful buildings, and cafes.',
        openHours: 'Open 24 hours',
        estimatedTime: '2 - 3 hours',
        imagePath: 'assets/images/old_phuket_town.jpg',
        icon: Icons.location_city_rounded,
        gradientColors: [
          Color(0xFF8B4513),
          Color(0xFFC8912E),
          Color(0xFFF0C060),
        ],
        tags: [PoiTag('Heritage', Color(0xFFFDF0EE), Color(0xFFE8634C))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.5 · 1,340 views',
      poi: m(
        name: 'Phuket Fantasea',
        location: 'Kamala, Phuket',
        category: 'Culture',
        rating: 4.5,
        description: 'A spectacular cultural theme park.',
        openHours: '5:30 PM - 11:30 PM',
        estimatedTime: '3 - 4 hours',
        priceRange: '฿฿฿',
        imagePath: 'assets/images/phuket_fantasea.jpg',
        icon: Icons.celebration_rounded,
        gradientColors: [
          Color(0xFF7C3AED),
          Color(0xFFA855F7),
          Color(0xFFE9D5FF),
        ],
        tags: [PoiTag('Culture', Color(0xFFFDF5E7), Color(0xFFC8912E))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.6 · 1,105 views',
      poi: m(
        name: 'Rawai Seafood Market',
        location: 'Rawai, Phuket',
        category: 'Food',
        rating: 4.6,
        description: 'Fresh seafood cooked on the spot.',
        openHours: '9:00 AM - 9:00 PM',
        estimatedTime: '1 - 2 hours',
        priceRange: '฿฿',
        imagePath: 'assets/images/rawai_seafood_market.jpg',
        icon: Icons.set_meal_rounded,
        gradientColors: [
          Color(0xFFE8634C),
          Color(0xFFF97316),
          Color(0xFFFED7AA),
        ],
        tags: [PoiTag('Seafood', Color(0xFFFDF0EE), Color(0xFFE8634C))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.7 · 1,488 views',
      poi: m(
        name: 'Phuket Town Walking Street',
        location: 'Phuket City',
        category: 'Food',
        rating: 4.7,
        description: 'A vibrant Sunday night market.',
        openHours: 'Sun 4:00 PM - 10:00 PM',
        estimatedTime: '1 - 2 hours',
        priceRange: '฿',
        imagePath: 'assets/images/phuket_town_walking_street.jpg',
        icon: Icons.restaurant_rounded,
        gradientColors: [
          Color(0xFFD97706),
          Color(0xFFF59E0B),
          Color(0xFFFDE68A),
        ],
        tags: [PoiTag('Street Food', Color(0xFFFDF0EE), Color(0xFFE8634C))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.7 · 780 views',
      poi: m(
        name: 'Blue Elephant Restaurant',
        location: 'Old Town, Phuket',
        category: 'Food',
        rating: 4.7,
        description: 'Award-winning Thai cuisine.',
        openHours: '11:30 AM - 10:00 PM',
        estimatedTime: '1.5 - 2 hours',
        priceRange: '฿฿฿',
        imagePath: 'assets/images/blue_elephant_restaurant.jpg',
        icon: Icons.dining_rounded,
        gradientColors: [
          Color(0xFF1D4ED8),
          Color(0xFF3B82F6),
          Color(0xFFBFDBFE),
        ],
        tags: [PoiTag('Fine Dining', Color(0xFFFDF5E7), Color(0xFFC8912E))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.2 · 620 views',
      poi: m(
        name: 'Tiger Kingdom',
        location: 'Kathu, Phuket',
        category: 'Adventure',
        rating: 4.2,
        description: 'Get up close with tigers.',
        openHours: '9:00 AM - 6:00 PM',
        estimatedTime: '1 - 2 hours',
        priceRange: '฿฿฿',
        imagePath: 'assets/images/tiger_kingdom.jpg',
        icon: Icons.pets_rounded,
        gradientColors: [
          Color(0xFFEA580C),
          Color(0xFFF97316),
          Color(0xFFFED7AA),
        ],
        tags: [PoiTag('Adventure', Color(0xFFFDF0EE), Color(0xFFE8634C))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.5 · 950 views',
      poi: m(
        name: 'ATV & Zipline Tour',
        location: 'Kathu, Phuket',
        category: 'Adventure',
        rating: 4.5,
        description: 'ATV rides and zipline over canopy.',
        openHours: '8:00 AM - 5:00 PM',
        estimatedTime: '2 - 3 hours',
        priceRange: '฿฿฿',
        imagePath: 'assets/images/atv_&_zipline.jpg',
        icon: Icons.directions_bike_rounded,
        gradientColors: [
          Color(0xFF166534),
          Color(0xFF16A34A),
          Color(0xFF86EFAC),
        ],
        tags: [PoiTag('Thrill', Color(0xFFFDF0EE), Color(0xFFE8634C))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.9 · 3,500 views',
      poi: m(
        name: 'Phi Phi Islands Day Trip',
        location: 'Rassada Pier, Phuket',
        category: 'Adventure',
        rating: 4.9,
        description: 'Full-day boat tour to Phi Phi Islands.',
        openHours: '7:30 AM - 6:00 PM',
        estimatedTime: 'Full Day',
        priceRange: '฿฿฿',
        imagePath: 'assets/images/phi_phi_island.jpg',
        icon: Icons.sailing_rounded,
        gradientColors: [
          Color(0xFF0369A1),
          Color(0xFF0EA5E9),
          Color(0xFF7DD3FC),
        ],
        tags: [PoiTag('Must Do', Color(0xFFEAF8FD), Color(0xFF0A7FAB))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.3 · 1,780 views',
      poi: m(
        name: 'Bangla Road',
        location: 'Patong, Phuket',
        category: 'Nightlife',
        rating: 4.3,
        description: 'A famous nightlife street.',
        openHours: '6:00 PM - Late',
        estimatedTime: '1 - 3 hours',
        priceRange: '฿฿',
        imagePath: 'assets/images/bangla_road.jpg',
        icon: Icons.nightlife_rounded,
        gradientColors: [
          Color(0xFF7C3AED),
          Color(0xFFDB2777),
          Color(0xFFF472B6),
        ],
        tags: [PoiTag('Nightlife', Color(0xFFFDF0EE), Color(0xFFE8634C))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.4 · 540 views',
      poi: m(
        name: 'Illuzion Club',
        location: 'Patong, Phuket',
        category: 'Nightlife',
        rating: 4.4,
        description: 'One of Phuket\'s biggest clubs.',
        openHours: '9:00 PM - Late',
        estimatedTime: '2 - 4 hours',
        priceRange: '฿฿',
        imagePath: 'assets/images/illuzion_club.jpg',
        icon: Icons.music_note_rounded,
        gradientColors: [
          Color(0xFF4C1D95),
          Color(0xFF7C3AED),
          Color(0xFFC4B5FD),
        ],
        tags: [PoiTag('Club', Color(0xFFFDF0EE), Color(0xFFE8634C))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.3 · 380 views',
      poi: m(
        name: 'Thalang National Museum',
        location: 'Thalang, Phuket',
        category: 'Heritage',
        rating: 4.3,
        description: 'Explore Phuket\'s history.',
        openHours: '9:00 AM - 4:00 PM',
        estimatedTime: '1 - 1.5 hours',
        priceRange: '฿',
        imagePath: 'assets/images/thalang_national_museum.jpg',
        icon: Icons.museum_rounded,
        gradientColors: [
          Color(0xFF92400E),
          Color(0xFFB45309),
          Color(0xFFFDE68A),
        ],
        tags: [PoiTag('History', Color(0xFFFDF5E7), Color(0xFFC8912E))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.9 · 2,340 views',
      poi: m(
        name: 'Promthep Cape',
        location: 'Rawai, Phuket',
        category: 'Viewpoint',
        rating: 4.9,
        description: 'One of the best sunset viewpoints.',
        openHours: 'Open 24 hours',
        estimatedTime: '45 mins - 1 hour',
        imagePath: 'assets/images/promthep_cape.jpg',
        icon: Icons.wb_sunny_rounded,
        gradientColors: [
          Color(0xFFF59E0B),
          Color(0xFFF97316),
          Color(0xFFFB7185),
        ],
        tags: [PoiTag('Sunset', Color(0xFFFDF5E7), Color(0xFFC8912E))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.7 · 1,060 views',
      poi: m(
        name: 'Karon Viewpoint',
        location: 'Karon, Phuket',
        category: 'Viewpoint',
        rating: 4.7,
        description: 'Panoramic viewpoint overlooking three beaches.',
        openHours: 'Open 24 hours',
        estimatedTime: '30 - 45 mins',
        imagePath: 'assets/images/karon_viewpoint.jpg',
        icon: Icons.landscape_rounded,
        gradientColors: [
          Color(0xFF0EA5E9),
          Color(0xFF2563EB),
          Color(0xFF93C5FD),
        ],
        tags: [PoiTag('Viewpoint', Color(0xFFEAF8FD), Color(0xFF0A7FAB))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.4 · 710 views',
      poi: m(
        name: 'Phuket Aquarium',
        location: 'Cape Panwa, Phuket',
        category: 'Attraction',
        rating: 4.4,
        description: 'A family-friendly aquarium.',
        openHours: '8:30 AM - 4:30 PM',
        estimatedTime: '1 - 2 hours',
        priceRange: '฿฿',
        imagePath: 'assets/images/phuket_aquarium.jpg',
        icon: Icons.set_meal_rounded,
        gradientColors: [
          Color(0xFF06B6D4),
          Color(0xFF0891B2),
          Color(0xFF67E8F9),
        ],
        tags: [PoiTag('Family', Color(0xFFEEF5EE), Color(0xFF16A34A))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.3 · 1,220 views',
      poi: m(
        name: 'Jungceylon',
        location: 'Patong, Phuket',
        category: 'Shopping',
        rating: 4.3,
        description: 'Patong\'s largest shopping complex.',
        openHours: '11:00 AM - 10:00 PM',
        estimatedTime: '2 - 3 hours',
        priceRange: '฿฿',
        imagePath: 'assets/images/jungceylon.jpg',
        icon: Icons.shopping_bag_rounded,
        gradientColors: [
          Color(0xFF475569),
          Color(0xFF64748B),
          Color(0xFFCBD5E1),
        ],
        tags: [PoiTag('Shopping', Color(0xFFFDF0EE), Color(0xFFE8634C))],
      ),
    ),
    _AdminPoi(
      viewsText: '4.5 · 980 views',
      poi: m(
        name: 'Central Festival Phuket',
        location: 'Vichitsongkram Rd',
        category: 'Shopping',
        rating: 4.5,
        description: 'A massive lifestyle mall.',
        openHours: '10:30 AM - 10:00 PM',
        estimatedTime: '2 - 4 hours',
        priceRange: '฿฿',
        imagePath: 'assets/images/central_festival_phuket.jpg',
        icon: Icons.store_rounded,
        gradientColors: [
          Color(0xFF1E293B),
          Color(0xFF334155),
          Color(0xFF94A3B8),
        ],
        tags: [PoiTag('Shopping', Color(0xFFFDF0EE), Color(0xFFE8634C))],
      ),
    ),
  ];

  // Merge admin-created POIs
  final adminCreated = AppStore.adminCreatedPois
      .map(
        (p) => _AdminPoi(
          viewsText: '0.0 · New',
          poi: PoiModel(
            name: p.name,
            location: p.location,
            category: p.category,
            rating: p.rating,
            description: p.description,
            longDescription: p.longDescription,
            openHours: p.openHours,
            estimatedTime: p.estimatedTime,
            priceRange: p.priceRange,
            imagePath: p.imagePath,
            gradientColors: p.gradientColors,
            icon: p.icon,
            tags: [PoiTag(p.tagLabel, p.tagBg, p.tagFg)],
          ),
        ),
      )
      .toList();

  return [
    ...hardcoded,
    ...adminCreated,
  ].where((ap) => !AppStore.deletedPois.contains(ap.poi.name)).toList();
}


// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class AdminPoiScreen extends StatefulWidget {
  const AdminPoiScreen({super.key});
  @override
  State<AdminPoiScreen> createState() => _AdminPoiScreenState();
}

class _AdminPoiScreenState extends State<AdminPoiScreen> {
  int _selectedCat = 0;
  String _searchQuery = '';
  List<_AdminPoi> _firestorePois = [];
  bool _loaded = false;

  Future<void> _loadPois() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pois')
          .get();

      final pois = snapshot.docs.map((doc) {
        final d = doc.data();
        final category = d['category'] as String? ?? '';
        final tags = (d['tags'] as List<dynamic>? ?? []).cast<String>();
        final status = d['status'] as String? ?? 'active';
        final rating = (d['rating'] as num?)?.toDouble() ?? 0.0;

        PoiStatus poiStatus;
        switch (status) {
          case 'hidden': poiStatus = PoiStatus.hidden; break;
          case 'review': poiStatus = PoiStatus.review; break;
          default: poiStatus = PoiStatus.active;
        }

        return _AdminPoi(
          poi: PoiModel(
            name: d['name'] as String? ?? '',
            location: d['location'] as String? ?? '',
            category: category,
            rating: rating,
            description: d['description'] as String? ?? '',
            longDescription: d['longDescription'] as String? ?? '',
            openHours: d['openHours'] as String? ?? '',
            estimatedTime: d['estimatedTime'] as String? ?? '',
            priceRange: d['priceRange'] as String? ?? 'Free',
            imagePath: d['imagePath'] as String? ?? '',
            gradientColors: _colorsForCategory(category),
            icon: _iconForCategory(category),
            tags: tags.map((t) {
              final c = _tagColors(t);
              return PoiTag(t, c.$1, c.$2);
            }).toList(),
          ),
          viewsText: '${rating.toStringAsFixed(1)} · ${d['createdBy'] == 'admin' ? 'Admin' : 'Seed'}',
          firestoreDocId: doc.id,
          firestoreStatus: poiStatus,
          latitude: (d['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (d['longitude'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _firestorePois = pois;
          _loaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  static IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'beach': return Icons.beach_access_rounded;
      case 'temple': return Icons.temple_buddhist_rounded;
      case 'nature': return Icons.forest_rounded;
      case 'culture': return Icons.account_balance_rounded;
      case 'food': return Icons.restaurant_rounded;
      case 'adventure': return Icons.surfing_rounded;
      case 'nightlife': return Icons.nightlife_rounded;
      case 'heritage': return Icons.location_city_rounded;
      case 'viewpoint': return Icons.landscape_rounded;
      case 'attraction': return Icons.attractions_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      default: return Icons.place_rounded;
    }
  }

  static List<Color> _colorsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'beach': return const [Color(0xFF0A7FAB), Color(0xFF38BDF8), Color(0xFF93C5FD)];
      case 'temple': return const [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFFDE68A)];
      case 'nature': return const [Color(0xFF16A34A), Color(0xFF22C55E), Color(0xFF86EFAC)];
      case 'culture': return const [Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFFE9D5FF)];
      case 'food': return const [Color(0xFFE8634C), Color(0xFFF97316), Color(0xFFFED7AA)];
      case 'adventure': return const [Color(0xFF166534), Color(0xFF16A34A), Color(0xFF86EFAC)];
      case 'nightlife': return const [Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFF472B6)];
      case 'heritage': return const [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFFDE68A)];
      case 'viewpoint': return const [Color(0xFFF59E0B), Color(0xFFF97316), Color(0xFFFB7185)];
      case 'attraction': return const [Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF67E8F9)];
      case 'shopping': return const [Color(0xFF475569), Color(0xFF64748B), Color(0xFFCBD5E1)];
      default: return const [Color(0xFF0A7FAB), Color(0xFF1AAECF), Color(0xFF7DD8EF)];
    }
  }

  static (Color, Color) _tagColors(String tag) {
    switch (tag.toLowerCase()) {
      case 'beach': case 'popular': case 'must see': case 'must do':
      case 'hidden gem': case 'scenic': case 'ethical': case 'viewpoint':
      case 'indoor': case 'relax': case 'mangrove':
        return (const Color(0xFFEAF8FD), const Color(0xFF0A7FAB));
      case 'nature': case 'peaceful': case 'wildlife': case 'outdoor':
      case 'snorkel': case 'family':
        return (const Color(0xFFEEF5EE), const Color(0xFF16A34A));
      case 'culture': case 'temple': case 'upscale': case 'heritage':
      case 'history': case 'fine dining': case 'luxury': case 'sunset':
      case 'local': case 'market':
        return (const Color(0xFFFDF5E7), const Color(0xFFC8912E));
      case 'food': case 'seafood': case 'nightlife': case 'adventure':
      case 'thrill': case 'show': case 'street food': case 'thai':
      case 'club': case 'museum': case 'shopping':
        return (const Color(0xFFFDF0EE), const Color(0xFFE8634C));
      case 'music':
        return (const Color(0xFFEDE9FE), const Color(0xFF7C3AED));
      default:
        return (const Color(0xFFEAF8FD), const Color(0xFF0A7FAB));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPois();
    AppStore.addListener(_rebuild);
  }

  @override
  void dispose() {
    AppStore.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  List<_AdminPoi> get _allPois => _firestorePois.isNotEmpty ? _firestorePois : _buildAllPois();

  List<String> get _cats {
    final pois = _allPois;
    final cc = <String, int>{};
    for (final ap in pois) {
      cc[ap.poi.category] = (cc[ap.poi.category] ?? 0) + 1;
    }
    return [
      'All (${pois.length})',
      ...cc.entries.map((e) => '${e.key} (${e.value})'),
    ];
  }

  List<_AdminPoi> get _filteredPois {
    final cats = _cats;
    final cl = _selectedCat == 0 || _selectedCat >= cats.length
        ? 'all'
        : cats[_selectedCat]
              .replaceAll(RegExp(r'\s*\(\d+\)'), '')
              .toLowerCase();
    return _allPois.where((ap) {
      final mc = cl == 'all' || ap.poi.category.toLowerCase() == cl;
      final q = _searchQuery.trim().toLowerCase();
      final ms =
          q.isEmpty ||
          ap.poi.name.toLowerCase().contains(q) ||
          ap.poi.location.toLowerCase().contains(q) ||
          ap.poi.category.toLowerCase().contains(q);
      return mc && ms;
    }).toList();
  }

  int get _activeCount =>
      _allPois.where((p) => p.status == PoiStatus.active).length;
  int get _hiddenCount =>
      _allPois.where((p) => p.status == PoiStatus.hidden).length;
  int get _reviewCount =>
      _allPois.where((p) => p.status == PoiStatus.review).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPois;
    final cats = _cats;
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          AdminTopNavPage(
            title: 'Manage POIs',
            showBack: false,
            action: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCreatePoiScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AC.ocean, AC.oceanMid],
                  ),
                  borderRadius: BorderRadius.circular(AR.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Add POI',
                      style: adminUi(
                        size: 12,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _searchRow(),
          _chipRow(cats),
          _strip(),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 32,
                          color: AC.text3,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No POIs found',
                          style: adminUi(
                            size: 14,
                            weight: FontWeight.w600,
                            color: AC.text2,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _card(filtered[i]),
                    ),
                  ),
          ),
          AdminBottomNav(activeIndex: 1),
        ],
      ),
    );
  }

  // ── Search ──
  Widget _searchRow() => Container(
    color: AC.navy,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AR.full),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 15,
            color: Colors.white.withOpacity(0.40),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: adminUi(size: 13, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search POIs…',
                hintStyle: adminUi(
                  size: 13,
                  color: Colors.white.withOpacity(0.40),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ── Chips ──
  Widget _chipRow(List<String> cats) => Container(
    color: AC.navy,
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      itemCount: cats.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final a = i == _selectedCat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCat = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: a
                  ? AC.ocean.withOpacity(0.20)
                  : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(AR.full),
              border: Border.all(
                color: a
                    ? AC.ocean.withOpacity(0.40)
                    : Colors.white.withOpacity(0.10),
              ),
            ),
            child: Text(
              cats[i],
              style: adminUi(
                size: 12,
                weight: FontWeight.w700,
                color: a ? AC.oceanMid : Colors.white.withOpacity(0.50),
              ),
            ),
          ),
        );
      },
    ),
  );

  // ── Strip ──
  Widget _strip() {
    final items = [
      ('$_activeCount', 'Active', AC.green),
      ('$_hiddenCount', 'Hidden', AC.amber),
      ('$_reviewCount', 'Review', AC.ocean),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AC.surface,
        border: Border(bottom: BorderSide(color: AC.borderLight)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        items[i].$1,
                        style: adminMono(size: 18, color: items[i].$3),
                      ),
                      Text(
                        items[i].$2,
                        style: adminUi(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AC.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: AC.borderLight,
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Card ──
  Widget _card(_AdminPoi ap) {
    final poi = ap.poi;
    final s = ap.status;
    final cc = _catClr(poi.category);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PoiDetailScreen(poi: poi)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AC.surface,
          borderRadius: BorderRadius.circular(AR.card),
          border: Border.all(color: AC.borderLight),
          boxShadow: aShadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (s == PoiStatus.hidden)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AC.amber.withOpacity(0.06),
                  border: Border(
                    left: BorderSide(color: AC.amber, width: 3),
                    bottom: BorderSide(color: AC.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_off_rounded,
                      size: 14,
                      color: AC.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hidden from tourists — tap "Show" to restore',
                        style: adminUi(size: 11, color: AC.amber),
                      ),
                    ),
                  ],
                ),
              ),
            Opacity(
              opacity: s == PoiStatus.hidden ? 0.65 : 1.0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AR.md),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: poi.imagePath.isNotEmpty
                            ? (poi.imagePath.startsWith('http')
                                ? Image.network(
                                    poi.imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _gt(poi),
                                  )
                                : Image.asset(
                                    poi.imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _gt(poi),
                                  ))
                            : _gt(poi),
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
                                  style: adminUi(
                                    size: 14,
                                    weight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _badge(s),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _meta(Icons.location_on_rounded, poi.location),
                              if (ap.viewsText != null)
                                _meta(Icons.star_rounded, ap.viewsText!),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cc.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(AR.full),
                                ),
                                child: Text(
                                  poi.category,
                                  style: adminUi(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: cc,
                                  ),
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
            const Divider(height: 1, color: AC.borderLight),
            _actions(ap),
          ],
        ),
      ),
    );
  }

  Widget _gt(PoiModel p) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: p.gradientColors,
      ),
    ),
    child: Icon(p.icon, size: 22, color: Colors.white.withOpacity(0.85)),
  );

  Color _catClr(String c) => switch (c.toLowerCase()) {
    'beach' => AC.ocean,
    'temple' => AC.gold,
    'nature' => AC.green,
    'culture' => AC.purple,
    'food' => AC.coral,
    'adventure' => AC.coral,
    'nightlife' => AC.purple,
    'heritage' => AC.gold,
    'viewpoint' => AC.ocean,
    'attraction' => AC.ocean,
    'shopping' => AC.amber,
    _ => AC.text2,
  };

  Widget _badge(PoiStatus s) {
    final (Color bg, Color fg, String l) = switch (s) {
      PoiStatus.active => (AC.greenTint, AC.green, 'Active'),
      PoiStatus.hidden => (AC.amberTint, AC.amber, 'Hidden'),
      PoiStatus.review => (AC.oceanTint, AC.ocean, 'Review'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AR.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fg),
          ),
          const SizedBox(width: 4),
          Text(
            l,
            style: adminUi(size: 10, weight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData i, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(i, size: 12, color: AC.text3),
      const SizedBox(width: 3),
      Text(t, style: adminUi(size: 11, color: AC.text2)),
    ],
  );

  // ══════════════════════════════════════════════════════════
  // ACTION BUTTONS — ALL WIRED TO APPSTORE (REAL-TIME)
  // ══════════════════════════════════════════════════════════
  Widget _actions(_AdminPoi ap) {
    final n = ap.poi.name;
    late List<(IconData, String, Color, VoidCallback)> acts;
    switch (ap.status) {
      case PoiStatus.active:
        acts = [
          (
            Icons.edit_rounded,
            'Edit',
            AC.ocean,
            () => _openEditScreen(ap),
          ),
          (
            Icons.visibility_off_rounded,
            'Hide',
            AC.amber,
            () async {
              if (ap.firestoreDocId != null) {
                await FirebaseFirestore.instance.collection('pois').doc(ap.firestoreDocId).update({'status': 'hidden'});
              }
              AppStore.hidePoi(n);
              AppStore.logActivity(category: 'poi', title: 'POI hidden', sub: '$n → Hidden');
              _loadPois();
              _snack('"$n" hidden from tourists');
            },
          ),
          (Icons.delete_rounded, 'Delete', AC.coral, () => _confirmDelete(ap)),
        ];
      case PoiStatus.hidden:
        acts = [
          (
            Icons.edit_rounded,
            'Edit',
            AC.ocean,
            () => _openEditScreen(ap),
          ),
          (
            Icons.visibility_rounded,
            'Show',
            AC.green,
            () async {
              if (ap.firestoreDocId != null) {
                await FirebaseFirestore.instance.collection('pois').doc(ap.firestoreDocId).update({'status': 'active'});
              }
              AppStore.showPoi(n);
              AppStore.logActivity(category: 'poi', title: 'POI restored', sub: '$n → Active');
              _loadPois();
              _snack('"$n" is now visible');
            },
          ),
          (Icons.delete_rounded, 'Delete', AC.coral, () => _confirmDelete(ap)),
        ];
      case PoiStatus.review:
        acts = [
          (
            Icons.check_circle_rounded,
            'Approve',
            AC.green,
            () async {
              if (ap.firestoreDocId != null) {
                await FirebaseFirestore.instance.collection('pois').doc(ap.firestoreDocId).update({'status': 'active'});
              }
              AppStore.approvePoi(n);
              AppStore.logActivity(category: 'poi', title: 'POI approved', sub: '$n → Active');
              _loadPois();
              _snack('"$n" approved!');
            },
          ),
          (
            Icons.edit_rounded,
            'Edit',
            AC.ocean,
            () => _openEditScreen(ap),
          ),
          (
            Icons.close_rounded,
            'Reject',
            AC.coral,
            () => _confirmDelete(ap, reject: true),
          ),
        ];
    }
    return IntrinsicHeight(
      child: Row(
        children: acts.asMap().entries.map((e) {
          final i = e.key;
          final a = e.value;
          return Expanded(
            child: GestureDetector(
              onTap: a.$4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    right: i < acts.length - 1
                        ? const BorderSide(color: AC.borderLight)
                        : BorderSide.none,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(a.$1, size: 16, color: a.$3),
                    const SizedBox(height: 3),
                    Text(
                      a.$2,
                      style: adminUi(
                        size: 11,
                        weight: FontWeight.w700,
                        color: a.$3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openEditScreen(_AdminPoi ap) async {
    final poi = ap.poi;

    List<String> transportAccess = [];
    if (ap.firestoreDocId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('pois')
            .doc(ap.firestoreDocId)
            .get();
        if (doc.exists) {
          transportAccess = List<String>.from(
              doc.data()?['transportAccess'] as List? ?? []);
        }
      } catch (_) {}
    }

    if (!mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditPoiScreen(
          firestoreDocId: ap.firestoreDocId,
          initialName: poi.name,
          initialDescription: poi.description,
          initialLongDescription: poi.longDescription,
          initialCategory: poi.category,
          initialLocation: poi.location,
          initialPriceRange: poi.priceRange,
          initialEstimatedTime: poi.estimatedTime,
          initialOpenHours: poi.openHours,
          initialLatitude: ap.latitude,
          initialLongitude: ap.longitude,
          initialTransportAccess: transportAccess,
          initialImagePath: ap.poi.imagePath,
        ),
      ),
    );

    if (saved == true) {
      _loadPois();
    }
  }

  void _confirmDelete(_AdminPoi ap, {bool reject = false}) {
    final name = ap.poi.name;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AC.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AR.xl)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AC.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              reject ? Icons.close_rounded : Icons.delete_rounded,
              size: 36,
              color: AC.coral,
            ),
            const SizedBox(height: 12),
            Text(
              reject ? 'Reject POI?' : 'Delete POI?',
              style: adminDisplay(size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              '"$name" will be permanently removed.',
              style: adminUi(size: 13, color: AC.text2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AC.surface,
                        borderRadius: BorderRadius.circular(AR.full),
                        border: Border.all(color: AC.border),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: adminUi(
                            size: 14,
                            weight: FontWeight.w700,
                            color: AC.text1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (ap.firestoreDocId != null) {
                        await FirebaseFirestore.instance.collection('pois').doc(ap.firestoreDocId).delete();
                      }
                      reject ? AppStore.rejectPoi(name) : AppStore.deletePoi(name);
                      AppStore.logActivity(
                        category: 'poi',
                        title: reject ? 'POI rejected' : 'POI deleted',
                        sub: '$name permanently removed',
                      );
                      _loadPois();
                      _snack('"$name" ${reject ? "rejected" : "deleted"}');
                    },
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AC.coral,
                        borderRadius: BorderRadius.circular(AR.full),
                      ),
                      child: Center(
                        child: Text(
                          reject ? 'Reject' : 'Delete',
                          style: adminUi(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AC.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: Text(m, style: adminUi(size: 13, color: Colors.white)),
      duration: const Duration(seconds: 2),
    ),
  );
}
