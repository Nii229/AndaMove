// ============================================================
// AndaMove — My Trips Screen
// File: lib/screens/screen11_trips.dart
//
// Changes vs previous version:
//   [FIX] _onCtaTap now merges AppStore.getAddedPoisForTrip()
//         into selectedPois before pushing ItineraryResultScreen,
//         so POIs added via screen6b "Add to Existing" appear
//         in screen8's timeline.
//   [NEW] _mergeExtraPois() helper — converts extra POI name
//         strings into PoiItem objects and appends to base list.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_store.dart';
import 'screen7_generateItinerary.dart' show GenerateItineraryScreen, PoiItem;
import 'screen8_itineraryResult.dart' show ItineraryResultScreen, ItineraryViewMode;
import 'screen10_navigation.dart' show NavigationScreen;
import 'screen5_home.dart' show HomeScreen;
import 'screen14_explore.dart' show ExploreScreen;
import 'screen12_profile.dart' show ProfileScreen;

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
  static const Color greenLight = Color(0xFF4ADE80);
  static const Color greenTint = Color(0xFFEEF5EE);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleTint = Color(0xFFF3EFFE);
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
    color: const Color(0xFF0A1F28).withOpacity(0.10),
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
class _FilterTab {
  final String label;
  const _FilterTab(this.label);
}

enum TripStatus { inProgress, upcoming, completed, draft }

class _StopPill {
  final IconData icon;
  final String label;
  const _StopPill(this.icon, this.label);
}

class _StatItem {
  final IconData icon;
  final Color color;
  final String value;
  const _StatItem(this.icon, this.color, this.value);
}

class _Trip {
  final String id;
  final TripStatus status;
  final String date;
  final String name;
  final String statusLabel;
  final IconData statusIcon;
  final Color statusBg;
  final Color statusFg;
  final Color statusBorder;
  final IconData transportIcon;
  final String transportLabel;
  final List<_StopPill> stops;
  final String moreLabel;
  final List<_StatItem> stats;
  final String ctaLabel;
  final IconData ctaIcon;
  final List<Color> ctaGradient;
  final double opacity;
  final List<Color> stripeColors;

  const _Trip({
    required this.id,
    required this.status,
    required this.date,
    required this.name,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusBg,
    required this.statusFg,
    required this.statusBorder,
    required this.transportIcon,
    required this.transportLabel,
    required this.stops,
    required this.moreLabel,
    required this.stats,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.ctaGradient,
    this.opacity = 1.0,
    this.stripeColors = const [],
  });

  _Trip copyWith({String? id, String? name, double? opacity}) => _Trip(
    id: id ?? this.id,
    status: status,
    date: date,
    name: name ?? this.name,
    statusLabel: statusLabel,
    statusIcon: statusIcon,
    statusBg: statusBg,
    statusFg: statusFg,
    statusBorder: statusBorder,
    transportIcon: transportIcon,
    transportLabel: transportLabel,
    stops: stops,
    moreLabel: moreLabel,
    stats: stats,
    ctaLabel: ctaLabel,
    ctaIcon: ctaIcon,
    ctaGradient: ctaGradient,
    opacity: opacity ?? this.opacity,
    stripeColors: stripeColors,
  );
}

// ══════════════════════════════════════════════════════════════
// MOCK POI DATA
// ══════════════════════════════════════════════════════════════
final List<PoiItem> _phuketCulturalMockPois = [
  PoiItem(
    name: 'Kata Beach',
    category: 'Beach',
    rating: 4.6,
    distance: 'Start · Kata',
    thumbIcon: Icons.beach_access_rounded,
    thumbGradient: const [Color(0xFF0A7FAB), Color(0xFF1AAECF)],
    imagePath: 'assets/images/kata_beach.jpg',
  ),
  PoiItem(
    name: 'The Big Buddha',
    category: 'Temple',
    rating: 4.8,
    distance: '8.5 km from Kata',
    thumbIcon: Icons.temple_buddhist_rounded,
    thumbGradient: const [Color(0xFFC8912E), Color(0xFFF0C060)],
    imagePath: 'assets/images/the_big_buddha.jpg',
  ),
  PoiItem(
    name: 'Wat Chalong',
    category: 'Culture',
    rating: 4.5,
    distance: '3.2 km',
    thumbIcon: Icons.account_balance_rounded,
    thumbGradient: const [Color(0xFFE8634C), Color(0xFFFF8A70)],
    imagePath: 'assets/images/wat_chalong.jpg',
  ),
  PoiItem(
    name: 'Karon Viewpoint',
    category: 'Viewpoint',
    rating: 4.7,
    distance: '5.1 km',
    thumbIcon: Icons.landscape_rounded,
    thumbGradient: const [Color(0xFF7C3AED), Color(0xFF9B5CF6)],
    imagePath: 'assets/images/karon_viewpoint.jpg',
  ),
];

