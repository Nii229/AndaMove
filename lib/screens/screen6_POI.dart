// ============================================================
// AndaMove — POI Detail Screen + Add-to-Itinerary Flow
// File: lib/screens/screen6_POI.dart
//
// Changes (latest):
//   • [FIX] SelectItineraryScreen._confirm() calls
//     AppStore.addPoiToTrip() so screen11 stop count updates
//   • [FIX] SelectItineraryScreen hides Completed itineraries
//     (only In Progress + Upcoming shown in the pick list)
//   • [FIX] _mockItineraries synced to screen11's _kBaseTrips:
//       - IDs: trip_phuket_cultural / trip_phi_phi / trip_old_town
//       - Draft "Elephant Sanctuary" removed
//   • [FIX] _toggleFav wired to AppStore.togglePoi()
//   • [FIX] initState reads AppStore.isPoiSaved()
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screen7_generateItinerary.dart';
import '../app_store.dart';

// ══════════════════════════════════════════════════════════════
// COLOR / RADIUS / SHADOW TOKENS
// ══════════════════════════════════════════════════════════════
class _C {
  static const oceanDeep = Color(0xFF0A7FAB);
  static const oceanMid = Color(0xFF1AAECF);
  static const oceanTint = Color(0xFFEAF8FD);
  static const gold = Color(0xFFC8912E);
  static const goldLight = Color(0xFFF0C060);
  static const goldTint = Color(0xFFFDF5E7);
  static const coral = Color(0xFFE8634C);
  static const coralTint = Color(0xFFFDF0EE);
  static const green = Color(0xFF16A34A);
  static const greenTint = Color(0xFFEEF5EE);
  static const bg = Color(0xFFFBF8F3);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF5F1EB);
  static const border = Color(0xFFE6DDD1);
  static const borderLight = Color(0xFFF0EBE2);
  static const text1 = Color(0xFF0A1E28);
  static const text2 = Color(0xFF5A7A8A);
  static const text3 = Color(0xFF9AB0B8);
}

List<BoxShadow> get _shadowSm => [
  BoxShadow(
    color: const Color(0xFF0A1F28).withOpacity(0.06),
    blurRadius: 4,
    offset: const Offset(0, 1),
  ),
];
List<BoxShadow> get _shadowMd => [
  BoxShadow(
    color: const Color(0xFF0A1F28).withOpacity(0.08),
    blurRadius: 16,
    offset: const Offset(0, 4),
  ),
];

// ══════════════════════════════════════════════════════════════
// PUBLIC TAG MODEL
// ══════════════════════════════════════════════════════════════
class PoiTag {
  final String label;
  final Color bg;
  final Color fg;
  const PoiTag(this.label, this.bg, this.fg);
}

// ══════════════════════════════════════════════════════════════
// POI MODEL
// ══════════════════════════════════════════════════════════════
class PoiModel {
  final String name;
  final String location;
  final String category;
  final double rating;
  final String description;
  final String longDescription;
  final String openHours;
  final String estimatedTime;
  final String priceRange;
  final String imagePath;
  final List<Color> gradientColors;
  final IconData icon;
  final bool isFavourited;
  final List<PoiTag> tags;
  final double latitude;
  final double longitude;

  const PoiModel({
    required this.name,
    required this.location,
    required this.category,
    required this.rating,
    required this.description,
    this.longDescription = '',
    required this.openHours,
    required this.estimatedTime,
    this.priceRange = 'Free',
    this.imagePath = '',
    required this.gradientColors,
    required this.icon,
    this.isFavourited = false,
    this.tags = const [],
    this.latitude = 0.0,
    this.longitude = 0.0,
  });
}

// ══════════════════════════════════════════════════════════════
// ITINERARY SUMMARY MODEL
// ══════════════════════════════════════════════════════════════
class ItinerarySummary {
  final String id;
  final String name;
  final String date;
  final String destination;
  final int stopCount;
  final String transportLabel;
  final IconData transportIcon;
  final List<Color> coverColors;
  final String statusLabel;
  final Color statusFg;

