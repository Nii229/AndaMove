// ============================================================
// AndaMove — Itinerary Result Screen
// File: lib/screens/screen8_itineraryResult.dart
//
// WHAT CHANGED (multi-day scheduling upgrade)
//   The timeline is no longer a naive "start + Σ(stay+15min)" clock.
//   It now runs ItineraryScheduler over the optimised POI list and
//   renders a realistic, DAY-SPLIT plan:
//     • Fix #1 — respects each POI's real opening hours
//     • Fix #2 — auto-inserts Lunch (~12:00) + Dinner (~19:00)
//     • Fix #3 — splits into Day 1, Day 2, … on overflow
//     • Fix #4 — each day ends by a sane cutoff; nightlife may run late
//
//   • [NEW] travelMinutes constructor param — real Distance Matrix
//           minutes from screen7, fed straight to the scheduler.
//   • [NEW] _schedule field built in initState + on reorder.
//   • [NEW] day headers + meal-break cards in the timeline.
//   • Header badges (duration / stops / days) now read from the
//     schedule, so they're truthful.
//   • All original visuals (banner, stars, sheen, dots, connectors,
//     stop cards, 3 CTA modes, reorder) are preserved.
//
//   The constructor is otherwise UNCHANGED, so screen7 / screen11 /
//   screen10 keep calling it the same way (travelMinutes is optional).
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'screen7_generateItinerary.dart' show GenerateItineraryScreen, PoiItem;
import 'screen9_mapView.dart';
import 'screen10_navigation.dart';
import 'screen11_trips.dart';
import '../app_store.dart';
import '../services/itinerary_scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

// ══════════════════════════════════════════════════════════════
// VIEW MODE ENUM
// ══════════════════════════════════════════════════════════════
enum ItineraryViewMode {
  /// Normal: user just generated an itinerary from screen7.
  generated,

  /// Viewing an in-progress trip from screen11 → bottom = End Trip.
  inProgress,