final List<PoiItem> _phiPhiMockPois = [
  PoiItem(
    name: 'Phi Phi Day Trip',
    category: 'Adventure',
    rating: 4.9,
    distance: 'Start · Phi Phi Don',
    thumbIcon: Icons.sailing_rounded,
    thumbGradient: const [Color(0xFF0A7FAB), Color(0xFF1AAECF)],
    imagePath: 'assets/images/phi_phi_island.jpg',
  ),
  PoiItem(
    name: 'Freedom Beach',
    category: 'Beach',
    rating: 4.8,
    distance: '4.5 km by longtail',
    thumbIcon: Icons.beach_access_rounded,
    thumbGradient: const [Color(0xFF16A34A), Color(0xFF4ADE80)],
    imagePath: 'assets/images/freedom_beach.jpg',
  ),
  PoiItem(
    name: 'Karon Viewpoint',
    category: 'Viewpoint',
    rating: 4.7,
    distance: '2.1 km',
    thumbIcon: Icons.landscape_rounded,
    thumbGradient: const [Color(0xFF7C3AED), Color(0xFF9B5CF6)],
    imagePath: 'assets/images/karon_viewpoint.jpg',
  ),
  PoiItem(
    name: 'Sirinat Natl Park',
    category: 'Nature',
    rating: 4.6,
    distance: '5.3 km',
    thumbIcon: Icons.park_rounded,
    thumbGradient: const [Color(0xFF15803D), Color(0xFF22C55E)],
    imagePath: 'assets/images/sirinat_national_park.jpg',
  ),
  PoiItem(
    name: 'Old Phuket Town',
    category: 'Culture',
    rating: 4.9,
    distance: '8.1 km',
    thumbIcon: Icons.location_city_rounded,
    thumbGradient: const [Color(0xFF8B4513), Color(0xFFC8912E)],
    imagePath: 'assets/images/old_phuket_town.jpg',
  ),
];

final Map<String, List<PoiItem>> _tripMockPois = {
  'trip_phuket_cultural': _phuketCulturalMockPois,
  'trip_phi_phi': _phiPhiMockPois,
};