  const ItinerarySummary({
    required this.id,
    required this.name,
    required this.date,
    required this.destination,
    required this.stopCount,
    required this.transportLabel,
    required this.transportIcon,
    required this.coverColors,
    required this.statusLabel,
    required this.statusFg,
  });
}

// ══════════════════════════════════════════════════════════════
// MOCK ITINERARIES — synced to screen11 _kBaseTrips
// Completed trips are stored here but filtered out in the UI
// ══════════════════════════════════════════════════════════════
final _mockItineraries = <ItinerarySummary>[
  const ItinerarySummary(
    id: 'trip_phuket_cultural',
    name: 'Phuket Cultural & Beach Day',
    date: 'Mon, 10 Mar 2026',
    destination: 'Phuket',
    stopCount: 4,
    transportLabel: 'Scooter',
    transportIcon: Icons.moped_rounded,
    coverColors: [Color(0xFFC8912E), Color(0xFFF0C060)],
    statusLabel: 'In Progress',
    statusFg: Color(0xFFC8912E),
  ),
  const ItinerarySummary(
    id: 'trip_phi_phi',
    name: 'Phi Phi Island Escape',
    date: 'Fri, 13 Mar 2026',
    destination: 'Phi Phi Islands',
    stopCount: 5,
    transportLabel: 'Boat',
    transportIcon: Icons.directions_boat_rounded,
    coverColors: [Color(0xFF0A7FAB), Color(0xFF1AAECF)],
    statusLabel: 'Upcoming',
    statusFg: Color(0xFF0A7FAB),
  ),
  const ItinerarySummary(
    id: 'trip_old_town',
    name: 'Old Town Food Trail',
    date: 'Sun, 8 Mar 2026',
    destination: 'Phuket Old Town',
    stopCount: 4,
    transportLabel: 'Walking',
    transportIcon: Icons.directions_walk_rounded,
    coverColors: [Color(0xFF16A34A), Color(0xFF4ADE80)],
    statusLabel: 'Completed',             // kept in data but hidden from picker
    statusFg: Color(0xFF16A34A),
  ),
];

// ══════════════════════════════════════════════════════════════
// POI DETAIL SCREEN
// ══════════════════════════════════════════════════════════════
class PoiDetailScreen extends StatefulWidget {
  final PoiModel poi;
  const PoiDetailScreen({super.key, required this.poi});

