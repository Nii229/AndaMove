// ============================================================
// AndaMove — Pick Existing Itinerary Screen
// File: lib/screens/screen6b_pick_itinerary.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════
// LIGHTWEIGHT ITINERARY SUMMARY MODEL
// TODO: Replace with real Trip model from trips_screen.dart
// ══════════════════════════════════════════════════════════════
class ItinerarySummary {
  final String id;
  final String name;
  final String dateLabel;
  final int stopCount;
  final String statusLabel;
  final IconData statusIcon;
  final Color statusBg;
  final Color statusFg;
  final List<Color> stripeColors;

  const ItinerarySummary({
    required this.id,
    required this.name,
    required this.dateLabel,
    required this.stopCount,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusBg,
    required this.statusFg,
    required this.stripeColors,
  });
}

// ══════════════════════════════════════════════════════════════
// COLOR TOKENS
// ══════════════════════════════════════════════════════════════
class _C {
  static const Color oceanDeep  = Color(0xFF0A7FAB);
  static const Color oceanMid   = Color(0xFF1AAECF);
  static const Color oceanTint  = Color(0xFFEAF8FD);
  static const Color gold       = Color(0xFFC8912E);
  static const Color goldLight  = Color(0xFFF0C060);
  static const Color goldTint   = Color(0xFFFDF5E7);
  static const Color green      = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFF4ADE80);
  static const Color greenTint  = Color(0xFFEEF5EE);
  static const Color bg         = Color(0xFFFBF8F3);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surface2   = Color(0xFFF5F1EB);
  static const Color border     = Color(0xFFE6DDD1);
  static const Color borderLight= Color(0xFFF0EBE2);
  static const Color text1      = Color(0xFF0A1E28);
  static const Color text2      = Color(0xFF5A7A8A);
  static const Color text3      = Color(0xFF9AB0B8);
}

// ══════════════════════════════════════════════════════════════
// PICK ITINERARY SCREEN
// ══════════════════════════════════════════════════════════════
class PickItineraryScreen extends StatefulWidget {
  final String poiName;
  const PickItineraryScreen({super.key, required this.poiName});

  @override
  State<PickItineraryScreen> createState() => _PickItineraryScreenState();
}

class _PickItineraryScreenState extends State<PickItineraryScreen> {
  String? _selectedId;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // TODO: Replace with real trip data
  static final List<ItinerarySummary> _itineraries = [
    ItinerarySummary(
      id: 'trip_1',
      name: 'Phuket Cultural & Beach Day',
      dateLabel: 'Mon, 10 Mar 2026',
      stopCount: 4,
      statusLabel: 'In Progress',
      statusIcon: Icons.my_location_rounded,
      statusBg: const Color(0xFFFFF8EC),
      statusFg: _C.gold,
      stripeColors: const [_C.gold, _C.goldLight],
    ),
    ItinerarySummary(
      id: 'trip_2',
      name: 'Phi Phi Island Escape',
      dateLabel: 'Fri, 13 Mar 2026',
      stopCount: 5,
      statusLabel: 'Upcoming',
      statusIcon: Icons.event_rounded,
      statusBg: _C.oceanTint,
      statusFg: _C.oceanDeep,
      stripeColors: const [_C.oceanDeep, _C.oceanMid],
    ),
    ItinerarySummary(
      id: 'trip_3',
      name: 'Old Town Food Trail',
      dateLabel: 'Sun, 8 Mar 2026',
      stopCount: 4,
      statusLabel: 'Completed',
      statusIcon: Icons.check_circle_rounded,
      statusBg: _C.greenTint,
      statusFg: _C.green,
      stripeColors: const [_C.green, _C.greenLight],
    ),
    ItinerarySummary(
      id: 'trip_4',
      name: 'Elephant Sanctuary + Viewpoints',
      dateLabel: 'Draft · Not Scheduled',
      stopCount: 2,
      statusLabel: 'Draft',
      statusIcon: Icons.edit_note_rounded,
      statusBg: _C.surface2,
      statusFg: _C.text3,
      stripeColors: const [],
    ),
  ];