const Map<String, List<String>> _tripPoiNames = {
  'trip_phuket_cultural': ['Kata Beach', 'The Big Buddha', 'Wat Chalong', 'Karon Viewpoint'],
  'trip_phi_phi': ['Phi Phi Day Trip', 'Freedom Beach', 'Karon Viewpoint', 'Sirinat Natl Park', 'Old Phuket Town'],
  'trip_old_town': ['Old Phuket Town', 'Walking Street', 'Blue Elephant', 'Rawai Seafood Mkt'],
};

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});
  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;

  late List<_Trip> _trips;
  final List<_Trip> _duplicatedTrips = [];
  final Set<String> _archivedIds = {};
  final Set<String> _deletedIds = {};
  final Map<String, String> _renamedTrips = {};

  late final AnimationController _sheenCtrl;
  late final Animation<double> _sheenAnim;

  void _onStoreUpdate() => setState(() {});

  static final List<_Trip> _kBaseTrips = [
    _Trip(
      id: 'trip_phuket_cultural',
      status: TripStatus.inProgress,
      date: 'Mon, 10 Mar 2026',
      name: 'Phuket Cultural & Beach Day',
      statusLabel: 'In Progress',
      statusIcon: Icons.my_location_rounded,
      statusBg: const Color(0xFFFFF8EC),
      statusFg: AppColors.gold,
      statusBorder: AppColors.gold,
      transportIcon: Icons.moped_rounded,
      transportLabel: 'Scooter',
      stops: const [
        _StopPill(Icons.beach_access_rounded, 'Kata'),
        _StopPill(Icons.temple_buddhist_rounded, 'Big Buddha'),
      ],
      moreLabel: '+2 more',
      stats: const [
        _StatItem(Icons.location_on_rounded, AppColors.oceanDeep, '4 stops'),
        _StatItem(Icons.schedule_rounded, AppColors.gold, '6h 40m'),
        _StatItem(Icons.near_me_rounded, AppColors.green, '14.2 km'),
      ],
      ctaLabel: 'Continue Trip',
      ctaIcon: Icons.navigation_rounded,
      ctaGradient: [AppColors.gold, Color(0xFFE8A840)],
      stripeColors: [AppColors.gold, AppColors.goldLight],
    ),
    _Trip(
      id: 'trip_phi_phi',
      status: TripStatus.upcoming,
      date: 'Fri, 13 Mar 2026',
      name: 'Phi Phi Island Escape',
      statusLabel: 'In 3 Days',
      statusIcon: Icons.event_rounded,
      statusBg: AppColors.oceanTint,
      statusFg: AppColors.oceanDeep,
      statusBorder: AppColors.oceanDeep,
      transportIcon: Icons.directions_boat_rounded,
      transportLabel: 'Boat',
      stops: const [
        _StopPill(Icons.sailing_rounded, 'Phi Phi Don'),
        _StopPill(Icons.beach_access_rounded, 'Maya Bay'),
      ],
      moreLabel: '+3 more',
      stats: const [
        _StatItem(Icons.location_on_rounded, AppColors.oceanDeep, '5 stops'),
        _StatItem(Icons.schedule_rounded, AppColors.gold, 'Full Day'),
        _StatItem(Icons.near_me_rounded, AppColors.green, '48 km'),
      ],
      ctaLabel: 'View Itinerary',
      ctaIcon: Icons.open_in_full_rounded,
      ctaGradient: [AppColors.oceanDeep, AppColors.oceanMid],
      stripeColors: [AppColors.oceanDeep, AppColors.oceanMid],
    ),
    _Trip(
      id: 'trip_old_town',
      status: TripStatus.completed,
      opacity: 0.85,
      date: 'Sun, 8 Mar 2026',
      name: 'Old Town Food Trail',
      statusLabel: 'Completed',
      statusIcon: Icons.check_circle_rounded,
      statusBg: AppColors.greenTint,
      statusFg: AppColors.green,
      statusBorder: AppColors.green,
      transportIcon: Icons.directions_walk_rounded,
      transportLabel: 'Walking',
      stops: const [
        _StopPill(Icons.restaurant_rounded, 'Kopitiam'),
        _StopPill(Icons.store_rounded, 'Sino-Portuguese'),
      ],
      moreLabel: '+2 more',
      stats: const [
        _StatItem(Icons.location_on_rounded, AppColors.oceanDeep, '4 stops'),
        _StatItem(Icons.schedule_rounded, AppColors.gold, '3h 20m'),
        _StatItem(Icons.near_me_rounded, AppColors.green, '4.8 km'),
      ],
      ctaLabel: 'Re-run Trip',
      ctaIcon: Icons.replay_rounded,
      ctaGradient: [AppColors.green, Color(0xFF22C55E)],
      stripeColors: [AppColors.green, AppColors.greenLight],
    ),
  ];

  _Trip _convertStoredTrip(StoredTrip stored) {
    IconData _stopIcon(String type) {
      switch (type.toLowerCase()) {
        case 'beach': return Icons.beach_access_rounded;
        case 'temple': return Icons.temple_buddhist_rounded;
        case 'food':
        case 'market': return Icons.restaurant_rounded;
        case 'view':
        case 'viewpoint': return Icons.landscape_rounded;
        case 'nature':
        case 'wildlife': return Icons.forest_rounded;
        case 'culture': return Icons.account_balance_rounded;
        case 'adventure': return Icons.surfing_rounded;
        case 'nightlife': return Icons.nightlife_rounded;
        case 'heritage': return Icons.museum_rounded;
        case 'attraction': return Icons.attractions_rounded;
        case 'shopping': return Icons.shopping_bag_rounded;
        default: return Icons.place_rounded;
      }
    }

    IconData _transportIcon(String t) {
      switch (t) {
        case 'Scooter': return Icons.moped_rounded;
        case 'Tuk-tuk': return Icons.electric_rickshaw_rounded;
        case 'Car':     return Icons.directions_car_rounded;
        case 'Walk':    return Icons.directions_walk_rounded;
        default:        return Icons.directions_walk_rounded;
      }
    }

    final preview = stored.stops.take(2)
        .map((s) => _StopPill(_stopIcon(s.type), s.name))
        .toList();
    final more = stored.stops.length - preview.length;

    if (stored.tripDate == null) {
      return _Trip(
        id: stored.id,
        status: TripStatus.upcoming,
        date: 'Not Scheduled · From Explore',
        name: stored.name,
        statusLabel: 'Not Scheduled',
        statusIcon: Icons.explore_rounded,
        statusBg: AppColors.oceanTint,
        statusFg: AppColors.oceanDeep,
        statusBorder: AppColors.oceanDeep,
        transportIcon: Icons.directions_walk_rounded,
        transportLabel: 'TBD',
        stops: preview,
        moreLabel: more > 0 ? '+$more more' : '${stored.stops.length} stops total',
        stats: [
          _StatItem(Icons.location_on_rounded, AppColors.oceanDeep, '${stored.stops.length} stops'),
          _StatItem(Icons.schedule_rounded, AppColors.gold, stored.totalDuration),
          _StatItem(Icons.near_me_rounded, AppColors.green, 'TBD'),
        ],
        ctaLabel: 'Start Planning',
        ctaIcon: Icons.edit_rounded,
        ctaGradient: [AppColors.oceanDeep, AppColors.oceanMid],
        stripeColors: [AppColors.oceanDeep, AppColors.oceanMid],
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDay = DateTime(
      stored.tripDate!.year,
      stored.tripDate!.month,
      stored.tripDate!.day,
    );

    final bool isToday  = tripDay == today;
    final bool isFuture = tripDay.isAfter(today);

    const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${days[stored.tripDate!.weekday - 1]}, '
        '${stored.tripDate!.day} ${months[stored.tripDate!.month - 1]} '
        '${stored.tripDate!.year}';

    final commonStats = [
      _StatItem(Icons.location_on_rounded, AppColors.oceanDeep, '${stored.stops.length} stops'),
      _StatItem(Icons.schedule_rounded, AppColors.gold, stored.totalDuration),
      _StatItem(Icons.near_me_rounded, AppColors.green, 'TBD'),
    ];

    if (isToday) {
      return _Trip(
        id: stored.id, status: TripStatus.inProgress, date: dateStr, name: stored.name,
        statusLabel: 'In Progress', statusIcon: Icons.my_location_rounded,
        statusBg: const Color(0xFFFFF8EC), statusFg: AppColors.gold, statusBorder: AppColors.gold,
        transportIcon: _transportIcon(stored.transport), transportLabel: stored.transport,
        stops: preview, moreLabel: more > 0 ? '+$more more' : '${stored.stops.length} stops total',
        stats: commonStats, ctaLabel: 'Continue Trip', ctaIcon: Icons.navigation_rounded,
        ctaGradient: [AppColors.gold, const Color(0xFFE8A840)],
        stripeColors: [AppColors.gold, AppColors.goldLight],
      );
    } else if (isFuture) {
      final diff = tripDay.difference(today).inDays;
      final inLabel = diff == 1 ? 'Tomorrow' : 'In $diff Days';
      return _Trip(
        id: stored.id, status: TripStatus.upcoming, date: dateStr, name: stored.name,
        statusLabel: inLabel, statusIcon: Icons.event_rounded,
        statusBg: AppColors.oceanTint, statusFg: AppColors.oceanDeep, statusBorder: AppColors.oceanDeep,
        transportIcon: _transportIcon(stored.transport), transportLabel: stored.transport,
        stops: preview, moreLabel: more > 0 ? '+$more more' : '${stored.stops.length} stops total',
        stats: commonStats, ctaLabel: 'View Itinerary', ctaIcon: Icons.open_in_full_rounded,
        ctaGradient: [AppColors.oceanDeep, AppColors.oceanMid],
        stripeColors: [AppColors.oceanDeep, AppColors.oceanMid],
      );
    } else {
      return _Trip(
        id: stored.id, status: TripStatus.completed, opacity: 0.85, date: dateStr, name: stored.name,
        statusLabel: 'Completed', statusIcon: Icons.check_circle_rounded,
        statusBg: AppColors.greenTint, statusFg: AppColors.green, statusBorder: AppColors.green,
        transportIcon: _transportIcon(stored.transport), transportLabel: stored.transport,
        stops: preview, moreLabel: more > 0 ? '+$more more' : '${stored.stops.length} stops total',
        stats: commonStats, ctaLabel: 'Re-run Trip', ctaIcon: Icons.replay_rounded,
        ctaGradient: [AppColors.green, const Color(0xFF22C55E)],
        stripeColors: [AppColors.green, AppColors.greenLight],
      );
    }
  }

  TripStatus _effectiveStatus(_Trip trip) {
    if (AppStore.completedTripIds.contains(trip.id)) return TripStatus.completed;
    if (AppStore.inProgressTripIds.contains(trip.id)) return TripStatus.inProgress;
    return trip.status;
  }

  List<_Trip> get _visibleTrips => [
    ..._trips.where((t) => !_deletedIds.contains(t.id) && !_archivedIds.contains(t.id)),
    ..._duplicatedTrips.where((t) => !_deletedIds.contains(t.id) && !_archivedIds.contains(t.id)),
    ...AppStore.followedTrips.map(_convertStoredTrip),
  ];

  int _statusPriority(TripStatus s) {
    switch (s) {
      case TripStatus.inProgress: return 0;
      case TripStatus.upcoming:   return 1;
      case TripStatus.completed:  return 2;
      case TripStatus.draft:      return 3;
    }
  }

  List<_Trip> get _filteredTrips {
    final all = _visibleTrips;
    List<_Trip> base;
    switch (_selectedTab) {
      case 1: base = all.where((t) => _effectiveStatus(t) == TripStatus.inProgress).toList(); break;
      case 2: base = all.where((t) => _effectiveStatus(t) == TripStatus.upcoming).toList(); break;
      case 3: base = all.where((t) => _effectiveStatus(t) == TripStatus.completed).toList(); break;
      default: base = List.from(all);
    }
    base.sort((a, b) {
      final sa = _statusPriority(_effectiveStatus(a));
      final sb = _statusPriority(_effectiveStatus(b));
      if (sa != sb) return sa.compareTo(sb);
      return b.date.compareTo(a.date);
    });
    return base;
  }

  List<_FilterTab> get _tabs {
    final v = _visibleTrips;
    final active = v.where((t) => _effectiveStatus(t) == TripStatus.inProgress).length;
    final soon   = v.where((t) => _effectiveStatus(t) == TripStatus.upcoming).length;
    final done   = v.where((t) => _effectiveStatus(t) == TripStatus.completed).length;
    return [
      _FilterTab('All (${v.length})'),
      _FilterTab('Active ($active)'),
      _FilterTab('Upcoming ($soon)'),
      _FilterTab('Done ($done)'),
    ];
  }

  String _displayName(_Trip t) => _renamedTrips[t.id] ?? t.name;

  @override
  void initState() {
    super.initState();
    _trips = List.from(_kBaseTrips);
    _sheenCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _sheenAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _sheenCtrl, curve: Curves.easeInOut));
    AppStore.addListener(_onStoreUpdate);
  }

  @override
  void dispose() {
    AppStore.removeListener(_onStoreUpdate);
    _sheenCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  // [NEW] Merge extra POIs added from screen6b into a base list
  // Converts stored POI name strings → PoiItem objects and
  // appends them, avoiding duplicates by name.
  // ══════════════════════════════════════════════════════════
  List<PoiItem> _mergeExtraPois(String tripId, List<PoiItem> basePois) {
    final extraNames = AppStore.getAddedPoisForTrip(tripId);
    if (extraNames.isEmpty) return basePois;

    // Avoid adding a POI that's already in the base list
    final existingNames = basePois.map((p) => p.name).toSet();
    final newPois = extraNames
        .where((name) => !existingNames.contains(name))
        .map((name) => PoiItem(
              name: name,
              category: 'Place',
              rating: 4.5,
              distance: '// TODO: Google Maps',
              thumbIcon: Icons.place_rounded,
              thumbGradient: const [Color(0xFF0A7FAB), Color(0xFF1AAECF)],
              imagePath:
                  'assets/images/${name.toLowerCase().replaceAll(' ', '_')}.jpg',
            ))
        .toList();

    return [...basePois, ...newPois];
  }

  // ══════════════════════════════════════════════════════════
  // ACTION HANDLERS
  // ══════════════════════════════════════════════════════════
  void _onCtaTap(_Trip trip) {
    final status = _effectiveStatus(trip);
    final stored = _findStoredTrip(trip.id);

    switch (status) {
      // ── A. Continue Trip → screen8 (inProgress mode) ────────
      case TripStatus.inProgress:
        final basePois = _tripMockPois[trip.id]
            ?? (stored != null ? _buildPoisFromStored(stored) : _phuketCulturalMockPois);
        // [FIX] Merge any POIs added via screen6b before opening screen8
        final pois = _mergeExtraPois(trip.id, basePois);
        final date = stored?.tripDate ?? DateTime(2026, 3, 10);
        final time = stored != null
            ? TimeOfDay(hour: stored.startHour, minute: stored.startMinute)
            : const TimeOfDay(hour: 9, minute: 0);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ItineraryResultScreen(
            transport: trip.transportLabel,
            categories: pois.map((p) => p.category).toSet().toList(),
            selectedPois: pois,
            date: date, time: time,
            tripId: trip.id,
            viewMode: ItineraryViewMode.inProgress,
          ),
        ));
        break;

      // ── B. View Itinerary → screen8 (upcoming mode) ─────────
      case TripStatus.upcoming:
        if (stored != null && stored.tripDate == null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => GenerateItineraryScreen(
              preSelectedPoiNames: stored.stops.map((s) => s.name).toList(),
            ),
          ));
          break;
        }
        final basePois = _tripMockPois[trip.id]
            ?? (stored != null ? _buildPoisFromStored(stored) : _phiPhiMockPois);
        // [FIX] Merge any POIs added via screen6b before opening screen8
        final pois = _mergeExtraPois(trip.id, basePois);
        final date = stored?.tripDate ?? DateTime(2026, 3, 13);
        final time = stored != null
            ? TimeOfDay(hour: stored.startHour, minute: stored.startMinute)
            : const TimeOfDay(hour: 8, minute: 0);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ItineraryResultScreen(
            transport: trip.transportLabel,
            categories: pois.map((p) => p.category).toSet().toList(),
            selectedPois: pois,
            date: date, time: time,
            tripId: trip.id,
            viewMode: ItineraryViewMode.upcoming,
          ),
        ));
        break;

      // ── C. Re-run Trip → screen7 (preSelectedPoiNames) ──────
      case TripStatus.completed:
        final poiNames = _tripPoiNames[trip.id]
            ?? stored?.stops.map((s) => s.name).toList()
            ?? [];
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => GenerateItineraryScreen(preSelectedPoiNames: poiNames),
        ));
        break;

      // ── D. Continue Editing → screen7 ───────────────────────
      case TripStatus.draft:
        final poiNames = _tripPoiNames[trip.id]
            ?? stored?.stops.map((s) => s.name).toList()
            ?? [];
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => GenerateItineraryScreen(preSelectedPoiNames: poiNames),
        ));
        break;
    }
  }

  StoredTrip? _findStoredTrip(String id) {
    try {
      return AppStore.followedTrips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<PoiItem> _buildPoisFromStored(StoredTrip stored) {
    return stored.stops.map((s) {
      final grad = _categoryGradient(s.type);
      final icon = _categoryIcon(s.type);
      return PoiItem(
        name: s.name, category: s.type, rating: 4.5, distance: s.distance,
        thumbIcon: icon, thumbGradient: grad,
        imagePath: 'assets/images/${s.name.toLowerCase().replaceAll(' ', '_')}.jpg',
      );
    }).toList();
  }

  List<Color> _categoryGradient(String cat) {
    switch (cat.toLowerCase()) {
      case 'beach':      return const [Color(0xFF0A7FAB), Color(0xFF38BDF8)];
      case 'temple':     return const [Color(0xFFC8912E), Color(0xFFF0C060)];
      case 'nature':     return const [Color(0xFF16A34A), Color(0xFF22C55E)];
      case 'culture':    return const [Color(0xFF8B4513), Color(0xFFC8912E)];
      case 'food':       return const [Color(0xFFE8634C), Color(0xFFF97316)];
      case 'adventure':  return const [Color(0xFF0369A1), Color(0xFF0EA5E9)];
      case 'nightlife':  return const [Color(0xFF7C3AED), Color(0xFFDB2777)];
      case 'heritage':   return const [Color(0xFF92400E), Color(0xFFB45309)];
      case 'viewpoint':  return const [Color(0xFFF59E0B), Color(0xFFF97316)];
      case 'attraction': return const [Color(0xFF06B6D4), Color(0xFF0891B2)];
      case 'shopping':   return const [Color(0xFF475569), Color(0xFF64748B)];
      default:           return const [Color(0xFF0A7FAB), Color(0xFF1AAECF)];
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'beach':      return Icons.beach_access_rounded;
      case 'temple':     return Icons.temple_buddhist_rounded;
      case 'nature':     return Icons.forest_rounded;
      case 'culture':    return Icons.account_balance_rounded;
      case 'food':       return Icons.restaurant_rounded;
      case 'adventure':  return Icons.surfing_rounded;
      case 'nightlife':  return Icons.nightlife_rounded;
      case 'heritage':   return Icons.museum_rounded;
      case 'viewpoint':  return Icons.landscape_rounded;
      case 'attraction': return Icons.attractions_rounded;
      case 'shopping':   return Icons.shopping_bag_rounded;
      default:           return Icons.place_rounded;
    }
  }

  // ── [NEW] helper: returns display value for a stat cell,
  // adding AppStore-tracked extra POIs to the stop count (index 0)
  String _statValueFor(_Trip trip, int statIndex) {
    final raw = trip.stats[statIndex].value;
    if (statIndex != 0) return raw;
    final extra = AppStore.getAddedPoisForTrip(trip.id).length;
    if (extra == 0) return raw;
    final match = RegExp(r'(\d+)').firstMatch(raw);
    if (match == null) return raw;
    return '${int.parse(match.group(1)!) + extra} stops';
  }

  void _showKebabMenu(_Trip trip) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _KebabSheet(
        tripName: _displayName(trip),
        onRename: () { Navigator.pop(context); _showRenameDialog(trip); },
        onDuplicate: () { Navigator.pop(context); _duplicateTrip(trip); },
        onArchive: () {
          Navigator.pop(context);
          setState(() => _archivedIds.add(trip.id));
          _showSnack('"${_displayName(trip)}" archived', AppColors.text2);
        },
        onDelete: () { Navigator.pop(context); _showDeleteSheet(trip); },
      ),
    );
  }

  void _showRenameDialog(_Trip trip) {
    final ctrl = TextEditingController(text: _displayName(trip));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Rename Trip', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text1)),
        content: TextField(
          controller: ctrl, autofocus: true,
          style: GoogleFonts.outfit(fontSize: 15, color: AppColors.text1),
          decoration: InputDecoration(
            hintText: 'Trip name',
            hintStyle: GoogleFonts.outfit(color: AppColors.text3),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.oceanDeep, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.text2)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) setState(() => _renamedTrips[trip.id] = v);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.oceanDeep, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
            child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _duplicateTrip(_Trip trip) {
    final copy = trip.copyWith(
      id: 'dup_${trip.id}_${DateTime.now().millisecondsSinceEpoch}',
      name: '${_displayName(trip)} (Copy)',
    );
    setState(() => _duplicatedTrips.add(copy));
    _showSnack('"${_displayName(trip)}" duplicated', AppColors.oceanDeep);
  }

  void _showShareSheet(_Trip trip) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(tripName: _displayName(trip)),
    );
  }

  void _showDeleteSheet(_Trip trip) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _DeleteSheet(
        tripName: _displayName(trip),
        onConfirm: () {
          Navigator.pop(context);
          setState(() => _deletedIds.add(trip.id));
          _showSnack('"${_displayName(trip)}" deleted', AppColors.coral);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      duration: const Duration(seconds: 2),
    ));
  }

  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        _buildHeader(),
        Expanded(
          child: _filteredTrips.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildStatsBanner(),
                    const SizedBox(height: 20),
                    _buildSectionHeader(),
                    const SizedBox(height: 12),
                    ..._filteredTrips.map(_buildTripCard),
                  ]),
                ),
        ),
      ]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    final tabs = _tabs;
    return SafeArea(
      bottom: false, left: false, right: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.borderLight))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: 'My ', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.text1)),
            TextSpan(text: 'Trips', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, color: AppColors.oceanDeep)),
          ])),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
            child: Row(children: List.generate(tabs.length, (i) {
              final isActive = i == _selectedTab;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: i < tabs.length - 1 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.oceanDeep : AppColors.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: isActive ? AppColors.oceanDeep : AppColors.border, width: 1.5),
                  ),
                  child: Text(tabs[i].label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: isActive ? Colors.white : AppColors.text2)),
                ),
              );
            })),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    final labels = ['trips', 'active trips', 'upcoming trips', 'completed trips'];
    final label = labels[_selectedTab.clamp(0, labels.length - 1)];
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.surface2, shape: BoxShape.circle), child: const Icon(Icons.map_outlined, size: 32, color: AppColors.text3)),
      const SizedBox(height: 16),
      Text('No $label yet', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text2)),
      const SizedBox(height: 6),
      Text('Start planning your next adventure!', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.text3)),
    ]));
  }

  Widget _buildStatsBanner() {
    final allV = _visibleTrips;
    final doneCount = allV.where((t) => _effectiveStatus(t) == TripStatus.completed).length;
    final stopsCount = allV.fold<int>(0, (sum, t) {
      final base = RegExp(r'(\d+)').firstMatch(t.stats.first.value);
      final baseN = base != null ? int.parse(base.group(1)!) : t.stops.length;
      return sum + baseN + AppStore.getAddedPoisForTrip(t.id).length;
    });
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
          colors: [Color(0xFF061018), Color(0xFF0A3D5C), Color(0xFF0A7FAB)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(children: [
          Positioned(top: -20, right: -20, child: Container(width: 140, height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.gold.withOpacity(0.15), Colors.transparent], stops: const [0.0, 0.65])))),
          Positioned(bottom: 0, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final isSmall = i.isOdd;
                return Container(margin: const EdgeInsets.only(right: 12), width: isSmall ? 2.0 : 3.0, height: isSmall ? 2.0 : 3.0,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.goldLight.withOpacity(isSmall ? 0.40 : 0.50)));
              }))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YOUR EXPLORER SUMMARY', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: Colors.white.withOpacity(0.50))),
            const SizedBox(height: 4),
            Text('${allV.length} Adventures Planned 🌴', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 12),
            IntrinsicHeight(child: Row(children: [
              _statCol('$stopsCount', 'Places'),
              _statColDivider(),
              _statCol('$doneCount', 'Done'),
              _statColDivider(),
              _statCol('${allV.length}', 'Trips'),
            ])),
          ]),
        ]),
      ),
    );
  }

  Widget _statCol(String val, String lbl) => Expanded(child: Column(children: [
    Text(val, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
    Text(lbl.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Colors.white.withOpacity(0.45)), textAlign: TextAlign.center),
  ]));

  Widget _statColDivider() => Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 2), color: Colors.white.withOpacity(0.15));

  Widget _buildSectionHeader() => Text('Your Trips', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1));

  Widget _buildTripCard(_Trip trip) {
    final effective = _effectiveStatus(trip);
    final wasJustCompleted = effective == TripStatus.completed && trip.status == TripStatus.inProgress;
    final wasJustStarted = effective == TripStatus.inProgress && trip.status == TripStatus.upcoming;

    return Opacity(
      opacity: trip.opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.borderLight, width: 1.5), boxShadow: shadowMd),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          _buildStripe(trip, overrideCompleted: wasJustCompleted, overrideStarted: wasJustStarted),
          _buildCardBody(trip, effective, wasJustCompleted, wasJustStarted),
          _buildCardCta(trip, effective, wasJustCompleted, wasJustStarted),
        ]),
      ),
    );
  }

  Widget _buildStripe(_Trip trip, {bool overrideCompleted = false, bool overrideStarted = false}) {
    final colors = overrideCompleted ? [AppColors.green, AppColors.greenLight]
        : overrideStarted ? [AppColors.gold, AppColors.goldLight]
        : trip.stripeColors;
    if (colors.isEmpty) {
      return SizedBox(height: 4, child: CustomPaint(painter: DashedStripePainter(color: AppColors.border), size: const Size(double.infinity, 4)));
    }
    return Container(height: 4, decoration: BoxDecoration(gradient: LinearGradient(colors: colors)));
  }

  Widget _buildCardBody(_Trip trip, TripStatus effective, bool wasJustCompleted, bool wasJustStarted) {
    final Color badgeBg, badgeFg, badgeBdr;
    final IconData badgeIcon;
    final String badgeLabel;

    if (wasJustCompleted) {
      badgeBg = AppColors.greenTint; badgeFg = AppColors.green; badgeBdr = AppColors.green;
      badgeIcon = Icons.check_circle_rounded; badgeLabel = 'Completed 🎉';
    } else if (wasJustStarted) {
      badgeBg = const Color(0xFFFFF8EC); badgeFg = AppColors.gold; badgeBdr = AppColors.gold;
      badgeIcon = Icons.my_location_rounded; badgeLabel = 'In Progress';
    } else {
      badgeBg = trip.statusBg; badgeFg = trip.statusFg; badgeBdr = trip.statusBorder;
      badgeIcon = trip.statusIcon; badgeLabel = trip.statusLabel;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trip.date.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.text3)),
            const SizedBox(height: 3),
            Text(_displayName(trip), style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text1, height: 1.15)),
          ])),
          GestureDetector(
            onTap: () => _showKebabMenu(trip),
            child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.md)), child: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.text2)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: badgeBdr.withOpacity(0.20))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(badgeIcon, size: 13, color: badgeFg), const SizedBox(width: 4), Text(badgeLabel, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: badgeFg))]),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.full)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(trip.transportIcon, size: 13, color: AppColors.text2), const SizedBox(width: 4), Text(trip.transportLabel, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2))]),
          ),
        ]),
        const SizedBox(height: 10),
        _buildStopPills(trip),
        const SizedBox(height: 10),
        _buildStatsRow(trip),
      ]),
    );
  }

  Widget _buildStopPills(_Trip trip) {
    final children = <Widget>[];
    for (int i = 0; i < trip.stops.length; i++) {
      final stop = trip.stops[i];
      children.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(stop.icon, size: 12, color: AppColors.text3), const SizedBox(width: 4), Text(stop.label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2))]),
      ));
      children.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('→', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.text3))));
    }
    children.add(Text(trip.moreLabel, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.oceanDeep)));
    return SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const NeverScrollableScrollPhysics(), child: Row(children: children));
  }

  Widget _buildStatsRow(_Trip trip) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderLight))),
      child: IntrinsicHeight(child: Row(children: [
        for (int i = 0; i < trip.stats.length; i++) ...[
          Expanded(child: Row(children: [
            Icon(trip.stats[i].icon, size: 15, color: trip.stats[i].color),
            const SizedBox(width: 5),
            Text(_statValueFor(trip, i), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text2)),
          ])),
          if (i < trip.stats.length - 1)
            Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), color: AppColors.borderLight),
        ],
      ])),
    );
  }

  Widget _buildCardCta(_Trip trip, TripStatus effective, bool wasJustCompleted, bool wasJustStarted) {
    final String ctaLabel;
    final IconData ctaIcon;
    final List<Color> ctaGradient;

    if (wasJustCompleted) {
      ctaLabel = 'Re-run Trip'; ctaIcon = Icons.replay_rounded;
      ctaGradient = [AppColors.green, const Color(0xFF22C55E)];
    } else if (wasJustStarted) {
      ctaLabel = 'Continue Trip'; ctaIcon = Icons.navigation_rounded;
      ctaGradient = [AppColors.gold, const Color(0xFFE8A840)];
    } else {
      ctaLabel = trip.ctaLabel; ctaIcon = trip.ctaIcon; ctaGradient = trip.ctaGradient;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        Expanded(child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            gradient: ctaGradient.isNotEmpty ? LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: ctaGradient) : null,
            color: ctaGradient.isEmpty ? AppColors.text1 : null,
            boxShadow: ctaGradient.isNotEmpty ? [BoxShadow(color: ctaGradient.first.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Material(color: Colors.transparent, child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: () => _onCtaTap(trip),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(ctaIcon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(ctaLabel, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          )),
        )),
        const SizedBox(width: 8),
        _cardIconBtn(icon: Icons.share_rounded, bg: AppColors.surface, iconColor: AppColors.text2, border: AppColors.border, onTap: () => _showShareSheet(trip)),
        const SizedBox(width: 8),
        _cardIconBtn(icon: Icons.delete_outline_rounded, bg: AppColors.coralTint, iconColor: AppColors.coral, border: AppColors.coral.withOpacity(0.25), onTap: () => _showDeleteSheet(trip)),
      ]),
    );
  }

  Widget _cardIconBtn({required IconData icon, required Color bg, required Color iconColor, required Color border, VoidCallback? onTap}) =>
    GestureDetector(onTap: onTap, child: Container(width: 40, height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg, border: Border.all(color: border, width: 1.5)),
      child: Icon(icon, size: 17, color: iconColor)));

  Widget _buildBottomNav() {
    final navItems = [
      (Icons.home_rounded, 'Home', false),
      (Icons.explore_rounded, 'Explore', false),
      (Icons.map_rounded, 'Trips', true),
      (Icons.person_rounded, 'Profile', false),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, stops: [0.70, 1.0], colors: [AppColors.surface, Colors.transparent])),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: AppColors.borderLight), boxShadow: shadowLg),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end, children: [
          _navItem(navItems[0], onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false)),
          _navItem(navItems[1], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreScreen()))),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Transform.translate(offset: const Offset(0, -22), child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GenerateItineraryScreen())),
                child: AnimatedBuilder(animation: _sheenAnim, builder: (_, __) => Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.oceanDeep, AppColors.oceanMid]), boxShadow: shadowOcean),
                  child: ClipOval(child: Stack(children: [
                    Positioned.fill(child: CustomPaint(painter: SheenPainter(position: _sheenAnim.value))),
                    const Center(child: Icon(Icons.add_rounded, size: 24, color: Colors.white)),
                  ])),
                )),
              ),
              const SizedBox(height: 3),
              Text('PLAN', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.oceanDeep)),
            ])),
          ]),
          _navItem(navItems[2], onTap: () {}),
          _navItem(navItems[3], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
        ]),
      ),
    );
  }

  Widget _navItem((IconData, String, bool) item, {required VoidCallback onTap}) {
    final (icon, label, isActive) = item;
    return GestureDetector(onTap: onTap, child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: isActive ? AppColors.oceanTint : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 22, color: isActive ? AppColors.oceanDeep : AppColors.text3),
        const SizedBox(height: 3),
        Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: isActive ? AppColors.oceanDeep : AppColors.text3)),
      ]),
    ));
  }
}

