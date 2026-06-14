// ============================================================
// AndaMove — Home Screen (Updated with POI Images)
// File: lib/screens/screen5_home.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screen13_notification.dart';
import 'screen14_explore.dart';
import 'screen6_POI.dart';
import 'screen7_generateItinerary.dart';
import 'screen11_trips.dart';
import 'screen12_profile.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../app_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_bottom_nav.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter/rendering.dart' show ScrollDirection;

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
List<BoxShadow> get shadowMd => [
  BoxShadow(
    color: const Color(0xFF0A1F28).withOpacity(0.08),
    blurRadius: 16,
    offset: const Offset(0, 4),
  ),
];
List<BoxShadow> get shadowLg => [
  BoxShadow(
    color: const Color(0xFF0A1F28).withOpacity(0.12),
    blurRadius: 32,
    offset: const Offset(0, 12),
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

class _Category {
  final String label;
  final IconData icon;
  const _Category(this.label, this.icon);
}

class _PoiTag {
  final String label;
  final Color bg;
  final Color fg;
  const _PoiTag(this.label, this.bg, this.fg);
}

class _PoiCard {
  final String name;
  final String location;
  final String category;
  final double rating;
  final String description;
  final String longDescription; // ← ADD THIS (for POI detail)
  final String openHours;
  final String estimatedTime;
  final String priceRange;
  final String imagePath; // ← local asset image
  final IconData placeholderIcon; // ← fallback if image fails
  final List<Color> gradientColors;
  final bool isFavourited;
  final List<_PoiTag> tags;
  final double latitude;
  final double longitude;

  const _PoiCard({
    required this.name,
    required this.location,
    required this.category,
    required this.rating,
    required this.description,
    required this.longDescription, // ← ADD THIS
    required this.openHours,
    required this.estimatedTime,
    this.priceRange = 'Free',
    required this.imagePath,
    required this.placeholderIcon,
    required this.gradientColors,
    this.isFavourited = false,
    required this.tags,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<_WeatherStat> _weatherFuture;

  int _selectedCat = 0;
  int _selectedNav = 0;
  int _activeTipIndex = 0;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  double _minRating = 0.0;
  bool _showFavouritesOnly = false;
  String _selectedPrice = 'All';

  List<_PoiCard> _firestorePois = [];
  bool _poisLoaded = false;

  final ScrollController _scrollCtrl = ScrollController();
  bool _headerVisible = true;

  // ADD this method inside _HomeScreenState (e.g. after _searchQuery declarations):
  void _onStoreUpdate() => setState(() {});

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!.split(' ').first;
      }
      if (user.email != null) {
        return user.email!.split('@').first;
      }
    }
    return 'Explorer';
  }

  String get _greetingLabel {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  Future<void> _loadPoisFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pois')
          .where('status', isEqualTo: 'active')
          .get();

      final pois = snapshot.docs.map((doc) {
        final d = doc.data();
        final tags = (d['tags'] as List<dynamic>? ?? []).cast<String>();
        final category = d['category'] as String? ?? '';

        return _PoiCard(
          name: d['name'] as String? ?? '',
          location: d['location'] as String? ?? '',
          category: category,
          rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
          description: d['description'] as String? ?? '',
          longDescription:
              d['longDescription'] as String? ??
              d['description'] as String? ??
              '',
          openHours: d['openHours'] as String? ?? '',
          estimatedTime: d['estimatedTime'] as String? ?? '',
          priceRange: d['priceRange'] as String? ?? 'Free',
          imagePath: d['imagePath'] as String? ?? '',
          placeholderIcon: _iconForCategory(category),
          gradientColors: _colorsForCategory(category),
          tags: tags.map((t) => _poiTagFromString(t, category)).toList(),
          latitude: (d['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (d['longitude'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _firestorePois = pois;
          _poisLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _poisLoaded = true);
    }
  }

  static IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'beach':
        return Icons.beach_access_rounded;
      case 'temple':
        return Icons.temple_buddhist_rounded;
      case 'nature':
        return Icons.forest_rounded;
      case 'culture':
        return Icons.account_balance_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'adventure':
        return Icons.surfing_rounded;
      case 'nightlife':
        return Icons.nightlife_rounded;
      case 'heritage':
        return Icons.location_city_rounded;
      case 'viewpoint':
        return Icons.landscape_rounded;
      case 'attraction':
        return Icons.attractions_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  static List<Color> _colorsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'beach':
        return const [Color(0xFF0A7FAB), Color(0xFF38BDF8), Color(0xFF93C5FD)];
      case 'temple':
        return const [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFFDE68A)];
      case 'nature':
        return const [Color(0xFF16A34A), Color(0xFF22C55E), Color(0xFF86EFAC)];
      case 'culture':
        return const [Color(0xFF8B4513), Color(0xFFC8912E), Color(0xFFF0C060)];
      case 'food':
        return const [Color(0xFFE8634C), Color(0xFFF97316), Color(0xFFFED7AA)];
      case 'adventure':
        return const [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF7DD3FC)];
      case 'nightlife':
        return const [Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFF472B6)];
      case 'heritage':
        return const [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFFDE68A)];
      case 'viewpoint':
        return const [Color(0xFFF59E0B), Color(0xFFF97316), Color(0xFFFB7185)];
      case 'attraction':
        return const [Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF67E8F9)];
      case 'shopping':
        return const [Color(0xFF475569), Color(0xFF64748B), Color(0xFFCBD5E1)];
      default:
        return const [Color(0xFF0A7FAB), Color(0xFF1AAECF), Color(0xFF7DD8EF)];
    }
  }

  static _PoiTag _poiTagFromString(String tag, String category) {
    const colors = <String, (Color, Color)>{
      'beach': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
      'nature': (Color(0xFFEEF5EE), Color(0xFF16A34A)),
      'culture': (Color(0xFFFDF5E7), Color(0xFFC8912E)),
      'temple': (Color(0xFFFDF5E7), Color(0xFFC8912E)),
      'food': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'seafood': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'nightlife': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'popular': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
      'must see': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
      'must do': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
      'hidden gem': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
      'peaceful': (Color(0xFFEEF5EE), Color(0xFF16A34A)),
      'scenic': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
      'ethical': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
      'upscale': (Color(0xFFFDF5E7), Color(0xFFC8912E)),
      'heritage': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'history': (Color(0xFFFDF5E7), Color(0xFFC8912E)),
      'show': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'local': (Color(0xFFFDF5E7), Color(0xFFC8912E)),
      'street food': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'market': (Color(0xFFFDF5E7), Color(0xFFC8912E)),
      'fine dining': (Color(0xFFFDF5E7), Color(0xFFC8912E)),
      'thai': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'adventure': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'wildlife': (Color(0xFFEEF5EE), Color(0xFF16A34A)),
      'thrill': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'outdoor': (Color(0xFFEEF5EE), Color(0xFF16A34A)),
      'snorkel': (Color(0xFFEEF5EE), Color(0xFF16A34A)),
      'club': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'music': (Color(0xFFEDE9FE), Color(0xFF7C3AED)),
      'museum': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'sunset': (Color(0xFFFDF5E7), Color(0xFFC8912E)),
      'viewpoint': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
      'family': (Color(0xFFEEF5EE), Color(0xFF16A34A)),
      'indoor': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
      'shopping': (Color(0xFFFDF0EE), Color(0xFFE8634C)),
      'luxury': (Color(0xFFFDF5E7), Color(0xFFC8912E)),
      'relax': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
      'mangrove': (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
    };
    final lower = tag.toLowerCase();
    final c =
        colors[lower] ?? (const Color(0xFFEAF8FD), const Color(0xFF0A7FAB));
    return _PoiTag(tag, c.$1, c.$2);
  }

  static (Color, Color) _getTagColors(String tag) {
    switch (tag.toLowerCase()) {
      case 'beach':
      case 'popular':
      case 'must see':
      case 'must do':
      case 'hidden gem':
      case 'scenic':
      case 'viewpoint':
      case 'indoor':
        return (const Color(0xFFEAF8FD), const Color(0xFF0A7FAB));
      case 'nature':
      case 'peaceful':
      case 'wildlife':
      case 'outdoor':
      case 'family':
      case 'ethical':
        return (const Color(0xFFEEF5EE), const Color(0xFF16A34A));
      case 'culture':
      case 'temple':
      case 'upscale':
      case 'heritage':
      case 'sunset':
      case 'fine dining':
      case 'luxury':
        return (const Color(0xFFFDF5E7), const Color(0xFFC8912E));
      case 'food':
      case 'seafood':
      case 'nightlife':
      case 'adventure':
      case 'shopping':
      case 'club':
      case 'thrill':
        return (const Color(0xFFFDF0EE), const Color(0xFFE8634C));
      default:
        return (const Color(0xFFEAF8FD), const Color(0xFF0A7FAB));
    }
  }

  Future<void> _loadSavedPoisFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedPois')
          .get();

      // Clear existing AppStore saved POIs and reload from Firestore
      AppStore.savedPois.clear();

      for (final doc in snapshot.docs) {
        final d = doc.data();
        final category = d['category'] as String? ?? '';

        IconData icon;
        switch (category.toLowerCase()) {
          case 'beach':
            icon = Icons.beach_access_rounded;
            break;
          case 'temple':
            icon = Icons.temple_buddhist_rounded;
            break;
          case 'nature':
            icon = Icons.forest_rounded;
            break;
          case 'culture':
            icon = Icons.account_balance_rounded;
            break;
          case 'food':
            icon = Icons.restaurant_rounded;
            break;
          case 'adventure':
            icon = Icons.surfing_rounded;
            break;
          case 'nightlife':
            icon = Icons.nightlife_rounded;
            break;
          case 'heritage':
            icon = Icons.location_city_rounded;
            break;
          case 'viewpoint':
            icon = Icons.landscape_rounded;
            break;
          case 'attraction':
            icon = Icons.attractions_rounded;
            break;
          case 'shopping':
            icon = Icons.shopping_bag_rounded;
            break;
          default:
            icon = Icons.place_rounded;
        }

        List<Color> gradColors;
        switch (category.toLowerCase()) {
          case 'beach':
            gradColors = const [
              Color(0xFF0A7FAB),
              Color(0xFF38BDF8),
              Color(0xFF93C5FD),
            ];
            break;
          case 'temple':
            gradColors = const [
              Color(0xFFFBBF24),
              Color(0xFFF59E0B),
              Color(0xFFFDE68A),
            ];
            break;
          case 'nature':
            gradColors = const [
              Color(0xFF16A34A),
              Color(0xFF22C55E),
              Color(0xFF86EFAC),
            ];
            break;
          case 'culture':
            gradColors = const [
              Color(0xFF7C3AED),
              Color(0xFFA855F7),
              Color(0xFFE9D5FF),
            ];
            break;
          case 'food':
            gradColors = const [
              Color(0xFFE8634C),
              Color(0xFFF97316),
              Color(0xFFFED7AA),
            ];
            break;
          case 'adventure':
            gradColors = const [
              Color(0xFF166534),
              Color(0xFF16A34A),
              Color(0xFF86EFAC),
            ];
            break;
          case 'nightlife':
            gradColors = const [
              Color(0xFF7C3AED),
              Color(0xFFDB2777),
              Color(0xFFF472B6),
            ];
            break;
          case 'heritage':
            gradColors = const [
              Color(0xFF92400E),
              Color(0xFFB45309),
              Color(0xFFFDE68A),
            ];
            break;
          case 'viewpoint':
            gradColors = const [
              Color(0xFFF59E0B),
              Color(0xFFF97316),
              Color(0xFFFB7185),
            ];
            break;
          case 'attraction':
            gradColors = const [
              Color(0xFF06B6D4),
              Color(0xFF0891B2),
              Color(0xFF67E8F9),
            ];
            break;
          case 'shopping':
            gradColors = const [
              Color(0xFF475569),
              Color(0xFF64748B),
              Color(0xFFCBD5E1),
            ];
            break;
          default:
            gradColors = const [
              Color(0xFF0A7FAB),
              Color(0xFF1AAECF),
              Color(0xFF7DD8EF),
            ];
        }

        final (tagBg, tagFg) = _getTagColors(
          d['tagLabel'] as String? ?? category,
        );

        AppStore.savedPois.add(
          SavedPoiSummary(
            name: d['name'] as String? ?? '',
            location: d['location'] as String? ?? '',
            category: category,
            rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
            description: d['description'] as String? ?? '',
            openHours: d['openHours'] as String? ?? '',
            estimatedTime: d['estimatedTime'] as String? ?? '',
            priceRange: d['priceRange'] as String? ?? 'Free',
            gradientColors: gradColors,
            icon: icon,
            tagLabel: d['tagLabel'] as String? ?? category,
            tagBg: tagBg,
            tagFg: tagFg,
            imagePath: d['imagePath'] as String? ?? '',
            longDescription: d['longDescription'] as String? ?? '',
            latitude: (d['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (d['longitude'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _weatherFuture = _WeatherStat.fetch();
    _loadPoisFromFirestore();
    _loadSavedPoisFromFirestore();
    AppStore.addListener(_onStoreUpdate);
  }

  // ── CATEGORIES ───────────────────────────────────────────
  static const _categories = [
    _Category('All', Icons.apps_rounded),
    _Category('Beach', Icons.beach_access_rounded),
    _Category('Temple', Icons.temple_buddhist_rounded),
    _Category('Nature', Icons.forest_rounded),
    _Category('Culture', Icons.account_balance_rounded),
    _Category('Food', Icons.restaurant_rounded),
    _Category('Adventure', Icons.surfing_rounded),
    _Category('Nightlife', Icons.nightlife_rounded),
    _Category('Heritage', Icons.location_city_rounded),
    _Category('Viewpoint', Icons.landscape_rounded),
    _Category('Attraction', Icons.attractions_rounded),
    _Category('Shopping', Icons.shopping_bag_rounded),
  ];

  // ── TRAVEL TIPS ──────────────────────────────────────────
  static const _travelTips = [
    _TravelTip(
      icon: Icons.wb_sunny_rounded,
      title: 'Best Time to Visit',
      body:
          'November to April is the dry season — perfect beach weather with calm seas.',
      accent: Color(0xFFF59E0B),
    ),
    _TravelTip(
      icon: Icons.directions_bike_rounded,
      title: 'Getting Around',
      body:
          'Rent a scooter for flexibility! Tuk-tuks are fun but negotiate the price first.',
      accent: Color(0xFF0A7FAB),
    ),
    _TravelTip(
      icon: Icons.restaurant_rounded,
      title: 'Local Food',
      body: 'Don\'t miss Pad Kra Pao and fresh seafood at Rawai Night Market.',
      accent: Color(0xFFE8634C),
    ),
    _TravelTip(
      icon: Icons.temple_buddhist_rounded,
      title: 'Temple Etiquette',
      body:
          'Dress modestly with covered shoulders and knees when visiting temples.',
      accent: Color(0xFFC8912E),
    ),
    _TravelTip(
      icon: Icons.water_rounded,
      title: 'Beach Safety',
      body:
          'Red flags mean no swimming. Rip currents can be strong — stay alert.',
      accent: Color(0xFF16A34A),
    ),
  ];

  // ── 25 POI CARDS ─────────────────────────────────────────
  static final _poiCards = [
    // ── BEACHES ─────────────────────────────────────────────
    _PoiCard(
      name: 'Kata Beach',
      location: 'Kata, Phuket',
      category: 'Beach',
      rating: 4.7,
      description:
          'A beautiful beach popular for swimming, sunsets, and a relaxed atmosphere.',
      longDescription:
          'Kata Beach is giving soft-life paradise energy from the very first step. The sea glows in shades of blue that look almost unreal, like someone turned the saturation all the way up just for the view. Waves roll in with that perfect chill rhythm, making it a dreamy spot for swimming, sunbathing, surfing, or just staring dramatically into the horizon. By day, it feels bright, breezy, and postcard-pretty. By sunset, the whole beach turns golden and romantic in a “main character healing arc” kind of way. It is the place where sunscreen, salty hair, and zero stress become the official dress code.',
      openHours: 'Open 24 hours',
      estimatedTime: '2 - 4 hours',
      priceRange: 'Free',
      imagePath: 'assets/images/kata_beach.jpg',
      placeholderIcon: Icons.beach_access_rounded,
      gradientColors: const [
        Color(0xFF6B3FA0),
        Color(0xFFE8634C),
        Color(0xFFF0A070),
      ],
      tags: const [
        _PoiTag('Beach', AppColors.oceanTint, AppColors.oceanDeep),
        _PoiTag('Nature', Color(0xFFEEF5EE), Color(0xFF16A34A)),
      ],
      latitude: 7.8196,
      longitude: 98.2986,
    ),
    _PoiCard(
      name: 'Patong Beach',
      location: 'Patong, Phuket',
      category: 'Beach',
      rating: 4.5,
      description:
          'A lively beach area known for nightlife, shopping, and entertainment.',
      longDescription:
          'Patong Beach is the loud, iconic, extra queen of Phuket — and honestly, she knows it. This is where beach life meets full-on energy, with jet skis slicing across the water, music floating through the air, and crowds vibing from morning until night. The sand is warm, the sea is sparkling, and there is always something happening, whether it is parasailing, banana boats, or people just living their best holiday life. It feels chaotic in the most exciting way, like a tropical playlist on maximum volume. If Phuket had a heartbeat, Patong Beach would probably be it — bold, busy, bright, and absolutely unforgettable.',
      openHours: 'Open 24 hours',
      estimatedTime: '2 - 4 hours',
      priceRange: 'Free',
      imagePath: 'assets/images/patong_beach.jpg',
      placeholderIcon: Icons.waves_rounded,
      gradientColors: const [
        Color(0xFF0A7FAB),
        Color(0xFF38BDF8),
        Color(0xFF93C5FD),
      ],
      tags: const [
        _PoiTag('Popular', AppColors.oceanTint, AppColors.oceanDeep),
        _PoiTag('Nightlife', AppColors.coralTint, AppColors.coral),
      ],
      latitude: 7.9036,
      longitude: 98.2969,
    ),
    _PoiCard(
      name: 'Freedom Beach',
      location: 'Patong, Phuket',
      category: 'Beach',
      rating: 4.8,
      description:
          'A quieter hidden beach with soft sand and clear water, great for relaxing.',
      longDescription:
          'Freedom Beach feels like a secret whispered by the island itself. Hidden away from the louder parts of Phuket, this beach is pure “found paradise by accident” energy. The water is insanely clear, the sand is soft like powdered sugar, and the whole place feels untouched in the best possible way. It is peaceful, dreamy, and lowkey magical, like the kind of beach you imagine in those unrealistic travel reels and then gasp because it actually exists. Surrounded by lush green hills, Freedom Beach feels private, calm, and almost sacred. It is perfect for anyone craving quiet beauty, sea sparkle, and a break from the world.',
      openHours: 'Open 24 hours',
      estimatedTime: '2 - 3 hours',
      priceRange: 'Free',
      imagePath: 'assets/images/freedom_beach.jpg',
      placeholderIcon: Icons.beach_access_rounded,
      gradientColors: const [
        Color(0xFF14B8A6),
        Color(0xFF0EA5E9),
        Color(0xFFBAE6FD),
      ],
      tags: const [
        _PoiTag('Hidden Gem', AppColors.oceanTint, AppColors.oceanDeep),
        _PoiTag('Nature', Color(0xFFEEF5EE), Color(0xFF16A34A)),
      ],
      latitude: 7.8921,
      longitude: 98.2788,
    ),
    _PoiCard(
      name: 'Surin Beach',
      location: 'Surin, Phuket',
      category: 'Beach',
      rating: 4.6,
      description:
          'Upscale beach area loved for clear water, sunbeds, and trendy beach clubs.',
      longDescription:
          'Surin Beach is classy, calm, and effortlessly pretty — like that one person who looks amazing without even trying. The shoreline curves beautifully, the sand feels silky, and the sea shines with an elegant blue that seems too polished to be real. It is less chaotic than the busier beaches, which makes everything feel more refined, more relaxed, and somehow more cinematic. Palm trees sway like background dancers while the waves do their thing with perfect timing. It is the kind of beach that makes you want to slow down, sip something cold, and romanticize your entire existence. Surin is not loud. She is luxury in a whisper.',
      openHours: 'Open 24 hours',
      estimatedTime: '2 - 3 hours',
      priceRange: '฿',
      imagePath: 'assets/images/surin_beach.jpg',
      placeholderIcon: Icons.beach_access_rounded,
      gradientColors: const [
        Color(0xFF0284C7),
        Color(0xFF0EA5E9),
        Color(0xFF7DD3FC),
      ],
      tags: const [
        _PoiTag('Beach', AppColors.oceanTint, AppColors.oceanDeep),
        _PoiTag('Upscale', AppColors.goldTint, AppColors.gold),
      ],
      latitude: 7.9736,
      longitude: 98.2800,
    ),
    _PoiCard(
      name: 'Nai Harn Beach',
      location: 'Nai Harn, Phuket',
      category: 'Beach',
      rating: 4.8,
      description:
          'A scenic and peaceful beach tucked in the south, surrounded by hills.',
      longDescription:
          'Nai Harn Beach feels like a peaceful little dream wrapped between green hills and glowing blue water. It has that perfect balance of beauty and calm, where the sea looks inviting enough to run straight into and the soft sand makes you want to stay forever. Unlike crowded party beaches, Nai Harn gives soft, serene, “I am reconnecting with nature and my inner peace” vibes. Families, swimmers, and sunset lovers all fit here so naturally. The scenery feels almost painted — blue sky, emerald hills, and a bay so pretty it barely makes sense. It is a gentle kind of paradise, quiet but unforgettable in its own graceful way.',
      openHours: 'Open 24 hours',
      estimatedTime: '2 - 3 hours',
      priceRange: 'Free',
      imagePath: 'assets/images/nai_harn_beach.jpg',
      placeholderIcon: Icons.waves_rounded,
      gradientColors: const [
        Color(0xFF0F766E),
        Color(0xFF14B8A6),
        Color(0xFF99F6E4),
      ],
      isFavourited: true,
      tags: const [
        _PoiTag('Peaceful', Color(0xFFEEF5EE), Color(0xFF16A34A)),
        _PoiTag('Scenic', AppColors.oceanTint, AppColors.oceanDeep),
      ],
      latitude: 7.7814,
      longitude: 98.3018,
    ),

    // ── TEMPLES ─────────────────────────────────────────────
    _PoiCard(
      name: 'The Big Buddha',
      location: 'Karon, Phuket',
      category: 'Temple',
      rating: 4.8,
      description:
          'A famous landmark with panoramic views and a peaceful hilltop atmosphere.',
      longDescription:
          'The Big Buddha is not just a landmark — it is a whole moment. Sitting high above Phuket, this giant white statue feels calm, majestic, and almost otherworldly, like it is quietly watching over the island with pure peaceful energy. The marble shines beautifully under the sun, and the view from the hilltop is honestly insane — ocean, hills, coastline, sky, everything all at once. Up there, the air feels lighter and the noise of the world seems to fade. It is spiritual, scenic, and deeply grounding in a way that sneaks up on you. The Big Buddha is where silence somehow says everything.',
      openHours: '8:00 AM - 7:30 PM',
      estimatedTime: '1 - 2 hours',
      priceRange: 'Free',
      imagePath: 'assets/images/the_big_buddha.jpg',
      placeholderIcon: Icons.temple_buddhist_rounded,
      gradientColors: const [
        Color(0xFF0A7FAB),
        Color(0xFF1AAECF),
        Color(0xFF7DD8EF),
      ],
      isFavourited: true,
      tags: const [
        _PoiTag('Must See', AppColors.oceanTint, AppColors.oceanDeep),
        _PoiTag('Culture', AppColors.goldTint, AppColors.gold),
      ],
      latitude: 7.8273,
      longitude: 98.3090,
    ),
    _PoiCard(
      name: 'Wat Chalong',
      location: 'Chalong, Phuket',
      category: 'Temple',
      rating: 4.8,
      description:
          'A significant Buddhist temple complex with ornate architecture and spiritual importance.',
      longDescription:
          'Wat Chalong is like stepping into a golden dream where every detail glows with meaning. The temple is stunning — elegant roofs, intricate patterns, and rich colors that shimmer under the Phuket sun like something straight out of a fantasy film. But it is not just beautiful, it also carries a deep sense of peace and devotion that makes the whole place feel special. Walking through the grounds feels calm, respectful, and quietly magical. There is beauty in every corner, from the ornate halls to the sacred atmosphere in the air. Wat Chalong is not just a place to visit — it is a place to feel.',
      openHours: '7:00 AM - 5:00 PM',
      estimatedTime: '1 hour',
      priceRange: 'Free',
      imagePath: 'assets/images/wat_chalong.jpg',
      placeholderIcon: Icons.account_balance_rounded,
      gradientColors: const [
        Color(0xFFFBBF24),
        Color(0xFFF59E0B),
        Color(0xFFFDE68A),
      ],
      tags: const [
        _PoiTag('Temple', AppColors.goldTint, AppColors.gold),
        _PoiTag('Culture', AppColors.coralTint, AppColors.coral),
      ],
      latitude: 7.8453,
      longitude: 98.3371,
    ),

    // ── NATURE ──────────────────────────────────────────────
    _PoiCard(
      name: 'Phuket Elephant Sanctuary',
      location: 'Paklok, Phuket',
      category: 'Nature',
      rating: 4.9,
      description:
          'An ethical elephant sanctuary where visitors can observe rescued elephants.',
      longDescription:
          'Phuket Elephant Sanctuary is pure soft-heart energy. This is where elephants are allowed to simply be elephants — walking freely, bathing, playing, and living peacefully in a safe and caring environment. Watching them move so gently through nature feels emotional in the best way, because there is something powerful about seeing these giant animals treated with kindness and respect. The experience feels meaningful, not performative, and that is what makes it special. It is quiet, educational, and full of heart. Instead of chaos, there is compassion. Instead of spectacle, there is connection. It is one of those places that leaves your camera full and your soul fuller.',
      openHours: '9:00 AM - 5:00 PM',
      estimatedTime: '2 - 3 hours',
      priceRange: '฿฿฿',
      imagePath: 'assets/images/phuket_elephant_sanctuary.jpg',
      placeholderIcon: Icons.pets_rounded,
      gradientColors: const [
        Color(0xFF16A34A),
        Color(0xFF22C55E),
        Color(0xFF86EFAC),
      ],
      isFavourited: true,
      tags: const [
        _PoiTag('Nature', Color(0xFFEEF5EE), Color(0xFF16A34A)),
        _PoiTag('Ethical', AppColors.oceanTint, AppColors.oceanDeep),
      ],
      latitude: 8.0233,
      longitude: 98.3636,
    ),
    _PoiCard(
      name: 'Sirinat National Park',
      location: 'North Phuket',
      category: 'Nature',
      rating: 4.6,
      description:
          'A peaceful natural area with beaches, forest, and wildlife observation.',
      longDescription:
          'Sirinat National Park feels like Phuket’s wild, untouched side showing off a little. It is a dreamy mix of beach, forest, mangroves, and open sky, all blending into one giant natural mood board. The air feels fresher here, the crowds disappear, and suddenly everything slows down in the prettiest possible way. You can walk beneath tall trees, hear birds calling from the branches, and then end up on a quiet beach that feels like it belongs only to you. It has that hidden-world vibe, where every path looks like it might lead to something magical. Sirinat is nature without filters — peaceful, raw, and ridiculously beautiful.',
      openHours: '8:00 AM - 6:00 PM',
      estimatedTime: '2 - 4 hours',
      priceRange: '฿',
      imagePath: 'assets/images/sirinat_national_park.jpg',
      placeholderIcon: Icons.park_rounded,
      gradientColors: const [
        Color(0xFF15803D),
        Color(0xFF22C55E),
        Color(0xFFBBF7D0),
      ],
      tags: const [
        _PoiTag('Nature', Color(0xFFEEF5EE), Color(0xFF16A34A)),
        _PoiTag('Relax', AppColors.oceanTint, AppColors.oceanDeep),
      ],
      latitude: 8.1310,
      longitude: 98.2937,
    ),
    _PoiCard(
      name: 'Koh Sirey',
      location: 'East Phuket',
      category: 'Nature',
      rating: 4.3,
      description:
          'A small island connected by bridge, known for mangrove forests and sea views.',
      longDescription:
          'Koh Sirey is one of those underrated little gems that quietly steals your heart. It is not loud or flashy, but that is exactly the charm. This small island near Phuket Town has sleepy coastal vibes, local life, peaceful sea views, and a soft, old-soul beauty that feels deeply authentic. The roads curve gently through fishing villages and quiet neighborhoods, making every ride feel like a scene from an indie travel film. There is something sweet and unbothered about the atmosphere, like the island is just minding its business while being adorable. Koh Sirey feels intimate, local, and beautifully lowkey — the definition of hidden treasure energy.',
      openHours: 'Open 24 hours',
      estimatedTime: '1 - 2 hours',
      priceRange: 'Free',
      imagePath: 'assets/images/koh_sirey.jpg',
      placeholderIcon: Icons.forest_rounded,
      gradientColors: const [
        Color(0xFF166534),
        Color(0xFF4ADE80),
        Color(0xFFBBF7D0),
      ],
      tags: const [
        _PoiTag('Nature', Color(0xFFEEF5EE), Color(0xFF16A34A)),
        _PoiTag('Mangrove', AppColors.oceanTint, AppColors.oceanDeep),
      ],
      latitude: 7.8921,
      longitude: 98.4260,
    ),

    // ── CULTURE ─────────────────────────────────────────────
    _PoiCard(
      name: 'Old Phuket Town',
      location: 'Phuket City',
      category: 'Culture',
      rating: 4.9,
      description:
          'Historic streets, colorful Sino-Portuguese buildings, cafes, and local food.',
      longDescription:
          'Old Phuket Town is a full-on aesthetic. Colorful Sino-Portuguese buildings line the streets like the island decided to serve architecture, culture, and charm all at once. Every corner feels photogenic, every café looks like it belongs on your mood board, and every little lane seems to hide another cute shop, mural, or snack spot waiting to be discovered. It is vibrant but nostalgic, lively but still full of story. Walking here feels like stepping into a vintage postcard that somehow got upgraded with modern cool-girl energy. Old Phuket Town is where history puts on a stylish outfit, grabs an iced coffee, and says, “Let’s romanticize today.”',
      openHours: 'Open 24 hours',
      estimatedTime: '2 - 3 hours',
      priceRange: 'Free',
      imagePath: 'assets/images/old_phuket_town.jpg',
      placeholderIcon: Icons.location_city_rounded,
      gradientColors: const [
        Color(0xFF8B4513),
        Color(0xFFC8912E),
        Color(0xFFF0C060),
      ],
      tags: const [
        _PoiTag('Heritage', AppColors.coralTint, AppColors.coral),
        _PoiTag('Food', AppColors.goldTint, AppColors.gold),
      ],
      latitude: 7.8838,
      longitude: 98.3920,
    ),
    _PoiCard(
      name: 'Phuket Fantasea',
      location: 'Kamala, Phuket',
      category: 'Culture',
      rating: 4.5,
      description:
          'A spectacular cultural theme park with Thai shows, acrobatics, and elephants.',
      longDescription:
          'Phuket FantaSea is absolutely extra — in the best way possible. It is bright, theatrical, oversized, and fully committed to giving fantasy kingdom energy from the second you arrive. Lights sparkle everywhere, grand buildings glow like palaces, and the entire place feels like someone mixed Thai culture with a dream sequence and a fireworks budget. The show itself is dramatic, colorful, and packed with wow moments that keep your eyes locked in. Everything feels larger than life, from the costumes to the atmosphere. Phuket FantaSea is not subtle, and that is exactly the point. It is bold, magical, chaotic, and unforgettable — pure spectacle mode activated.',
      openHours: '5:30 PM - 11:30 PM',
      estimatedTime: '3 - 4 hours',
      priceRange: '฿฿฿',
      imagePath: 'assets/images/phuket_fantasea.jpg',
      placeholderIcon: Icons.celebration_rounded,
      gradientColors: const [
        Color(0xFF7C3AED),
        Color(0xFFA855F7),
        Color(0xFFE9D5FF),
      ],
      tags: const [
        _PoiTag('Show', AppColors.coralTint, AppColors.coral),
        _PoiTag('Culture', AppColors.goldTint, AppColors.gold),
      ],
      latitude: 7.9600,
      longitude: 98.2750,
    ),

    // ── FOOD ────────────────────────────────────────────────
    _PoiCard(
      name: 'Rawai Seafood Market',
      location: 'Rawai, Phuket',
      category: 'Food',
      rating: 4.6,
      description:
          'Buy fresh seafood by weight directly from fishermen and have it cooked on the spot.',
      longDescription:
          'Rawai Seafood Market is a paradise for food lovers and seafood stans. The whole place buzzes with salty air, sizzling flavors, and the delicious chaos of fresh catches being picked out right in front of you. It is lively, local, and full of character, where giant prawns, crabs, shellfish, and fish all seem to say, “Choose me, I am the main event.” The best part is how fresh everything feels — straight from the sea to your plate with barely any time to blink. It is messy, flavorful, and authentic in the best way. Rawai is where seafood goes from ingredient to icon.',
      openHours: '9:00 AM - 9:00 PM',
      estimatedTime: '1 - 2 hours',
      priceRange: '฿฿',
      imagePath: 'assets/images/rawai_seafood_market.jpg',
      placeholderIcon: Icons.set_meal_rounded,
      gradientColors: const [
        Color(0xFFE8634C),
        Color(0xFFF97316),
        Color(0xFFFED7AA),
      ],
      tags: const [
        _PoiTag('Seafood', AppColors.coralTint, AppColors.coral),
        _PoiTag('Local', AppColors.goldTint, AppColors.gold),
      ],
      latitude: 7.7849,
      longitude: 98.3356,
    ),
    _PoiCard(
      name: 'Phuket Town Walking Street',
      location: 'Phuket City',
      category: 'Food',
      rating: 4.7,
      description:
          'A vibrant Sunday night market packed with local food stalls and street art.',
      longDescription:
          'Phuket Town Walking Street is giving full weekend fever dream energy. As the sun goes down, the street transforms into a glowing maze of food stalls, lights, music, art, handmade goodies, and people everywhere just vibing. It is loud, colorful, and alive in a way that feels exciting without being overwhelming. One second you are buying cute souvenirs, the next you are holding some random snack you have never seen before and somehow loving it. The buildings, lights, and crowd create this electric atmosphere that makes everything feel more fun. It is the kind of place where you wander with no plan and still win.',
      openHours: 'Sun 4:00 PM - 10:00 PM',
      estimatedTime: '1 - 2 hours',
      priceRange: '฿',
      imagePath: 'assets/images/phuket_town_walking_street.jpg',
      placeholderIcon: Icons.restaurant_rounded,
      gradientColors: const [
        Color(0xFFD97706),
        Color(0xFFF59E0B),
        Color(0xFFFDE68A),
      ],
      tags: const [
        _PoiTag('Street Food', AppColors.coralTint, AppColors.coral),
        _PoiTag('Market', AppColors.goldTint, AppColors.gold),
      ],
      latitude: 7.8847,
      longitude: 98.3933,
    ),
    _PoiCard(
      name: 'Blue Elephant Restaurant',
      location: 'Old Town, Phuket',
      category: 'Food',
      rating: 4.7,
      description:
          'Award-winning Thai cuisine in a beautiful colonial mansion with cooking classes.',
      longDescription:
          'Blue Elephant Restaurant is elegant drama in culinary form. Housed in a beautiful heritage mansion, the place already feels iconic before the food even arrives. Then the dishes show up — refined, fragrant, colorful, and looking way too gorgeous to touch for at least five seconds. It is not just dinner, it is a whole experience. Every bite feels rich with Thai tradition, but presented with style, grace, and a little bit of royal energy. The atmosphere is charming, sophisticated, and slightly theatrical, like the building itself knows it is beautiful. Blue Elephant is where history, flavor, and luxury sit at the same table.',
      openHours: '11:30 AM - 10:00 PM',
      estimatedTime: '1.5 - 2 hours',
      priceRange: '฿฿฿',
      imagePath: 'assets/images/blue_elephant_restaurant.jpg',
      placeholderIcon: Icons.dining_rounded,
      gradientColors: const [
        Color(0xFF1D4ED8),
        Color(0xFF3B82F6),
        Color(0xFFBFDBFE),
      ],
      tags: const [
        _PoiTag('Fine Dining', AppColors.goldTint, AppColors.gold),
        _PoiTag('Thai', AppColors.coralTint, AppColors.coral),
      ],
      latitude: 7.8846,
      longitude: 98.3939,
    ),

    // ── ADVENTURE ───────────────────────────────────────────
    _PoiCard(
      name: 'Tiger Kingdom',
      location: 'Kathu, Phuket',
      category: 'Adventure',
      rating: 4.2,
      description:
          'Get up close with tigers of all ages in a supervised and safe environment.',
      longDescription:
          'Tiger Kingdom is one of Phuket’s most talked-about spots, and the vibe is definitely wild. Seeing these huge, powerful animals up close feels surreal, like your brain takes a second to process that yes, that is an actual tiger right there. Their beauty is intense — striped, majestic, and lowkey intimidating in a very real way. The whole place gives a rare chance to witness creatures that usually live only in documentaries and imagination. It is exciting, nerve-racking, and unforgettable all at once. Whether you come out amazed, shaken, or both, Tiger Kingdom is the kind of place that leaves a strong impression.',
      openHours: '9:00 AM - 6:00 PM',
      estimatedTime: '1 - 2 hours',
      priceRange: '฿฿฿',
      imagePath: 'assets/images/tiger_kingdom.jpg',
      placeholderIcon: Icons.pets_rounded,
      gradientColors: const [
        Color(0xFFEA580C),
        Color(0xFFF97316),
        Color(0xFFFED7AA),
      ],
      tags: const [
        _PoiTag('Adventure', AppColors.coralTint, AppColors.coral),
        _PoiTag('Wildlife', Color(0xFFEEF5EE), Color(0xFF16A34A)),
      ],
      latitude: 7.9260,
      longitude: 98.3307,
    ),
    _PoiCard(
      name: 'ATV & Zipline Tour',
      location: 'Kathu, Phuket',
      category: 'Adventure',
      rating: 4.5,
      description:
          'Thrilling ATV rides through jungle trails and zipline rides over the canopy.',
      longDescription:
          'An ATV and zipline tour is basically Phuket saying, “Okay, now let’s add chaos.” One minute you are roaring through muddy jungle trails on an ATV like the star of an action movie, and the next you are flying over treetops with your heart somewhere between your chest and the clouds. It is fast, thrilling, messy, and ridiculously fun. The jungle around you feels alive, wild, and dramatic, making every turn and every scream feel even bigger. This is not a calm, peaceful sightseeing moment — this is adrenaline, dirt, wind, and pure scream-laugh energy. Perfect for anyone whose vacation mood is “let’s do something unhinged.”',
      openHours: '8:00 AM - 5:00 PM',
      estimatedTime: '2 - 3 hours',
      priceRange: '฿฿฿',
      imagePath: 'assets/images/atv_&_zipline.jpg',
      placeholderIcon: Icons.directions_bike_rounded,
      gradientColors: const [
        Color(0xFF166534),
        Color(0xFF16A34A),
        Color(0xFF86EFAC),
      ],
      tags: const [
        _PoiTag('Thrill', AppColors.coralTint, AppColors.coral),
        _PoiTag('Outdoor', Color(0xFFEEF5EE), Color(0xFF16A34A)),
      ],
      latitude: 7.9180,
      longitude: 98.3200,
    ),
    _PoiCard(
      name: 'Phi Phi Islands Day Trip',
      location: 'Rassada Pier, Phuket',
      category: 'Adventure',
      rating: 4.9,
      description:
          'A full-day boat tour to the iconic Phi Phi Islands — snorkeling, Maya Bay, and more.',
      longDescription:
          'Phi Phi Island is unfairly beautiful. Like, almost offensive. The cliffs rise dramatically out of the sea, the water glows in impossible shades of turquoise, and every angle looks like it belongs on the cover of a luxury travel magazine. It feels cinematic, almost too perfect, as if nature really decided to flex here. Boats glide through the bay, the sun bounces off the water like glitter, and the whole island seems to exist in permanent wow mode. Whether you are snorkeling, cruising, swimming, or just staring in disbelief, Phi Phi serves tropical fantasy at maximum level. It is the kind of place that makes real life feel edited.',
      openHours: '7:30 AM - 6:00 PM',
      estimatedTime: 'Full Day',
      priceRange: '฿฿฿',
      imagePath: 'assets/images/phi_phi_island.jpg',
      placeholderIcon: Icons.sailing_rounded,
      gradientColors: const [
        Color(0xFF0369A1),
        Color(0xFF0EA5E9),
        Color(0xFF7DD3FC),
      ],
      isFavourited: true,
      tags: const [
        _PoiTag('Must Do', AppColors.oceanTint, AppColors.oceanDeep),
        _PoiTag('Snorkel', Color(0xFFEEF5EE), Color(0xFF16A34A)),
      ],
      latitude: 7.9041,
      longitude: 98.4243,
    ),

    // ── NIGHTLIFE ───────────────────────────────────────────
    _PoiCard(
      name: 'Bangla Road',
      location: 'Patong, Phuket',
      category: 'Nightlife',
      rating: 4.3,
      description:
          'A famous nightlife street packed with bars, clubs, lights, and late-night energy.',
      longDescription:
          'Bangla Road is absolute nightlife chaos — neon, noise, music, lights, crowds, and zero intention of going to bed early. The street comes alive after dark like someone flipped a switch and activated party mode for the entire city. Every step hits you with new sounds, flashing signs, performers, laughter, and enough energy to power an entire island. It is bold, wild, and not pretending to be anything else. Bangla is not about calm elegance — it is about living loudly, dancing badly, and letting the night get a little ridiculous. If Phuket has a party core, Bangla Road is where it explodes into full color.',
      openHours: '6:00 PM - Late',
      estimatedTime: '1 - 3 hours',
      priceRange: '฿฿',
      imagePath: 'assets/images/bangla_road.jpg',
      placeholderIcon: Icons.nightlife_rounded,
      gradientColors: const [
        Color(0xFF7C3AED),
        Color(0xFFDB2777),
        Color(0xFFF472B6),
      ],
      tags: const [
        _PoiTag('Nightlife', AppColors.coralTint, AppColors.coral),
        _PoiTag('Popular', AppColors.goldTint, AppColors.gold),
      ],
      latitude: 7.8940,
      longitude: 98.2968,
    ),
    _PoiCard(
      name: 'Illuzion Club',
      location: 'Patong, Phuket',
      category: 'Nightlife',
      rating: 4.4,
      description:
          'One of Phuket\'s biggest and most popular clubs with top DJs and light shows.',
      longDescription:
          'Illuzion Club is where the night goes full superstar mode. Massive lights, giant stage energy, booming music, and a crowd that came to have an actual moment — it all feels huge, electric, and dramatic in the best way. The atmosphere is sleek and intense, like stepping into a music video where everyone suddenly looks cooler under the lights. DJs drop beats, the room pulses with energy, and the whole place feels designed to make ordinary nights impossible. It is glamorous, loud, flashy, and unapologetically extra. Illuzion is not just a club — it is a full sensory attack, but like, make it iconic.',
      openHours: '9:00 PM - Late',
      estimatedTime: '2 - 4 hours',
      priceRange: '฿฿',
      imagePath: 'assets/images/illuzion_club.jpg',
      placeholderIcon: Icons.music_note_rounded,
      gradientColors: const [
        Color(0xFF4C1D95),
        Color(0xFF7C3AED),
        Color(0xFFC4B5FD),
      ],
      tags: const [
        _PoiTag('Club', AppColors.coralTint, AppColors.coral),
        _PoiTag('Music', Color(0xFFEDE9FE), Color(0xFF7C3AED)),
      ],
      latitude: 7.8941,
      longitude: 98.2969,
    ),

    // ── HERITAGE ────────────────────────────────────────────
    _PoiCard(
      name: 'Thalang National Museum',
      location: 'Thalang, Phuket',
      category: 'Heritage',
      rating: 4.3,
      description:
          'Explore Phuket\'s history including the famous Battle of Thalang.',
      longDescription:
          'Thalang National Museum feels like opening a hidden chapter of Phuket’s soul. It is quiet and thoughtful, but far from boring. Inside, stories of the island’s past unfold through old artifacts, cultural displays, and historical pieces that give everything around Phuket deeper meaning. It is the kind of place that turns random landmarks into living memories, making you realize there is so much more beneath the postcard version of the island. The atmosphere is calm, respectful, and rich with heritage. If beaches show Phuket’s beauty, this museum shows its memory. It is where history stops being just facts and starts feeling like something alive.',
      openHours: '9:00 AM - 4:00 PM',
      estimatedTime: '1 - 1.5 hours',
      priceRange: '฿',
      imagePath: 'assets/images/thalang_national_museum.jpg',
      placeholderIcon: Icons.museum_rounded,
      gradientColors: const [
        Color(0xFF92400E),
        Color(0xFFB45309),
        Color(0xFFFDE68A),
      ],
      tags: const [
        _PoiTag('History', AppColors.goldTint, AppColors.gold),
        _PoiTag('Museum', AppColors.coralTint, AppColors.coral),
      ],
      latitude: 8.0137,
      longitude: 98.3256,
    ),

    // ── VIEWPOINTS ──────────────────────────────────────────
    _PoiCard(
      name: 'Promthep Cape',
      location: 'Rawai, Phuket',
      category: 'Viewpoint',
      rating: 4.9,
      description:
          'One of the best sunset viewpoints in Phuket with dramatic coastal scenery.',
      longDescription:
          'Promthep Cape is sunset royalty. This place does not just show you the sunset — it performs it. Perched at the southern tip of Phuket, the cape opens up to endless sea views, dramatic cliffs, and a sky that slowly melts into shades of gold, orange, pink, and fire. The whole scene feels cinematic, almost unreal, like the universe is putting on one final show before night falls. People gather here for the same reason: because the view really is that good. Promthep Cape is romantic, dramatic, and breathtaking in a very “pause everything and just look” kind of way.',
      openHours: 'Open 24 hours',
      estimatedTime: '45 mins - 1 hour',
      priceRange: 'Free',
      imagePath: 'assets/images/promthep_cape.jpg',
      placeholderIcon: Icons.wb_sunny_rounded,
      gradientColors: const [
        Color(0xFFF59E0B),
        Color(0xFFF97316),
        Color(0xFFFB7185),
      ],
      isFavourited: true,
      tags: const [
        _PoiTag('Sunset', AppColors.goldTint, AppColors.gold),
        _PoiTag('Viewpoint', AppColors.oceanTint, AppColors.oceanDeep),
      ],
      latitude: 7.7696,
      longitude: 98.3034,
    ),
    _PoiCard(
      name: 'Karon Viewpoint',
      location: 'Karon, Phuket',
      category: 'Viewpoint',
      rating: 4.7,
      description:
          'A panoramic viewpoint overlooking Kata Noi, Kata, and Karon beaches.',
      longDescription:
          'Karon Viewpoint is the definition of “this view ate.” From up high, you get this stunning sweep of coastline where the beaches curve like ribbons of gold beside glowing blue water. It feels wide, open, and impossibly pretty, like the island is showing off its best angles without even trying. The breeze up there makes everything feel lighter, and the whole place has that dramatic overlook energy that makes you want to take fifty photos and still stay longer. It is one of those spots where you do not need much — just the view, the sky, and a few seconds to let your jaw drop properly.',
      openHours: 'Open 24 hours',
      estimatedTime: '30 - 45 mins',
      priceRange: 'Free',
      imagePath: 'assets/images/karon_viewpoint.jpg',
      placeholderIcon: Icons.landscape_rounded,
      gradientColors: const [
        Color(0xFF0EA5E9),
        Color(0xFF2563EB),
        Color(0xFF93C5FD),
      ],
      tags: const [
        _PoiTag('Viewpoint', AppColors.oceanTint, AppColors.oceanDeep),
        _PoiTag('Scenic', AppColors.goldTint, AppColors.gold),
      ],
      latitude: 7.8296,
      longitude: 98.2975,
    ),

    // ── ATTRACTIONS ─────────────────────────────────────────
    _PoiCard(
      name: 'Phuket Aquarium',
      location: 'Cape Panwa, Phuket',
      category: 'Attraction',
      rating: 4.4,
      description:
          'A family-friendly aquarium featuring marine life and educational exhibits.',
      longDescription:
          'Phuket Aquarium is a soft, underwater little world where the ocean gets to show its quieter magic. Inside, glowing tanks and drifting sea creatures create this calm, dreamy atmosphere that feels both peaceful and fascinating. Fish shimmer like tiny moving jewels, strange marine animals glide past like aliens with good design, and the whole place feels like a gentle invitation into another universe. It is not loud or chaotic — it is more like floating through a cool, blue daydream. Perfect for curious minds and ocean lovers, Phuket Aquarium turns the mystery of the sea into something you can walk beside and wonder at.',
      openHours: '8:30 AM - 4:30 PM',
      estimatedTime: '1 - 2 hours',
      priceRange: '฿฿',
      imagePath: 'assets/images/phuket_aquarium.jpg',
      placeholderIcon: Icons.set_meal_rounded,
      gradientColors: const [
        Color(0xFF06B6D4),
        Color(0xFF0891B2),
        Color(0xFF67E8F9),
      ],
      tags: const [
        _PoiTag('Family', Color(0xFFEEF5EE), Color(0xFF16A34A)),
        _PoiTag('Indoor', AppColors.oceanTint, AppColors.oceanDeep),
      ],
      latitude: 7.8449,
      longitude: 98.4091,
    ),

    // ── SHOPPING ────────────────────────────────────────────
    _PoiCard(
      name: 'Jungceylon',
      location: 'Patong, Phuket',
      category: 'Shopping',
      rating: 4.3,
      description:
          'Patong\'s largest shopping complex with international brands, cinema, and food court.',
      longDescription:
          'Jungceylon is where beach holiday meets shopping spree and suddenly your “just looking” turns into carrying five bags and a coffee. This mall is lively, modern, and packed with everything from fashion and beauty to snacks, souvenirs, entertainment, and random little temptations you definitely did not plan for. It feels energetic without being stressful, making it the perfect escape when you want air-con, convenience, and a little retail therapy. There is always something happening, something glowing, or something delicious nearby. Jungceylon is not just a mall — it is a full vacation survival zone for shopping, chilling, eating, and pretending you are being responsible.',
      openHours: '11:00 AM - 10:00 PM',
      estimatedTime: '2 - 3 hours',
      priceRange: '฿฿',
      imagePath: 'assets/images/jungceylon.jpg',
      placeholderIcon: Icons.shopping_bag_rounded,
      gradientColors: const [
        Color(0xFF475569),
        Color(0xFF64748B),
        Color(0xFFCBD5E1),
      ],
      tags: const [
        _PoiTag('Shopping', AppColors.coralTint, AppColors.coral),
        _PoiTag('Indoor', AppColors.oceanTint, AppColors.oceanDeep),
      ],
      latitude: 7.8942,
      longitude: 98.2991,
    ),
    _PoiCard(
      name: 'Central Festival Phuket',
      location: 'Vichitsongkram Rd',
      category: 'Shopping',
      rating: 4.5,
      description:
          'A massive lifestyle mall with luxury brands, restaurants, and entertainment.',
      longDescription:
          'Central Festival Phuket feels polished, spacious, and a little bit dangerous for your wallet. It is sleek, stylish, and packed with that modern mall energy where everything looks clean, tempting, and slightly luxurious. From fashion brands and beauty counters to cafés, restaurants, and entertainment spots, the whole place feels like a one-stop answer to “what should we do now?” It is comfortable, cool, and easy to spend way too much time in without even noticing. Whether you want to shop seriously, eat dramatically, or just escape the heat with a cold drink and a browse, Central Festival delivers big-city convenience with island flair.',
      openHours: '10:30 AM - 10:00 PM',
      estimatedTime: '2 - 4 hours',
      priceRange: '฿฿',
      imagePath: 'assets/images/central_festival_phuket.jpg',
      placeholderIcon: Icons.store_rounded,
      gradientColors: const [
        Color(0xFF1E293B),
        Color(0xFF334155),
        Color(0xFF94A3B8),
      ],
      tags: const [
        _PoiTag('Shopping', AppColors.coralTint, AppColors.coral),
        _PoiTag('Luxury', AppColors.goldTint, AppColors.gold),
      ],
      latitude: 7.9041,
      longitude: 98.3693,
    ),
  ];

  // ── TRENDING ─────────────────────────────────────────────
  List<_PoiCard> get _trendingCards {
    final sourcePois = _firestorePois.isNotEmpty ? _firestorePois : _poiCards;
    final highRated = sourcePois.where((c) => c.rating >= 4.5).toList();
    // Shuffle based on week number so it changes weekly but stays consistent
    final weekNumber =
        DateTime.now().millisecondsSinceEpoch ~/ (7 * 24 * 60 * 60 * 1000);
    highRated.shuffle(Random(weekNumber));
    return highRated.take(5).toList();
  }

  // ── FILTERED POI ─────────────────────────────────────────
  List<_PoiCard> get _filteredPoiCards {
    final sourcePois = _firestorePois.isNotEmpty ? _firestorePois : _poiCards;
    final selectedCatLabel = _categories[_selectedCat].label.toLowerCase();
    return sourcePois.where((card) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          card.name.toLowerCase().contains(q) ||
          card.location.toLowerCase().contains(q) ||
          card.category.toLowerCase().contains(q) ||
          card.description.toLowerCase().contains(q) ||
          card.tags.any((t) => t.label.toLowerCase().contains(q));
      final matchesCat =
          selectedCatLabel == 'all' ||
          card.category.toLowerCase() == selectedCatLabel ||
          card.tags.any((t) => t.label.toLowerCase() == selectedCatLabel);
      final matchesRating = card.rating >= _minRating;
      final matchesPrice =
          _selectedPrice == 'All' || card.priceRange == _selectedPrice;
      final matchesFav = !_showFavouritesOnly || AppStore.isPoiSaved(card.name);
      final isVisible = AppStore.isPoiVisible(card.name);
      return matchesSearch &&
          matchesCat &&
          matchesRating &&
          matchesPrice &&
          matchesFav &&
          isVisible;
    }).toList();
  }

  bool _onUserScroll(UserScrollNotification n) {
    if (n.direction == ScrollDirection.reverse && _headerVisible) {
      setState(() => _headerVisible = false);
    } else if (n.direction == ScrollDirection.forward && !_headerVisible) {
      setState(() => _headerVisible = true);
    }
    return false;
  }

  @override
  void dispose() {
    AppStore.removeListener(_onStoreUpdate);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final headerSpacer = MediaQuery.of(context).padding.top + 89.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<UserScrollNotification>(
              onNotification: _onUserScroll,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: headerSpacer),
                    _buildGreetingBanner(),
                    _buildWeatherStrip(),
                    _buildSearchBar(),
                    _buildSectionHeader('Phuket Tips', null),
                    _buildTravelTips(),
                    _buildSectionHeader('Trending This Week', null),
                    _buildTrendingStrip(),
                    _buildSectionHeader('Popular Attractions', null),
                    _buildCategoryChips(),
                    const SizedBox(height: 12),
                    _buildPoiVerticalList(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              offset: _headerVisible ? Offset.zero : const Offset(0, -1),
              child: _buildAppHeader(),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AppBottomNav(currentIndex: 0),
          ),
        ],
      ),
    );
  }
  
  // ══════════════════════════════════════════════════════════
  // APP HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildAppHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 14),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 15, 5, 0),
          child: Row(
            children: [
              Row(
                children: [
                  ClipRect(
                    child: Transform.scale(
                      scale: 1.6, // zoom factor — increase to crop tighter
                      child: Image.asset(
                        'assets/images/andamove_logo.png',
                        width: 60,
                        height: 60,
                        color: AppColors.text1,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text1,
                      ),
                      children: const [
                        TextSpan(text: 'Anda'),
                        TextSpan(
                          text: 'Move',
                          style: TextStyle(color: AppColors.oceanDeep),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  _buildHeaderIconBtn(),
                  const SizedBox(width: 10),
                  _buildAvatar(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconBtn() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationScreen()),
        ),
        child: Stack(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 19,
                color: AppColors.text2,
              ),
            ),
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.oceanDeep, AppColors.oceanMid],
          ),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: const Icon(Icons.person_rounded, size: 18, color: Colors.white),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // GREETING BANNER
  // ══════════════════════════════════════════════════════════
  Widget _buildGreetingBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
          colors: [Color(0xFF061018), Color(0xFF0A3D5C), Color(0xFF0A7FAB)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withOpacity(0.20),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.70],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (i) {
                  final small = i.isOdd;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    width: small ? 2 : 3,
                    height: small ? 2 : 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.goldLight.withOpacity(
                        small ? 0.30 : 0.60,
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: Colors.white.withOpacity(0.50),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sawasdee, $_userName! 🌴',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ready to explore Phuket today?',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.goldLight,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Phuket, Thailand',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // WEATHER STRIP
  // ══════════════════════════════════════════════════════════
  Widget _buildWeatherStrip() {
    return FutureBuilder<_WeatherStat>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        // Loading skeleton
        if (!snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderLight, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.oceanDeep,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Loading weather…',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.text3,
                  ),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
            boxShadow: shadowSm,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        stats.conditionIcon,
                        size: 20,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${stats.tempC}°',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text1,
                                  ),
                                ),
                                TextSpan(
                                  text: 'C',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            stats.conditionLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              color: AppColors.text2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.borderLight),
              Expanded(
                flex: 3,
                child: _weatherCell(
                  Icons.water_drop_outlined,
                  '${stats.humidity}%',
                  'Humidity',
                  const Color(0xFF0A7FAB),
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.borderLight),
              Expanded(
                flex: 3,
                child: _weatherCell(
                  Icons.air_rounded,
                  '${stats.windKph} km/h',
                  'Wind',
                  const Color(0xFF16A34A),
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.borderLight),
              Expanded(
                flex: 3,
                child: _weatherCell(
                  Icons.wb_sunny_outlined,
                  'UV ${stats.uvIndex}',
                  _uvLabel(stats.uvIndex),
                  _uvColor(stats.uvIndex),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _weatherCell(
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.text1,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 9.5, color: AppColors.text3),
        ),
      ],
    );
  }

  String _uvLabel(int uv) {
    if (uv == 0) return 'None'; // ← add this
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }

  Color _uvColor(int uv) {
    if (uv == 0) return const Color.fromARGB(255, 119, 195, 222); // ← add this
    if (uv <= 2) return const Color(0xFF16A34A);
    if (uv <= 5) return const Color(0xFFF59E0B);
    if (uv <= 7) return const Color(0xFFEA580C);
    return const Color(0xFFE8634C);
  }

  // ══════════════════════════════════════════════════════════
  // SEARCH BAR
  // ══════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
          boxShadow: shadowMd,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.oceanDeep,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text1,
                ),
                decoration: InputDecoration(
                  hintText: 'Search attractions, beaches…',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppColors.text3,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          splashRadius: 18,
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.text3,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _openFilterSheet,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.oceanDeep,
                  boxShadow: shadowOcean,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                    if (_minRating > 0 ||
                        _selectedPrice != 'All' ||
                        _showFavouritesOnly)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.oceanDeep,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FILTER SHEET
  // ══════════════════════════════════════════════════════════
  void _openFilterSheet() {
    double tempRating = _minRating;
    String tempPrice = _selectedPrice;
    bool tempFavOnly = _showFavouritesOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Filter Attractions',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Price Range',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Free', '฿', '฿฿', '฿฿฿'].map((p) {
                    final active = tempPrice == p;
                    return GestureDetector(
                      onTap: () => setModal(() => tempPrice = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.oceanDeep
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          p,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.text2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Text(
                  'Minimum Rating: ${tempRating.toStringAsFixed(1)} ★',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text2,
                  ),
                ),
                Slider(
                  value: tempRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  label: tempRating.toStringAsFixed(1),
                  activeColor: AppColors.oceanDeep,
                  inactiveColor: AppColors.oceanTint,
                  onChanged: (v) => setModal(() => tempRating = v),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  value: tempFavOnly,
                  activeColor: AppColors.oceanDeep,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Favourites only',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text1,
                    ),
                  ),
                  onChanged: (v) => setModal(() => tempFavOnly = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _minRating = 0.0;
                            _selectedPrice = 'All';
                            _showFavouritesOnly = false;
                          });
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _minRating = tempRating;
                            _selectedPrice = tempPrice;
                            _showFavouritesOnly = tempFavOnly;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.oceanDeep,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION HEADER
  // ══════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title, String? linkText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
            ),
          ),
          const Spacer(),
          if (linkText != null)
            Text(
              linkText,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.oceanDeep,
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TRAVEL TIPS
  // ══════════════════════════════════════════════════════════
  Widget _buildTravelTips() {
    return SizedBox(
      height: 110,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        onPageChanged: (i) => setState(() => _activeTipIndex = i),
        itemCount: _travelTips.length,
        itemBuilder: (_, i) {
          final tip = _travelTips[i];
          return Container(
            margin: const EdgeInsets.only(right: 10, left: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderLight, width: 1.5),
              boxShadow: shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tip.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(tip.icon, size: 22, color: tip.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tip.title,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: AppColors.text2,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TRENDING STRIP — now with real images
  // ══════════════════════════════════════════════════════════
  Widget _buildTrendingStrip() {
    final trending = _trendingCards;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: trending.length,
        itemBuilder: (_, i) {
          final card = trending[i];
          return GestureDetector(
            onTap: () => _navigateToPoi(card),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  // ── Image thumbnail with rating badge ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            card.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: card.gradientColors,
                                ),
                              ),
                              child: Icon(
                                card.placeholderIcon,
                                size: 26,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                          // Dark overlay for badge readability
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.55),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Rating badge
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 9,
                                    color: AppColors.goldLight,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    card.rating.toString(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text2,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // CATEGORY CHIPS
  // ══════════════════════════════════════════════════════════
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final active = i == _selectedCat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.oceanDeep : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: active ? AppColors.oceanDeep : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 15,
                    color: active ? Colors.white : AppColors.text2,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cat.label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      color: active ? Colors.white : AppColors.text2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // POI VERTICAL LIST — with real images
  // ══════════════════════════════════════════════════════════
  Widget _buildPoiVerticalList() {
    final cards = _filteredPoiCards;

    if (cards.isEmpty) {
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 28,
                color: AppColors.text3,
              ),
              const SizedBox(height: 8),
              Text(
                'No attractions found',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: cards.map((card) => _buildPoiListCard(card)).toList(),
      ),
    );
  }

  Widget _buildPoiListCard(_PoiCard card) {
    return GestureDetector(
      onTap: () => _navigateToPoi(card),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: shadowMd,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // ── Left: POI image ──────────────────────────
            SizedBox(
              width: 96,
              height: 108,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Real image with gradient fallback
                  Image.asset(
                    card.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: card.gradientColors,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          card.placeholderIcon,
                          size: 32,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                  // Subtle dark overlay for badges
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.25),
                        ],
                      ),
                    ),
                  ),
                  // Fav heart — tappable, wired to AppStore
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _togglePoiFav(card),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppStore.isPoiSaved(card.name)
                              ? AppColors.coral.withOpacity(0.85)
                              : Colors.black.withOpacity(0.30),
                        ),
                        child: Icon(
                          AppStore.isPoiSaved(card.name)
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Price badge
                  Positioned(
                    bottom: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        card.priceRange,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Right: info panel ────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            card.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: AppColors.goldLight,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          card.rating.toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 11,
                          color: AppColors.text3,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            card.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: AppColors.text2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      card.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.text2,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: AppColors.text3,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          card.estimatedTime,
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            color: AppColors.text3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (card.tags.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: card.tags.first.bg,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              card.tags.first.label.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: card.tags.first.fg,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Arrow ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle POI favourite via AppStore ─────────────────────
  void _togglePoiFav(_PoiCard card) {
    final poi = SavedPoiSummary(
      name: card.name,
      location: card.location,
      category: card.category,
      rating: card.rating,
      description: card.description,
      openHours: card.openHours,
      estimatedTime: card.estimatedTime,
      priceRange: card.priceRange,
      gradientColors: card.gradientColors,
      icon: card.placeholderIcon,
      tagLabel: card.tags.isNotEmpty ? card.tags.first.label : card.category,
      tagBg: card.tags.isNotEmpty
          ? card.tags.first.bg
          : const Color(0xFFEAF8FD),
      tagFg: card.tags.isNotEmpty
          ? card.tags.first.fg
          : const Color(0xFF0A7FAB),
      imagePath: card.imagePath,
      longDescription: card.longDescription,
      latitude: card.latitude,
      longitude: card.longitude,
    );

    AppStore.togglePoi(poi);

    // Sync to Firestore (fire-and-forget)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docId = card.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedPois')
          .doc(docId);

      if (AppStore.isPoiSaved(card.name)) {
        // Just saved — add to Firestore
        ref.set({
          'name': card.name,
          'location': card.location,
          'category': card.category,
          'rating': card.rating,
          'description': card.description,
          'openHours': card.openHours,
          'estimatedTime': card.estimatedTime,
          'priceRange': card.priceRange,
          'imagePath': card.imagePath,
          'tagLabel': card.tags.isNotEmpty
              ? card.tags.first.label
              : card.category,
          'longDescription': card.longDescription,
          'latitude': card.latitude,
          'longitude': card.longitude,
          'savedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Just unsaved — remove from Firestore
        ref.delete();
      }
    }
  }

  // ── Navigation helper ────────────────────────────────────
  void _navigateToPoi(_PoiCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PoiDetailScreen(
          poi: PoiModel(
            name: card.name,
            location: card.location,
            category: card.category,
            rating: card.rating,
            description: card.description,
            longDescription: card.longDescription, // ← ADD THIS
            openHours: card.openHours,
            estimatedTime: card.estimatedTime,
            imagePath: card.imagePath,
            gradientColors: card.gradientColors,
            icon: card.placeholderIcon,
            priceRange: card.priceRange,
            isFavourited: card.isFavourited,
            tags: card.tags.map((t) => PoiTag(t.label, t.bg, t.fg)).toList(),
            latitude: card.latitude,
            longitude: card.longitude,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BOTTOM NAV
  // ══════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [0.70, 1.0],
          colors: [AppColors.surface, Colors.transparent],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: shadowLg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _navItem(0, Icons.home_rounded, 'Home')),
            Expanded(child: _navItem(1, Icons.explore_rounded, 'Explore')),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GenerateItineraryScreen(),
                          ),
                        ),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.oceanDeep, AppColors.oceanMid],
                            ),
                            boxShadow: shadowOcean,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'PLAN',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.oceanDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(child: _navItem(3, Icons.map_rounded, 'Trips')),
            Expanded(child: _navItem(4, Icons.person_rounded, 'Profile')),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _selectedNav == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (index == 0) {
          setState(() => _selectedNav = index);
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExploreScreen()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TripsScreen()),
          );
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.oceanTint : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? AppColors.oceanDeep : AppColors.text3,
                ),
                const SizedBox(height: 3),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isActive ? AppColors.oceanDeep : AppColors.text3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DATA CLASSES
// ══════════════════════════════════════════════════════════════
class _WeatherStat {
  final int tempC;
  final String conditionLabel;
  final IconData conditionIcon;
  final int humidity;
  final int windKph;
  final int uvIndex;

  const _WeatherStat({
    required this.tempC,
    required this.conditionLabel,
    required this.conditionIcon,
    required this.humidity,
    required this.windKph,
    required this.uvIndex,
  });

  // Phuket coordinates
  static const double _lat = 7.9519;
  static const double _lon = 98.3381;
  static const String _apiKey =
      '5a342d03f6fcfc825f21cd4385a15c49'; // 🔑 replace this

  static Future<_WeatherStat> fetch() async {
    try {
      final weatherUri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$_lat&lon=$_lon&appid=$_apiKey&units=metric',
      );

      final response = await http.get(weatherUri);
      final w = jsonDecode(response.body);

      final condition = (w['weather'][0]['main'] as String).toLowerCase();

      // ── Time-aware UV estimation ─────────────────────────────
      final int nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int sunrise = (w['sys']['sunrise'] as num).toInt();
      final int sunset = (w['sys']['sunset'] as num).toInt();
      final bool isDaytime = nowUnix >= sunrise && nowUnix <= sunset;

      final int estimatedUv;
      if (!isDaytime) {
        estimatedUv = 0; // no UV at night
      } else {
        final clouds = (w['clouds']['all'] as num).toInt(); // 0–100%
        if (condition.contains('thunder') || condition.contains('rain')) {
          estimatedUv = 2;
        } else if (clouds > 75) {
          estimatedUv = 3;
        } else if (clouds > 50) {
          estimatedUv = 5;
        } else if (clouds > 25) {
          estimatedUv = 7;
        } else {
          estimatedUv = 10; // clear sky in Phuket → very high UV
        }
      }

      return _WeatherStat(
        tempC: (w['main']['temp'] as num).round(),
        conditionLabel: w['weather'][0]['description']
            .toString()
            .split(' ')
            .map((s) => s[0].toUpperCase() + s.substring(1))
            .join(' '),
        conditionIcon: _iconFromCondition(condition),
        humidity: (w['main']['humidity'] as num).toInt(),
        windKph: ((w['wind']['speed'] as num) * 3.6).round(), // m/s → km/h
        uvIndex: estimatedUv,
      );
    } catch (_) {
      // Fallback if API fails
      return const _WeatherStat(
        tempC: 31,
        conditionLabel: 'Partly Cloudy',
        conditionIcon: Icons.wb_cloudy_rounded,
        humidity: 72,
        windKph: 18,
        uvIndex: 8,
      );
    }
  }

  static IconData _iconFromCondition(String condition) {
    if (condition.contains('thunder')) return Icons.thunderstorm_rounded;
    if (condition.contains('drizzle') || condition.contains('rain'))
      return Icons.grain_rounded;
    if (condition.contains('snow')) return Icons.ac_unit_rounded;
    if (condition.contains('cloud')) return Icons.wb_cloudy_rounded;
    if (condition.contains('mist') || condition.contains('fog'))
      return Icons.foggy;
    return Icons.wb_sunny_rounded;
  }
}

class _TravelTip {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  const _TravelTip({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });
}