  List<ItinerarySummary> get _filtered {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _itineraries;
    return _itineraries.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _confirmAdd(ItinerarySummary trip) {
    // TODO: call real add-POI-to-trip logic here
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '"${widget.poiName}" added to "${trip.name}"',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _C.text1),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Itinerary',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _C.text1),
            ),
            Text(
              'Adding "${widget.poiName}"',
              style: GoogleFonts.outfit(fontSize: 11, color: _C.text3),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.borderLight),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                Text(
                  '${filtered.length} itinerar${filtered.length == 1 ? 'y' : 'ies'}',
                  style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _C.text2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildItineraryTile(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // SEARCH BAR
  // ════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _C.borderLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1F28).withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18, color: _C.text3),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.outfit(fontSize: 13, color: _C.text1),
                decoration: InputDecoration(
                  hintText: 'Search your itineraries…',
                  hintStyle: GoogleFonts.outfit(fontSize: 13, color: _C.text3),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          splashRadius: 16,
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 16, color: _C.text3),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // ITINERARY TILE
  //
  // Fix summary:
  //   • IntrinsicHeight wraps the row so the stripe fills the
  //     real card height instead of a hardcoded 80px
  //   • Status row uses MainAxisAlignment.spaceBetween inside
  //     its own Row, with the badge wrapped in Flexible so it
  //     can never overflow into the button
  //   • "Add Here" button is always visible (no selection gate)
  //     and highlights when the card is selected
  // ════════════════════════════════════════════════════════
  Widget _buildItineraryTile(ItinerarySummary trip) {
    final isSelected = _selectedId == trip.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedId = isSelected ? null : trip.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _C.oceanDeep : _C.borderLight,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1F28).withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          // ── IntrinsicHeight lets the stripe match card height ──
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left stripe ─────────────────────────────────
                Container(
                  width: 4,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: trip.stripeColors.isEmpty
                      ? BoxDecoration(
                          color: _C.border,
                          borderRadius: BorderRadius.circular(4),
                        )
                      : BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: trip.stripeColors,
                          ),
                        ),
                ),

                // ── Content ─────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trip name
                      Text(
                        trip.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _C.text1,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Date + stops row
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 11, color: _C.text3),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              trip.dateLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 11, color: _C.text2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_rounded, size: 11, color: _C.text3),
                          const SizedBox(width: 3),
                          Text(
                            '${trip.stopCount} stop${trip.stopCount == 1 ? '' : 's'}',
                            style: GoogleFonts.outfit(fontSize: 11, color: _C.text2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Status badge + Add Here button ──────────
                      // Uses MainAxisAlignment.spaceBetween so they
                      // sit at opposite ends with no overflow risk.
                      // Badge is Flexible so long text wraps, not
                      // pushes the button off-screen.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Status badge
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: trip.statusBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(trip.statusIcon, size: 11, color: trip.statusFg),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      trip.statusLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: trip.statusFg,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Add Here button — always visible
                          GestureDetector(
                            onTap: () => _confirmAdd(trip),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected ? _C.oceanDeep : _C.surface2,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected ? _C.oceanDeep : _C.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    size: 14,
                                    color: isSelected ? Colors.white : _C.text2,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add Here',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : _C.text2,
                                    ),
                                  ),
                                ],
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
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // EMPTY STATE
  // ════════════════════════════════════════════════════════
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _C.surface2,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.search_off_rounded, size: 30, color: _C.text3),
          ),
          const SizedBox(height: 14),
          Text(
            'No itineraries found',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: _C.text1),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search term',
            style: GoogleFonts.outfit(fontSize: 13, color: _C.text3),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DASHED VERTICAL PAINTER (kept for potential future use)
// ══════════════════════════════════════════════════════════════
class _DashedVerticalPainter extends CustomPainter {
  final Color color;
  const _DashedVerticalPainter({required this.color});

  static const double _dashH = 6.0;
  static const double _gapH  = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    double y = 0;
    while (y < size.height) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, _dashH.clamp(0, size.height - y)),
        paint,
      );
      y += _dashH + _gapH;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedVerticalPainter old) => old.color != color;
}