// ══════════════════════════════════════════════════════════════
// BOTTOM SHEETS
// ══════════════════════════════════════════════════════════════
class _KebabSheet extends StatelessWidget {
  final String tripName;
  final VoidCallback onRename, onDuplicate, onArchive, onDelete;
  const _KebabSheet({required this.tripName, required this.onRename, required this.onDuplicate, required this.onArchive, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        Text(tripName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        const Divider(color: AppColors.borderLight, height: 1),
        const SizedBox(height: 8),
        _kebabItem(icon: Icons.drive_file_rename_outline_rounded, label: 'Rename',    color: AppColors.text1,     onTap: onRename),
        _kebabItem(icon: Icons.content_copy_rounded,              label: 'Duplicate', color: AppColors.oceanDeep, onTap: onDuplicate),
        _kebabItem(icon: Icons.archive_outlined,                  label: 'Archive',   color: AppColors.text2,     onTap: onArchive),
        const Divider(color: AppColors.borderLight, height: 16),
        _kebabItem(icon: Icons.delete_outline_rounded,            label: 'Delete',    color: AppColors.coral,     onTap: onDelete),
      ]),
    );
  }

  Widget _kebabItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.md)), child: Icon(icon, size: 20, color: color)),
        const SizedBox(width: 14),
        Text(label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
        const Spacer(),
        Icon(Icons.chevron_right_rounded, size: 18, color: color.withOpacity(0.35)),
      ]))));
  }
}