  @override
  State<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends State<PoiDetailScreen> {
  late bool _isFav;
  bool _expandAbout = false;

  @override
  void initState() {
    super.initState();
    _isFav = AppStore.isPoiSaved(widget.poi.name);
  }

  void _toggleFav() {
    HapticFeedback.lightImpact();
    final poi = widget.poi;
    AppStore.togglePoi(SavedPoiSummary(
      name: poi.name,
      location: poi.location,
      category: poi.category,
      rating: poi.rating,
      description: poi.description,
      openHours: poi.openHours,
      estimatedTime: poi.estimatedTime,
      priceRange: poi.priceRange,
      gradientColors: poi.gradientColors,
      icon: poi.icon,
      tagLabel: poi.tags.isNotEmpty ? poi.tags.first.label : poi.category,
      tagBg: poi.tags.isNotEmpty ? poi.tags.first.bg : const Color(0xFFEAF8FD),
      tagFg: poi.tags.isNotEmpty ? poi.tags.first.fg : const Color(0xFF0A7FAB),
      imagePath: poi.imagePath,
      longDescription: poi.longDescription,
    ));
    setState(() => _isFav = AppStore.isPoiSaved(poi.name));
  }

  Future<void> _navigateToPoi() async {
    final poi = widget.poi;
    if (poi.latitude == 0.0 && poi.longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location coordinates not available',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: _C.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${poi.latitude},${poi.longitude}'
      '&destination_place_id='
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToItinerarySheet(poi: widget.poi),
    );
  }

  Widget _buildStarRow(double rating) {
    final full = rating.floor();
    final half = (rating - full) >= 0.25 ? 1 : 0;
    final empty = 5 - full - half;

    return Row(
      children: [
        ...List.generate(full, (_) => const Icon(Icons.star_rounded, size: 20, color: Color(0xFFF0C060))),
        ...List.generate(half, (_) => const Icon(Icons.star_half_rounded, size: 20, color: Color(0xFFF0C060))),
        ...List.generate(empty, (_) => const Icon(Icons.star_outline_rounded, size: 20, color: Color(0xFFF0C060))),
        const SizedBox(width: 8),
        Text(rating.toStringAsFixed(1),
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: _C.text1)),
        const SizedBox(width: 5),
        Text('/ 5.0', style: GoogleFonts.outfit(fontSize: 12, color: _C.text3)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final poi = widget.poi;

    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 38, height: 38,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.30), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: Colors.white),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _toggleFav,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 16),
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _isFav ? _C.coral.withOpacity(0.85) : Colors.black.withOpacity(0.30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                size: 18, color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 280, width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  poi.imagePath.isNotEmpty
                      ? Image.asset(poi.imagePath, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: poi.gradientColors)),
                            child: Center(child: Icon(poi.icon, size: 90, color: Colors.white.withOpacity(0.18))),
                          ))
                      : Container(
                          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: poi.gradientColors)),
                          child: Center(child: Icon(poi.icon, size: 90, color: Colors.white.withOpacity(0.18))),
                        ),
                  Positioned(bottom: 0, left: 0, right: 0,
                    child: Container(height: 100, decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.60), Colors.transparent])))),
                  Positioned(bottom: 14, left: 18,
                    child: _heroBadge(icon: Icons.payments_outlined, label: poi.priceRange == 'Free' ? 'Free Entry' : poi.priceRange)),
                  Positioned(bottom: 14, right: 18,
                    child: _heroBadge(label: poi.category)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(poi.name, style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: _C.text1, height: 1.2)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 15, color: _C.text3),
                    const SizedBox(width: 4),
                    Expanded(child: Text(poi.location, style: GoogleFonts.outfit(fontSize: 13, color: _C.text2))),
                  ]),
                  const SizedBox(height: 14),
                  _buildStarRow(poi.rating),
                  const SizedBox(height: 14),
                  if (poi.tags.isNotEmpty) ...[
                    Wrap(spacing: 7, runSpacing: 7,
                      children: poi.tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(999)),
                        child: Text(t.label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: t.fg)),
                      )).toList(),
                    ),
                    const SizedBox(height: 22),
                  ],
                  Text('About', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _C.text1)),
                  const SizedBox(height: 8),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: _expandAbout ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Text(poi.longDescription, maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 14, height: 1.65, color: _C.text2)),
                    secondChild: Text(poi.longDescription,
                        style: GoogleFonts.outfit(fontSize: 14, height: 1.65, color: _C.text2)),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _expandAbout = !_expandAbout),
                    child: Text(_expandAbout ? 'Show less ▲' : 'Read more ▼',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: _C.oceanDeep)),
                  ),
                  const SizedBox(height: 22),
                  _infoCard(icon: Icons.access_time_rounded, title: 'Opening Hours', value: poi.openHours),
                  const SizedBox(height: 10),
                  _infoCard(icon: Icons.schedule_rounded, title: 'Estimated Visit', value: poi.estimatedTime),
                  const SizedBox(height: 10),
                  _infoCard(icon: Icons.payments_outlined, title: 'Entry Fee', value: poi.priceRange == 'Free' ? 'Free Entry' : 'Paid · ${poi.priceRange}'),
                  const SizedBox(height: 22),
                  _buildMiniMap(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _navigateToPoi,
                            icon: const Icon(Icons.navigation_rounded, size: 18),
                            label: Text('Navigate on\nGoogle Maps', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, height: 1.3)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _C.oceanDeep,
                              side: const BorderSide(color: _C.oceanDeep, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _openAddSheet,
                            icon: const Icon(Icons.add_location_alt_rounded, size: 20),
                            label: Text('Add to Itinerary', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _C.oceanDeep,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
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
    );
  }

  Widget _heroBadge({IconData? icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.38), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withOpacity(0.18))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: Colors.white), const SizedBox(width: 5)],
        Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.borderLight), boxShadow: _shadowSm),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: _C.oceanTint, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: _C.oceanDeep)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 11, color: _C.text3)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: _C.text1)),
        ])),
      ]),
    );
  }

  Widget _buildMiniMap() {
    final poi = widget.poi;
    if (poi.latitude == 0.0 && poi.longitude == 0.0) {
      return const SizedBox.shrink();
    }

    final poiLatLng = LatLng(poi.latitude, poi.longitude);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location',
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w700, color: _C.text1)),
        const SizedBox(height: 10),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.borderLight),
            boxShadow: _shadowSm,
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: poiLatLng,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: MarkerId(poi.name),
                position: poiLatLng,
                infoWindow: InfoWindow(
                  title: poi.name,
                  snippet: poi.location,
                ),
              ),
            },
            zoomControlsEnabled: false,
            scrollGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            liteModeEnabled: true,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.place_rounded, size: 12, color: _C.text3),
            const SizedBox(width: 4),
            Text(
              '${poi.latitude.toStringAsFixed(4)}, ${poi.longitude.toStringAsFixed(4)}',
              style: GoogleFonts.outfit(fontSize: 11, color: _C.text3),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ADD-TO-ITINERARY BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class _AddToItinerarySheet extends StatelessWidget {
  final PoiModel poi;
  const _AddToItinerarySheet({required this.poi});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _C.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _C.border, borderRadius: BorderRadius.circular(999)))),
            const SizedBox(height: 20),
            Text('Add to Itinerary', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: _C.text1)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_rounded, size: 13, color: _C.text3),
              const SizedBox(width: 4),
              Expanded(child: Text('${poi.name}  ·  ${poi.location}', style: GoogleFonts.outfit(fontSize: 12, color: _C.text2), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 22),
            _OptionTile(
              icon: Icons.add_circle_outline_rounded, iconBg: _C.oceanTint, iconFg: _C.oceanDeep,
              title: 'Create New Itinerary', subtitle: 'Start a fresh plan with this as the first stop',
              badgeLabel: 'Recommended', badgeBg: _C.oceanTint, badgeFg: _C.oceanDeep,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => GenerateItineraryScreen(preSelectedPoiNames: [poi.name])));
              },
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.playlist_add_rounded, iconBg: _C.goldTint, iconFg: _C.gold,
              title: 'Add to Existing Itinerary', subtitle: 'Pick one of your saved trips',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SelectItineraryScreen(poi: poi)));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon; final Color iconBg; final Color iconFg;
  final String title; final String subtitle;
  final String? badgeLabel; final Color? badgeBg; final Color? badgeFg;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.iconBg, required this.iconFg, required this.title, required this.subtitle, this.badgeLabel, this.badgeBg, this.badgeFg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.borderLight, width: 1.5), boxShadow: _shadowSm),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 24, color: iconFg)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: _C.text1))),
              if (badgeLabel != null) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)), child: Text(badgeLabel!, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: badgeFg)))],
            ]),
            const SizedBox(height: 3),
            Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: _C.text2)),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 20, color: _C.text3),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SELECT ITINERARY SCREEN