  /// Viewing an upcoming trip from screen11 → bottom = Start Trip.
  upcoming,
}

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
List<BoxShadow> get shadowGold => [
  BoxShadow(
    color: AppColors.gold.withOpacity(0.25),
    blurRadius: 18,
    offset: const Offset(0, 6),
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
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class ItineraryResultScreen extends StatefulWidget {
  final String transport;
  final List<String> categories;
  final List<PoiItem> selectedPois;
  final DateTime date;
  final TimeOfDay time;
  final String? tripId;

  /// Determines which bottom CTA layout to show.
  final ItineraryViewMode viewMode;

  /// [NEW] Real travel minutes into each stop (parallel to
  /// selectedPois). Optional — fallbacks (no-coords / API failure)
  /// and screen11 re-runs omit it, and the scheduler then uses a
  /// 15-min buffer. travelMinutes[i] = minutes into selectedPois[i];
  /// index 0 = travel from the user's start point.
  final List<int>? travelMinutes;

  const ItineraryResultScreen({
    super.key,
    required this.transport,
    required this.categories,
    required this.selectedPois,
    required this.date,
    required this.time,
    this.tripId,
    this.viewMode = ItineraryViewMode.generated,
    this.travelMinutes,
  });

  @override
  State<ItineraryResultScreen> createState() => _ItineraryResultScreenState();
}

class _ItineraryResultScreenState extends State<ItineraryResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheenCtrl;
  late final Animation<double> _sheenAnim;

  int _activeStopIndex = 0;
  late final TextEditingController _nameCtrl;
  bool _isEditingName = false;
  late List<PoiItem> _orderedPois;
  bool _isReordering = false;
  bool _locationPermissionGranted = false;
  String? _savedTripId;

  // [NEW] The computed multi-day schedule.
  late ItinerarySchedule _schedule;

  @override
  void initState() {
    super.initState();
    _orderedPois = List.from(widget.selectedPois);
    _rebuildSchedule(); // [NEW]

    // restore active stop for in-progress trips
    _savedTripId = widget.tripId;
    if (widget.tripId != null && widget.viewMode == ItineraryViewMode.inProgress) {
      _activeStopIndex = AppStore.getTripProgress(widget.tripId!);
      if (_activeStopIndex >= _orderedPois.length) {
        _activeStopIndex = _orderedPois.length - 1;
      }
    }

    _sheenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _sheenAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _sheenCtrl, curve: Curves.easeInOut),
    );

    final defaultName = widget.selectedPois.length == 1
        ? widget.selectedPois.first.name
        : 'Phuket ${widget.categories.take(2).join(" & ")} Day';
    _nameCtrl = TextEditingController(text: defaultName);

    _ensureLocationPermission();
  }

  // ── [NEW] Build the schedule from the current POI order ──────
  void _rebuildSchedule() {
    final stops = <ScheduleStop>[];
    for (int i = 0; i < _orderedPois.length; i++) {
      final p = _orderedPois[i];
      final travel = (widget.travelMinutes != null &&
              i < widget.travelMinutes!.length)
          ? widget.travelMinutes![i]
          : 0; // 0 → scheduler applies its fallback buffer
      stops.add(ScheduleStop(
        name: p.name,
        category: p.category,
        imagePath: p.imagePath,
        rating: p.rating,
        latitude: p.latitude,
        longitude: p.longitude,
        stayMinutes: p.stayMinutes,
        travelMinutesToHere: travel,
        openHours: p.openHours,
        travelLabel: p.distance,
      ));
    }
    _schedule = ItineraryScheduler.build(
      stops: stops,
      startDate: widget.date,
      startHour: widget.time.hour,
      startMinute: widget.time.minute,
    );
  }

  Future<void> _ensureLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (mounted && granted) {
        setState(() => _locationPermissionGranted = true);
      }
    } catch (e) {
      print('Location permission error: $e');
    }
  }

  @override
  void dispose() {
    _sheenCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Only save a new trip when in "generated" mode ────────────
  void _onBackPressed() {
    if (widget.viewMode == ItineraryViewMode.generated) {
      _saveAndGoToTrips();
    } else {
      Navigator.pop(context);
    }
  }

  // ── Shared save logic (no navigation) ────────────────────────
  void _persistTrip(String tripId, String tripName) {
    if (!AppStore.isTripFollowed(tripId)) {
      AppStore.followTrip(
        StoredTrip(
          id: tripId,
          name: tripName,
          totalDuration: _totalDuration,
          stops: _orderedPois
              .map((p) => StoredTripStop(
                    name: p.name,
                    type: p.category,
                    duration: '${p.stayMinutes} min',
                    distance: p.distance,
                  ))
              .toList(),
          sourceVlogId: tripId,
          tripDate: widget.date,
          transport: widget.transport,
          startHour: widget.time.hour,
          startMinute: widget.time.minute,
        ),
      );
    }

    // Fire-and-forget Firestore write (non-blocking)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final stops = _orderedPois.map((p) => {
          'name': p.name,
          'category': p.category,
          'distance': p.distance,
          'stayMinutes': p.stayMinutes,
          'latitude': p.latitude,
          'longitude': p.longitude,
          'imagePath': p.imagePath,
          'openHours': p.openHours, // [NEW] persist hours for re-open
        }).toList();

        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('trips')
            .doc(tripId)
            .set({
          'name': tripName,
          'transport': widget.transport,
          'totalDuration': _totalDuration,
          'stops': stops,
          'date': Timestamp.fromDate(widget.date),
          'startHour': widget.time.hour,
          'startMinute': widget.time.minute,
          'dayCount': _schedule.totalDays, // [NEW]
          'status': 'upcoming',
          'createdAt': FieldValue.serverTimestamp(),
        });

        FirebaseFirestore.instance
            .collection('counters')
            .doc('stats')
            .set(
              {'tripCount': FieldValue.increment(1)},
              SetOptions(merge: true),
            );
      }
    } catch (_) {}
  }

  Future<String> _ensureTripSaved() async {
    if (_savedTripId != null) return _savedTripId!;
    final tripId = 'trip_${DateTime.now().millisecondsSinceEpoch}';
    final tripName = _nameCtrl.text.trim().isEmpty
        ? 'My Phuket Itinerary'
        : _nameCtrl.text.trim();
    _savedTripId = tripId;
    _persistTrip(tripId, tripName);
    return tripId;
  }

  Future<void> _saveAndGoToTrips() async {
    await _ensureTripSaved();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const TripsScreen()),
        (route) => route.isFirst,
      );
    }
  }

  void _onStartTrip() {
    if (widget.tripId != null) {
      AppStore.startTrip(widget.tripId!);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(tripId: widget.tripId, selectedPois: _orderedPois),
      ),
    );
  }

  void _openRouteMap() async {
    final pois = _orderedPois;
    final hasCoords = pois.every((p) => p.latitude != 0.0 && p.longitude != 0.0);

    if (!hasCoords) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapViewScreen()));
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
              Text('Loading route map...', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
            ],
          ),
        ),
      ),
    );

    try {
      final origin = '${pois.first.latitude},${pois.first.longitude}';
      final destination = '${pois.last.latitude},${pois.last.longitude}';

      String travelMode;
      switch (widget.transport.toLowerCase()) {
        case 'walk': travelMode = 'walking'; break;
        default: travelMode = 'driving'; break;
      }

      String waypointsParam = '';
      if (pois.length > 2) {
        final waypoints = pois.sublist(1, pois.length - 1)
            .map((p) => '${p.latitude},${p.longitude}')
            .join('|');
        waypointsParam = '&waypoints=$waypoints';
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$origin'
        '&destination=$destination'
        '$waypointsParam'
        '&mode=$travelMode'
        '&key=${_getApiKey()}',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      List<LatLng> routePoints = [];
      if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
        final encodedPolyline = data['routes'][0]['overview_polyline']['points'] as String;
        routePoints = _decodePolyline(encodedPolyline);
      }

      if (mounted) Navigator.pop(context);

      final markers = <Marker>{};
      for (int i = 0; i < pois.length; i++) {
        final poi = pois[i];
        markers.add(Marker(
          markerId: MarkerId('stop_$i'),
          position: LatLng(poi.latitude, poi.longitude),
          infoWindow: InfoWindow(
            title: 'Stop ${i + 1}: ${poi.name}',
            snippet: poi.category,
          ),
        ));
      }

      double minLat = pois.first.latitude, maxLat = pois.first.latitude;
      double minLng = pois.first.longitude, maxLng = pois.first.longitude;
      for (final p in pois) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      for (final p in routePoints) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      final bounds = LatLngBounds(
        southwest: LatLng(minLat - 0.005, minLng - 0.005),
        northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.surface,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.text1),
                ),
                title: Text('Route Map',
                  style: GoogleFonts.outfit(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text1)),
                centerTitle: false,
              ),
              body: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
                  zoom: 12,
                ),
                markers: markers,
                polylines: {
                  if (routePoints.isNotEmpty)
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: routePoints,
                      color: AppColors.oceanDeep,
                      width: 4,
                    ),
                },
                onMapCreated: (controller) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                  });
                },
                myLocationEnabled: _locationPermissionGranted,
                myLocationButtonEnabled: _locationPermissionGranted,
                compassEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MapViewScreen()));
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  String _getApiKey() => 'AIzaSyB0CTGhgMeEQczyD3N1aM6ynx7hY3HO6kw';

  // ── Edit stops → push new screen7 with POIs, date, time, transport ──
  void _onEditStops() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenerateItineraryScreen(
          preSelectedPoiNames: _orderedPois.map((p) => p.name).toList(),
          preSelectedDate: widget.date,
          preSelectedTime: widget.time,
          preSelectedTransport: widget.transport,
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  String _formatDate(DateTime d) {
    const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final hour   = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // [NEW] Format an absolute minutes-from-midnight value. Values
  // ≥ 1440 (post-midnight, e.g. nightlife) wrap and show the time.
  String _formatMinutes(int minutes) {
    final m = ((minutes % (24 * 60)) + 24 * 60) % (24 * 60);
    final h24 = m ~/ 60;
    final mm = m % 60;
    final period = h24 < 12 ? 'AM' : 'PM';
    var h12 = h24 % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:${mm.toString().padLeft(2, '0')} $period';
  }

  IconData _transportIcon(String transport) {
    switch (transport) {
      case 'Scooter': return Icons.moped_rounded;
      case 'Tuk-tuk': return Icons.electric_rickshaw_rounded;
      case 'Car':     return Icons.directions_car_rounded;
      case 'Walk':    return Icons.directions_walk_rounded;
      default:        return Icons.directions_car_rounded;
    }
  }

  // [CHANGED] Total duration now spans the whole schedule (all days):
  // from Day 1's first start to the last day's last end, expressed as
  // active touring time. We sum each day's (lastEnd - firstStart).
  String get _totalDuration {
    int totalMins = 0;
    for (final day in _schedule.days) {
      if (day.entries.isEmpty) continue;
      totalMins += (day.lastEnd - day.firstStart);
    }
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  // [NEW] Map a global POI index (0-based across the whole trip, in
  // schedule order) for active-stop highlighting. We walk days/entries
  // counting only POI entries.
  bool _isPoiActive(ScheduleStop stop, int globalPoiIndex) =>
      globalPoiIndex == _activeStopIndex;

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: _buildBottomCta(context),
      body: Column(
        children: [
          _buildHeaderBanner(),
          _buildStatsRow(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(),
                  _buildTimeline(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // DARK HEADER BANNER
  // ══════════════════════════════════════════════════════════
  Widget _buildHeaderBanner() {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.2, -1.0),
            end: Alignment(0.2, 1.0),
            stops: [0.0, 0.55, 1.0],
            colors: [Color(0xFF061018), Color(0xFF0A3D5C), Color(0xFF0A7FAB)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.gold.withOpacity(0.15), Colors.transparent],
                    stops: const [0.0, 0.65],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 36, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (i) {
                  final isSmall = i.isOdd;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    width: isSmall ? 2.0 : 3.0,
                    height: isSmall ? 2.0 : 3.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.goldLight.withOpacity(isSmall ? 0.30 : 0.60),
                    ),
                  );
                }),
              ),
            ),
            // Wave cutout
            Positioned(
              bottom: -16,
              left: -MediaQuery.of(context).size.width * 0.05,
              right: -MediaQuery.of(context).size.width * 0.05,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.elliptical(9999, 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 15, 20, 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Back + mode chip ───────────────────────────
                  Row(
                    children: [
                      _frostedBtn(Icons.arrow_back_rounded, onTap: _onBackPressed),
                      if (widget.viewMode == ItineraryViewMode.upcoming) ...[
                        const SizedBox(width: 10),
                        _headerChip(
                          icon: Icons.visibility_rounded,
                          label: 'Preview',
                          color: AppColors.oceanMid,
                        ),
                      ],
                      if (widget.viewMode == ItineraryViewMode.inProgress) ...[
                        const SizedBox(width: 10),
                        _headerChip(
                          icon: Icons.my_location_rounded,
                          label: 'Active Trip',
                          color: AppColors.goldLight,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    // [CHANGED] reflect multi-day in the eyebrow text.
                    _schedule.totalDays > 1
                        ? 'AI-Generated · ${_schedule.totalDays}-Day Plan · ${_formatDate(widget.date)}'
                        : 'AI-Generated Route · ${_formatDate(widget.date)}',
                    style: GoogleFonts.outfit(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 1.4, color: Colors.white.withOpacity(0.50),
                    ),
                  ),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: () => setState(() => _isEditingName = true),
                    child: _isEditingName
                        ? TextField(
                            controller: _nameCtrl,
                            autofocus: true,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20, fontWeight: FontWeight.w700,
                              color: Colors.white, height: 1.15,
                            ),
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.40),
                                ),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.goldLight),
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() => _isEditingName = false),
                                child: const Icon(Icons.check_rounded,
                                    color: AppColors.goldLight, size: 20),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => setState(() => _isEditingName = false),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _nameCtrl.text.isEmpty
                                      ? 'My Phuket Itinerary'
                                      : _nameCtrl.text,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22, fontWeight: FontWeight.w700,
                                    color: Colors.white, height: 1.15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.edit_rounded, size: 16,
                                  color: Colors.white.withOpacity(0.50)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _hbBadge(_transportIcon(widget.transport), widget.transport,
                          AppColors.oceanMid),
                      _hbBadge(Icons.schedule_rounded, _totalDuration, AppColors.goldLight),
                      _hbBadge(Icons.location_on_rounded,
                          '${_schedule.totalStops} stops', AppColors.greenLight),
                      // [NEW] days badge when multi-day
                      if (_schedule.totalDays > 1)
                        _hbBadge(Icons.calendar_month_rounded,
                            '${_schedule.totalDays} days', AppColors.coral),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _frostedBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _headerChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
            style: GoogleFonts.outfit(
              fontSize: 11, fontWeight: FontWeight.w700, color: color,
            )),
        ],
      ),
    );
  }

  Widget _hbBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text,
            style: GoogleFonts.outfit(
              fontSize: 11, fontWeight: FontWeight.w700, color: color,
            )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════════════════════════
  Widget _buildStatsRow() {
    final stats = [
      (Icons.location_on_rounded, AppColors.oceanTint, AppColors.oceanDeep,
          '${_schedule.totalStops}', 'Stops'),
      (Icons.schedule_rounded, AppColors.goldTint, AppColors.gold, _totalDuration, 'Total'),
      // [CHANGED] third cell: Days when multi-day, else Start time.
      _schedule.totalDays > 1
          ? (Icons.calendar_month_rounded, AppColors.coralTint, AppColors.coral,
              '${_schedule.totalDays}', 'Days')
          : (Icons.flag_rounded, AppColors.greenTint, AppColors.green,
              _formatTime(widget.time), 'Start'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final i = e.key;
          final (icon, tint, iconColor, val, lbl) = e.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < stats.length - 1 ? 10 : 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: shadowSm,
              ),
              child: Column(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: tint, borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(height: 5),
                  Text(val,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text1,
                    )),
                  Text(lbl.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 9, fontWeight: FontWeight.w600,
                      letterSpacing: 0.8, color: AppColors.text3,
                    )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Text('Your Route',
            style: GoogleFonts.outfit(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1,
            )),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _isReordering = !_isReordering),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _isReordering ? AppColors.oceanDeep : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: _isReordering ? AppColors.oceanDeep : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isReordering ? Icons.check_rounded : Icons.swap_vert_rounded,
                    size: 14,
                    color: _isReordering ? Colors.white : AppColors.oceanDeep,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isReordering ? 'Done' : 'Reorder',
                    style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: _isReordering ? Colors.white : AppColors.oceanDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onEditStops,
            child: Text('Edit stops',
              style: GoogleFonts.outfit(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text3,
              )),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TIMELINE  [REWRITTEN] — now day-grouped with meal blocks
  // ══════════════════════════════════════════════════════════
  Widget _buildTimeline() {
    if (_isReordering) return _buildReorderList();

    final items = <Widget>[];
    int globalPoiIndex = 0; // counts POIs across all days for active state

    for (final day in _schedule.days) {
      // Day header (always shown; gives even a 1-day plan a clean label)
      items.add(_buildDayHeader(day));
      items.add(const SizedBox(height: 4));

      final entries = day.entries;
      for (int e = 0; e < entries.length; e++) {
        final entry = entries[e];
        final isLastInDay = e == entries.length - 1;

        if (entry.isMeal) {
          items.add(_buildMealRow(entry, hasConnector: !isLastInDay));
        } else {
          final stop = entry.stop!;
          final isFirstOverall = globalPoiIndex == 0;
          final isLastOverall =
              globalPoiIndex == _schedule.totalStops - 1;
          final isActive = _isPoiActive(stop, globalPoiIndex);
          final isDone = globalPoiIndex < _activeStopIndex;

          items.add(_buildStopRow(
            entry: entry,
            index: globalPoiIndex,
            isFirst: isFirstOverall,
            isLast: isLastOverall,
            isActive: isActive,
            isDone: isDone,
          ));
          globalPoiIndex++;
        }

        // Connector between entries in the same day
        if (!isLastInDay) {
          final next = entries[e + 1];
          final travel = next.travelMinutes;
          final label = travel > 0
              ? '${widget.transport} · ${travel} min'
              : '${widget.transport}';
          items.add(_buildConnector(
            isDone: entry.isPoi && (globalPoiIndex - 1) < _activeStopIndex,
            travelTime: label,
          ));
        }
      }

      items.add(const SizedBox(height: 18));
    }

    if (_schedule.unplaced.isNotEmpty) {
      items.add(_buildUnplacedNote());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: items),
    );
  }

  // [NEW] Day section header.
  Widget _buildDayHeader(ItineraryDay day) {
    final start = day.firstStart;
    final end = day.lastEnd;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0A3D5C), AppColors.oceanDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text('${day.dayNumber}',
              style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DAY ${day.dayNumber}',
                style: GoogleFonts.outfit(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: Colors.white.withOpacity(0.60))),
              Text(_formatDate(day.date),
                style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '${_formatMinutes(start)} – ${_formatMinutes(end)}',
              style: GoogleFonts.outfit(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.90)),
            ),
          ),
        ],
      ),
    );
  }

  // [NEW] Meal break row (lunch / dinner).
  Widget _buildMealRow(ItineraryEntry meal, {required bool hasConnector}) {
    final isLunch = (meal.mealLabel ?? '').toLowerCase() == 'lunch';
    final icon = isLunch ? Icons.lunch_dining_rounded : Icons.dinner_dining_rounded;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 36,
          child: Center(
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coralTint,
                border: Border.all(color: AppColors.coral.withOpacity(0.35), width: 1.5),
              ),
              child: Icon(icon, size: 15, color: AppColors.coral),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.coralTint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.coral.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                Text(meal.mealLabel ?? 'Meal',
                  style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.coral)),
                const Spacer(),
                Text(
                  '${_formatMinutes(meal.startMinutes)} – ${_formatMinutes(meal.endMinutes)}',
                  style: GoogleFonts.outfit(
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.coral)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // [NEW] Note for any POI the scheduler couldn't fit.
  Widget _buildUnplacedNote() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gold.withOpacity(0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Couldn't fit on schedule",
                  style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold)),
                const SizedBox(height: 2),
                Text(
                  _schedule.unplaced.map((s) => s.name).join(', ') +
                      ' — opening hours leave no room. Try adding a day or trimming stays.',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.text2, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reorder list — schedule still computed; shows day labels ──
  Widget _buildReorderList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.oceanTint,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.oceanDeep.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.oceanDeep),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag to reorder. The day-by-day plan and meal breaks '
                    'rebuild automatically when you tap Done.',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.oceanDeep)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orderedPois.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _orderedPois.removeAt(oldIndex);
                _orderedPois.insert(newIndex, item);
                _rebuildSchedule(); // [NEW] re-split after reorder
              });
            },
            proxyDecorator: (child, index, animation) => Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: Colors.transparent,
              child: child,
            ),
            itemBuilder: (_, i) {
              final poi = _orderedPois[i];
              return Container(
                key: ValueKey(poi.name),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: shadowSm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? AppColors.green
                            : i == _orderedPois.length - 1
                                ? AppColors.gold
                                : AppColors.oceanDeep,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white,
                          )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        width: 40, height: 40,
                        child: Image.asset(poi.imagePath, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: poi.thumbGradient.length >= 2
                                    ? poi.thumbGradient
                                    : [poi.thumbGradient.first, poi.thumbGradient.first],
                              ),
                            ),
                            child: Icon(poi.thumbIcon, size: 18,
                              color: Colors.white.withOpacity(0.8)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(poi.name,
                            style: GoogleFonts.outfit(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text1,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${poi.category} · Stay: ${poi.stayMinutes} min',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.text2)),
                        ],
                      ),
                    ),
                    const Icon(Icons.drag_handle_rounded, color: AppColors.text3, size: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStopRow({
    required ItineraryEntry entry,
    required int index,
    required bool isFirst,
    required bool isLast,
    required bool isActive,
    required bool isDone,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: _buildDot(
            isFirst: isFirst, isLast: isLast, isActive: isActive, isDone: isDone,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildStopCard(
            entry: entry, index: index,
            isActive: isActive, isDone: isDone, isLast: isLast,
          ),
        ),
      ],
    );
  }

  Widget _buildDot({
    required bool isFirst, required bool isLast,
    required bool isActive, required bool isDone,
  }) {
    Color bg; IconData icon; Color iconColor; List<BoxShadow> glow;

    if (isDone) {
      bg = AppColors.oceanDeep; icon = Icons.check_circle_rounded;
      iconColor = Colors.white;
      glow = [BoxShadow(color: AppColors.oceanDeep.withOpacity(0.15), spreadRadius: 4)];
    } else if (isActive) {
      bg = AppColors.gold; icon = Icons.my_location_rounded;
      iconColor = Colors.white;
      glow = [BoxShadow(color: AppColors.gold.withOpacity(0.20), spreadRadius: 4)];
    } else if (isFirst) {
      bg = AppColors.green; icon = Icons.flag_rounded;
      iconColor = Colors.white;
      glow = [BoxShadow(color: AppColors.green.withOpacity(0.15), spreadRadius: 4)];
    } else if (isLast) {
      bg = AppColors.gold; icon = Icons.sports_score_rounded;
      iconColor = Colors.white; glow = [];
    } else {
      bg = AppColors.surface; icon = Icons.radio_button_unchecked_rounded;
      iconColor = AppColors.text3; glow = [];
    }

    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: bg,
        border: (!isDone && !isActive && !isFirst && !isLast)
            ? Border.all(color: AppColors.border, width: 2) : null,
        boxShadow: glow,
      ),
      child: Icon(icon, size: 17, color: iconColor),
    );
  }

  Widget _buildStopCard({
    required ItineraryEntry entry,
    required int index,
    required bool isActive,
    required bool isDone,
    required bool isLast,
  }) {
    final poi = entry.stop!;
    final tags = <_Tag>[
      _Tag(poi.category,
          isActive ? AppColors.goldTint : AppColors.oceanTint,
          isActive ? AppColors.gold : AppColors.oceanDeep),
      if (entry.wasAdjustedForHours)
        const _Tag('⏰ Opens later', AppColors.goldTint, AppColors.gold),
      if (isDone)   const _Tag('Completed ✓', AppColors.greenTint, AppColors.green),
      if (isActive) const _Tag('📍 You are here', AppColors.goldTint, AppColors.gold),
      if (!isDone && !isActive && isLast)
                    const _Tag('Final Stop', AppColors.surface2, AppColors.text2),
      if (!isDone && !isActive && !isLast)
                    const _Tag('Upcoming', AppColors.surface2, AppColors.text2),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isActive ? AppColors.gold : AppColors.borderLight, width: 1.5,
        ),
        boxShadow: isActive ? shadowGold : shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 56, height: 56,
                  child: Image.asset(
                    poi.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [AppColors.oceanDeep, AppColors.oceanMid],
                        ),
                      ),
                      child: const Icon(Icons.place_rounded, size: 26,
                          color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          letterSpacing: 1.0, color: AppColors.text3,
                        ),
                        children: [
                          // [CHANGED] time now from the schedule entry
                          TextSpan(text: 'Stop ${index + 1} · '
                              '${_formatMinutes(entry.startMinutes)}'),
                          if (isActive) ...[
                            const TextSpan(text: ' · '),
                            TextSpan(
                              text: 'NOW',
                              style: GoogleFonts.outfit(
                                fontSize: 10, fontWeight: FontWeight.w800,
                                letterSpacing: 1.0, color: AppColors.gold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(poi.name,
                      style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text1,
                      )),
                    const SizedBox(height: 2),
                    // [CHANGED] show open–close window + arrival→leave
                    Text(
                      '${_formatMinutes(entry.startMinutes)} – ${_formatMinutes(entry.endMinutes)}',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.text2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.hourglass_top_rounded, size: 12, color: AppColors.text3),
            const SizedBox(width: 4),
            Text('Stay: ${poi.stayMinutes} min',
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.text2)),
            const SizedBox(width: 12),
            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.text3),
            const SizedBox(width: 4),
            // [NEW] surface the real opening hours on the card
            Flexible(
              child: Text(poi.openHours,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.text2)),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tag.bg, borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(tag.label,
                style: GoogleFonts.outfit(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 0.5, color: tag.fg,
                )),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector({required bool isDone, String travelTime = '~15 min'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            child: Center(
              child: Container(
                width: 2, height: 28,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.oceanMid : AppColors.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDone ? AppColors.oceanTint : AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: isDone
                    ? AppColors.oceanDeep.withOpacity(0.15)
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_transportIcon(widget.transport), size: 14,
                    color: isDone ? AppColors.oceanDeep : AppColors.text3),
                const SizedBox(width: 5),
                Text(travelTime,
                  style: GoogleFonts.outfit(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDone ? AppColors.oceanDeep : AppColors.text2,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BOTTOM CTA — mode-aware (unchanged behaviour)
  // ══════════════════════════════════════════════════════════
  Widget _buildBottomCta(BuildContext context) {
    switch (widget.viewMode) {
      case ItineraryViewMode.inProgress:
        return _buildGeneratedBottomCta(context);
      case ItineraryViewMode.upcoming:
        return _buildStartTripBottomCta(context);
      case ItineraryViewMode.generated:
      default:
        return _buildGeneratedBottomCta(context);
    }
  }

  Widget _buildStartTripBottomCta(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: AnimatedBuilder(
        animation: _sheenAnim,
        builder: (_, child) => GestureDetector(
          onTap: _onStartTrip,
          child: Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.oceanDeep, AppColors.oceanMid],
              ),
              boxShadow: shadowOcean,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Stack(
                children: [
                  child!,
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SheenPainter(position: _sheenAnim.value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text('Start Trip',
                style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: 0.3,
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratedBottomCta(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => _openRouteMap(),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: shadowSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_rounded, size: 17, color: AppColors.text2),
                    const SizedBox(width: 6),
                    Text('Map View',
                      style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text1,
                      )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: _sheenAnim,
              builder: (_, child) => GestureDetector(
                onTap: () async {
                  final nav = Navigator.of(context);
                  final id = await _ensureTripSaved();
                  if (!mounted) return;
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => NavigationScreen(
                        tripId: id,
                        selectedPois: _orderedPois,
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.oceanDeep, AppColors.oceanMid],
                    ),
                    boxShadow: shadowOcean,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Stack(
                      children: [
                        child!,
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SheenPainter(position: _sheenAnim.value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation_rounded, color: Colors.white, size: 19),
                    const SizedBox(width: 8),
                    Text('Start Navigation',
                      style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 0.3,
                      )),
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

// ══════════════════════════════════════════════════════════════
// HELPER MODEL
// ══════════════════════════════════════════════════════════════
class _Tag {
  final String label;
  final Color bg;
  final Color fg;
  const _Tag(this.label, this.bg, this.fg);
}

// ══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════
class _StarsPainter extends CustomPainter {
  const _StarsPainter();
  static const _stars = [
    (50.0, 30.0, 0.75, 0.50),
    (180.0, 20.0, 0.50, 0.40),
    (310.0, 50.0, 0.50, 0.30),
    (120.0, 90.0, 0.50, 0.25),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      canvas.drawCircle(Offset(s.$1, s.$2), s.$3,
          Paint()..color = Colors.white.withOpacity(s.$4));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _SheenPainter extends CustomPainter {
  final double position;
  const _SheenPainter({required this.position});
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
  bool shouldRepaint(_SheenPainter old) => old.position != position;
}