class _ShareSheet extends StatelessWidget {
  final String tripName;
  const _ShareSheet({required this.tripName});

  @override
  Widget build(BuildContext context) {
    final options = [
      (Icons.link_rounded,          'Copy Link',   AppColors.oceanDeep),
      (Icons.chat_rounded,          'WhatsApp',    AppColors.green),
      (Icons.camera_alt_rounded,    'Instagram',   AppColors.purple),
      (Icons.picture_as_pdf_rounded,'Save as PDF', AppColors.coral),
    ];
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Row(children: [const Icon(Icons.share_rounded, size: 20, color: AppColors.text1), const SizedBox(width: 10), Text('Share Itinerary', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text1))]),
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerLeft, child: Text(tripName, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.text3), maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: options.map((opt) {
          final (icon, label, color) = opt;
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Shared via $label', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                backgroundColor: color, behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12), duration: const Duration(seconds: 2),
              ));
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: color.withOpacity(0.10), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.20), width: 1.5)), child: Icon(icon, size: 22, color: color)),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text2)),
            ]),
          );
        }).toList()),
      ]),
    );
  }
}

class _DeleteSheet extends StatelessWidget {
  final String tripName;
  final VoidCallback onConfirm, onCancel;
  const _DeleteSheet({required this.tripName, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.coralTint, shape: BoxShape.circle, border: Border.all(color: AppColors.coral.withOpacity(0.30), width: 2)), child: const Icon(Icons.delete_outline_rounded, size: 30, color: AppColors.coral)),
        const SizedBox(height: 16),
        Text('Delete Trip?', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text1)),
        const SizedBox(height: 8),
        Text('"$tripName" will be permanently\nremoved from your trips.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.text2, height: 1.5)),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.delete_outline_rounded, size: 18), const SizedBox(width: 8), Text('Yes, Delete', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700))]),
        )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 52, child: OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.text1, side: const BorderSide(color: AppColors.border, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
          child: Text('Keep It', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text1)),
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════
class DashedStripePainter extends CustomPainter {
  final Color color;
  const DashedStripePainter({required this.color});
  static const double _dashW = 8.0;
  static const double _gapW  = 6.0;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    double x = 0;
    while (x < size.width) {
      canvas.drawRect(Rect.fromLTWH(x, 0, _dashW.clamp(0, size.width - x), size.height), paint);
      x += _dashW + _gapW;
    }
  }
  @override
  bool shouldRepaint(covariant DashedStripePainter old) => old.color != color;
}

class SheenPainter extends CustomPainter {
  final double position;
  const SheenPainter({required this.position});
  @override
  void paint(Canvas canvas, Size size) {
    final stripeW = size.width * 0.30;
    final left    = position * size.width;
    final paint   = Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, Colors.white.withOpacity(0.12), Colors.transparent],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(left, 0, stripeW, size.height), paint);
  }
  @override
  bool shouldRepaint(SheenPainter old) => old.position != position;
}