// ══════════════════════════════════════════════════════════════
class SelectItineraryScreen extends StatefulWidget {
  final PoiModel poi;
  const SelectItineraryScreen({super.key, required this.poi});
  @override
  State<SelectItineraryScreen> createState() => _SelectItineraryScreenState();
}

class _SelectItineraryScreenState extends State<SelectItineraryScreen> {
  String? _selectedId;

  // [FIX #2] Only show non-completed itineraries in the picker
  List<ItinerarySummary> get _pickableItineraries =>
      _mockItineraries.where((it) => it.statusLabel != 'Completed').toList();

  void _confirm() {
    if (_selectedId == null) return;
    final chosen = _mockItineraries.firstWhere((it) => it.id == _selectedId);

    // [FIX #1] Persist the added POI so screen11 can reflect the updated count
    AppStore.addPoiToTrip(_selectedId!, widget.poi.name);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating, backgroundColor: _C.text1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text('"${widget.poi.name}" added to "${chosen.name}"',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
      ]),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final list = _pickableItineraries;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface, elevation: 0, surfaceTintColor: Colors.transparent,
        leading: GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _C.text1)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Itinerary', style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.w700, color: _C.text1)),
          Text('Adding "${widget.poi.name}"', style: GoogleFonts.outfit(fontSize: 11, color: _C.text2), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        titleSpacing: 4,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: _C.borderLight)),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 4), child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(color: _C.oceanTint, borderRadius: BorderRadius.circular(999)),
            child: Text('${list.length} available itineraries',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: _C.oceanDeep)),
          ),
        ])),
        Expanded(child: list.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: list.length,
                itemBuilder: (_, i) => _buildItineraryCard(list[i]),
              )),
      ]),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(color: _C.surface, border: const Border(top: BorderSide(color: _C.borderLight)),
            boxShadow: [BoxShadow(color: const Color(0xFF0A1F28).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))]),
        child: SafeArea(top: false, child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200), opacity: _selectedId != null ? 1.0 : 0.45,
          child: SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton.icon(
              onPressed: _selectedId != null ? _confirm : null,
              icon: Icon(_selectedId != null ? Icons.check_rounded : Icons.touch_app_rounded, size: 20),
              label: Text(_selectedId != null ? 'Add to this Itinerary' : 'Select an Itinerary First',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.oceanDeep, disabledBackgroundColor: _C.oceanDeep,
                foregroundColor: Colors.white, disabledForegroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: const BoxDecoration(color: _C.surface2, shape: BoxShape.circle),
            child: const Icon(Icons.map_outlined, size: 28, color: _C.text3)),
        const SizedBox(height: 14),
        Text('No active itineraries', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _C.text2)),
        const SizedBox(height: 6),
        Text('Create a new itinerary to add this place.',
            style: GoogleFonts.outfit(fontSize: 13, color: _C.text3)),
      ]),
    );
  }

  Widget _buildItineraryCard(ItinerarySummary it) {
    final isSelected = _selectedId == it.id;
    // Show live added count from AppStore on top of base stopCount
    final extraCount = AppStore.getAddedPoisForTrip(it.id).length;
    final totalStops = it.stopCount + extraCount;

    return GestureDetector(
      onTap: () => setState(() => _selectedId = it.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? _C.oceanDeep : _C.borderLight, width: isSelected ? 2.0 : 1.5),
            boxShadow: isSelected ? _shadowMd : _shadowSm),
        child: Row(children: [
          Container(width: 5, height: 90,
              decoration: BoxDecoration(borderRadius: const BorderRadius.horizontal(left: Radius.circular(17)),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: it.coverColors))),
          Container(width: 50, height: 50, margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: it.coverColors)),
              child: Icon(it.transportIcon, size: 22, color: Colors.white.withOpacity(0.85))),
          Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: _C.text1))),
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: it.statusFg.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
                  child: Text(it.statusLabel, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: it.statusFg))),
              const SizedBox(width: 10),
            ]),
            const SizedBox(height: 4),
            Row(children: [const Icon(Icons.location_on_rounded, size: 11, color: _C.text3), const SizedBox(width: 3), Text(it.destination, style: GoogleFonts.outfit(fontSize: 11, color: _C.text2))]),
            const SizedBox(height: 2),
            Row(children: [const Icon(Icons.calendar_today_rounded, size: 11, color: _C.text3), const SizedBox(width: 3), Text(it.date, style: GoogleFonts.outfit(fontSize: 11, color: _C.text2))]),
            const SizedBox(height: 8),
            Row(children: [
              _miniPill(Icons.location_on_rounded, '$totalStops stops', _C.oceanTint, _C.oceanDeep),
              const SizedBox(width: 6),
              _miniPill(it.transportIcon, it.transportLabel, _C.surface2, _C.text2),
            ]),
          ]))),
          AnimatedContainer(duration: const Duration(milliseconds: 180), width: 24, height: 24, margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? _C.oceanDeep : Colors.transparent,
                  border: Border.all(color: isSelected ? _C.oceanDeep : _C.border, width: 2)),
              child: isSelected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null),
        ]),
      ),
    );
  }

  Widget _miniPill(IconData icon, String label, Color bg, Color fg) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
        ]));
  }
}