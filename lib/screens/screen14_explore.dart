// ============================================================
// AndaMove — Explore Screen
// File: lib/screens/screen14_explore.dart
//
// Changes vs original:
//   • import app_store.dart
//   • Working search bar (_searchQuery, _showSearch, _filteredStories)
//   • Save toggle wired to AppStore.toggleVlog()
//   • Follow Trip in itinerary sheet wired to AppStore.followTrip()
//   • _ItinerarySheet converted to StatefulWidget (shows "Following ✓")
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../app_store.dart';
import 'package:video_player/video_player.dart';

// ══════════════════════════════════════════════════════════════
// COLOR TOKENS
// ══════════════════════════════════════════════════════════════
class AppColors {
  static const Color oceanDeep   = Color(0xFF0A7FAB);
  static const Color oceanMid    = Color(0xFF1AAECF);
  static const Color oceanTint   = Color(0xFFEAF8FD);
  static const Color gold        = Color(0xFFC8912E);
  static const Color goldLight   = Color(0xFFF0C060);
  static const Color coral       = Color(0xFFE8634C);
  static const Color green       = Color(0xFF16A34A);
  static const Color bg          = Color(0xFFFBF8F3);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color border      = Color(0xFFE6DDD1);
  static const Color borderLight = Color(0xFFF0EBE2);
  static const Color surface2    = Color(0xFFF5F1EB);
  static const Color text1       = Color(0xFF0A1E28);
  static const Color text2       = Color(0xFF5A7A8A);
  static const Color text3       = Color(0xFF9AB0B8);
}

class AppRadius {
  static const double md   = 14;
  static const double lg   = 20;
  static const double xl   = 28;
  static const double full = 9999;
}

// ══════════════════════════════════════════════════════════════
// SCENE PAINTER (unchanged from original)
// ══════════════════════════════════════════════════════════════
class ScenePainter extends CustomPainter {
  final StoryScene scene;
  final double kenBurns;
  const ScenePainter({required this.scene, required this.kenBurns});

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = 1.0 + kenBurns * 0.06;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-size.width / 2, -size.height / 2);
    switch (scene) {
      case StoryScene.beach:   _paintBeach(canvas, size);  break;
      case StoryScene.temple:  _paintTemple(canvas, size); break;
      case StoryScene.jungle:  _paintJungle(canvas, size); break;
      case StoryScene.sunset:  _paintSunset(canvas, size); break;
      case StoryScene.market:  _paintMarket(canvas, size); break;
    }
    canvas.restore();
  }

  void _paintBeach(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.55),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A6B9A), Color(0xFF4DBCE9)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.55)));
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.52), width: size.width * 1.4, height: 80),
      Paint()..color = const Color(0xFFF0E9C0).withOpacity(0.25));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.52, size.width, size.height * 0.27),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF38BED6), Color(0xFF1595A8)]).createShader(Rect.fromLTWH(0, size.height * 0.52, size.width, size.height * 0.27)));
    final shimmer = Paint()..color = Colors.white.withOpacity(0.12)..strokeWidth = 1.5;
    for (int i = 0; i < 5; i++) { final y = size.height * (0.55 + i * 0.04); canvas.drawLine(Offset(size.width * 0.1, y), Offset(size.width * 0.9, y), shimmer); }
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.79, size.width, size.height * 0.21),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8D5A0), Color(0xFFCFB87A)]).createShader(Rect.fromLTWH(0, size.height * 0.79, size.width, size.height * 0.21)));
    _drawCloud(canvas, Offset(size.width * 0.3, size.height * 0.10), 50);
    _drawCloud(canvas, Offset(size.width * 0.72, size.height * 0.18), 38);
  }

  void _drawCloud(Canvas canvas, Offset center, double r) {
    final p = Paint()..color = Colors.white.withOpacity(0.55);
    canvas.drawOval(Rect.fromCenter(center: center, width: r * 2, height: r), p);
    canvas.drawCircle(center.translate(-r * 0.3, -r * 0.25), r * 0.55, p);
    canvas.drawCircle(center.translate(r * 0.3, -r * 0.20), r * 0.45, p);
  }

  void _paintTemple(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0D2B3E), Color(0xFF1A5276), Color(0xFF2E86AB)], stops: [0, 0.5, 1]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    final star = Paint()..color = Colors.white.withOpacity(0.7);
    final rng = math.Random(42);
    for (int i = 0; i < 40; i++) { canvas.drawCircle(Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height * 0.4), rng.nextDouble() * 1.5 + 0.5, star); }
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28), Paint()..color = const Color(0xFF0A1A10));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.15, size.height * 0.68, size.width * 0.70, size.height * 0.06), const Radius.circular(4)), Paint()..color = const Color(0xFF1E3A20));
    canvas.drawRect(Rect.fromLTWH(size.width * 0.30, size.height * 0.46, size.width * 0.40, size.height * 0.24), Paint()..color = const Color(0xFF1A3226));
    final spireGold = Paint()..color = const Color(0xFFC8912E);
    for (int tier = 0; tier < 5; tier++) {
      final w = size.width * (0.28 - tier * 0.04); final h = size.height * (0.046 - tier * 0.004);
      final x = (size.width - w) / 2; final y = size.height * (0.46 - tier * 0.044);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)), spireGold);
    }
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.24), 35,
      Paint()..color = const Color(0xFFC8912E).withOpacity(0.20)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.44, size.height * 0.54, size.width * 0.12, size.height * 0.09), const Radius.circular(20)),
      Paint()..color = const Color(0xFFC8912E).withOpacity(0.60));
  }

  void _paintJungle(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2C5F3A), Color(0xFF1A3D22), Color(0xFF0D2210)], stops: [0, 0.5, 1]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.38, size.width, size.height * 0.28),
      Paint()..color = Colors.white.withOpacity(0.10)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));
    final pathP = Paint()..color = const Color(0xFF8B6914).withOpacity(0.70);
    final pathShape = Path()..moveTo(size.width * 0.35, size.height)..lineTo(size.width * 0.65, size.height)..lineTo(size.width * 0.55, size.height * 0.5)..lineTo(size.width * 0.45, size.height * 0.5)..close();
    canvas.drawPath(pathShape, pathP);
    for (final spec in [[0.10, 0.92, 0.40], [0.82, 0.90, 0.38], [0.22, 0.88, 0.30], [0.72, 0.86, 0.28]]) {
      final x = size.width * spec[0]; final y = size.height * spec[1]; final r = size.height * spec[2];
      canvas.drawLine(Offset(x, y), Offset(x + 5, y - r * 0.55), Paint()..color = const Color(0xFF4A3220)..strokeWidth = 8..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(x + 5, y - r * 0.55), r * 0.5, Paint()..color = const Color(0xFF1E5E26).withOpacity(0.90)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
  }

  void _paintSunset(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A0A2E), Color(0xFF6B1F4E), Color(0xFFD45F1A), Color(0xFFE8A020)], stops: [0, 0.30, 0.65, 1]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.52), 38, Paint()..color = const Color(0xFFFFC040).withOpacity(0.90)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.52), 28, Paint()..color = const Color(0xFFFFE080));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB84010), Color(0xFF5A1E40)]).createShader(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45)));
  }

  void _paintMarket(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A0A18), Color(0xFF1A100A), Color(0xFF2A1505)], stops: [0, 0.5, 1]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28), Paint()..color = const Color(0xFF1A0E05));
    for (int i = 0; i < 4; i++) {
      final x = size.width * (0.05 + i * 0.24); final stallW = size.width * 0.20;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height * 0.46, stallW, size.height * 0.28), const Radius.circular(4)),
        Paint()..color = [const Color(0xFF8B1A10), const Color(0xFF1A5C1A), const Color(0xFF1A1A8B), const Color(0xFF8B5A10)][i]);
    }
    for (int i = 0; i < 8; i++) {
      final lx = size.width * (0.06 + i * 0.13); final ly = size.height * (0.31 + (i % 2) * 0.03);
      final lanternColor = [const Color(0xFFE84C20), const Color(0xFFF0A020), const Color(0xFFE8C020)][i % 3];
      canvas.drawOval(Rect.fromCenter(center: Offset(lx, ly), width: 14, height: 20), Paint()..color = lanternColor.withOpacity(0.90)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(Offset(lx, ly), 18, Paint()..color = lanternColor.withOpacity(0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }
  }

  @override
  bool shouldRepaint(ScenePainter old) => old.scene != scene || old.kenBurns != kenBurns;
}

enum StoryScene { beach, temple, jungle, sunset, market }

// ══════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════
class ItineraryStop {
  final String name;
  final String type;
  final String duration;
  final String distance;
  const ItineraryStop({required this.name, required this.type, required this.duration, required this.distance});
}

class StoryVlog {
  final String id;
  final String title;
  final String location;
  final String creatorName;
  final String creatorHandle;
  final Color  creatorAvatarColor;
  final String creatorInitials;
  final StoryScene scene;
  final List<String> tags;
  final String totalDuration;
  final int    stopCount;
  final List<ItineraryStop> stops;
  final String videoPath;
  bool isSaved;

  StoryVlog({required this.id, required this.title, required this.location, required this.creatorName,
    required this.creatorHandle, required this.creatorAvatarColor, required this.creatorInitials,
    required this.scene, required this.tags, required this.totalDuration, required this.stopCount,
required this.stops, required this.videoPath, this.isSaved = false});}

// ══════════════════════════════════════════════════════════════
// SEED DATA
// ══════════════════════════════════════════════════════════════
final List<StoryVlog> seedStories = [
  StoryVlog(id: 's1', title: 'A Perfect Day at Kata Beach', location: 'Kata Beach, Phuket', creatorName: 'Ozo Phuket', creatorHandle: '@ozophuket', creatorAvatarColor: const Color(0xFF2E86AB), creatorInitials: 'MT', scene: StoryScene.beach, tags: ['Beach', 'Chill', 'Sunset'], totalDuration: '6 hrs', stopCount: 4,
    stops: const [ItineraryStop(name: 'Kata Beach', type: 'Beach', duration: '2 hr', distance: 'Start'), ItineraryStop(name: 'Kata Noi Viewpoint', type: 'View', duration: '45 min', distance: '1.2 km'), ItineraryStop(name: 'Boathouse Restaurant', type: 'Food', duration: '1 hr', distance: '600 m'), ItineraryStop(name: 'Kata Night Market', type: 'Market', duration: '1.5 hr', distance: '800 m')],
    videoPath: 'assets/videos/kata_beach.mov'),
  StoryVlog(id: 's2', title: 'Chasing Gold — Big Buddha Trek', location: 'Nakkerd Hill, Phuket', creatorName: 'Phuket Explores', creatorHandle: '@phuket.explores', creatorAvatarColor: const Color(0xFFC8912E), creatorInitials: 'SC', scene: StoryScene.temple, tags: ['Temple', 'Culture', 'Photography'], totalDuration: '4 hrs', stopCount: 3,
    stops: const [ItineraryStop(name: 'Big Buddha', type: 'Temple', duration: '1.5 hr', distance: 'Start'), ItineraryStop(name: 'Chalong Temple', type: 'Temple', duration: '1 hr', distance: '4.2 km'), ItineraryStop(name: 'Rawai Seafood Market', type: 'Food', duration: '1.5 hr', distance: '3.8 km')],
    videoPath: 'assets/videos/big_buddha.mov'),
  StoryVlog(id: 's3', title: 'Hidden Jungle Trails of Phuket', location: 'Khao Phra Thaeo, Phuket', creatorName: 'My Little Marshmallow', creatorHandle: '@my_little_marshmallow', creatorAvatarColor: const Color(0xFF16A34A), creatorInitials: 'LW', scene: StoryScene.jungle, tags: ['Nature', 'Hiking', 'Wildlife'], totalDuration: '5 hrs', stopCount: 3,
    stops: const [ItineraryStop(name: 'Ton Sai Waterfall', type: 'Nature', duration: '1.5 hr', distance: 'Start'), ItineraryStop(name: 'Bang Pae Waterfall', type: 'Nature', duration: '1.5 hr', distance: '3.0 km'), ItineraryStop(name: 'Gibbon Rehab Project', type: 'Wildlife', duration: '2 hr', distance: '1.8 km')],
    videoPath: 'assets/videos/khao_phra_thaeo.mov'),
  StoryVlog(id: 's4', title: 'Phromthep Sunset — Magic Hour', location: 'Cape Phromthep, Phuket', creatorName: 'Daily World Views', creatorHandle: '@dailyworldviews', creatorAvatarColor: const Color(0xFFE8634C), creatorInitials: 'AS', scene: StoryScene.sunset, tags: ['Sunset', 'Scenic', 'Couples'], totalDuration: '3 hrs', stopCount: 3,
    stops: const [ItineraryStop(name: 'Windmill Viewpoint', type: 'View', duration: '45 min', distance: 'Start'), ItineraryStop(name: 'Cape Phromthep', type: 'View', duration: '1 hr', distance: '1.5 km'), ItineraryStop(name: 'Nai Harn Beach', type: 'Beach', duration: '1.5 hr', distance: '2.2 km')],
    videoPath: 'assets/videos/promthep_cave.mov'),
  StoryVlog(id: 's5', title: 'Old Phuket Town Night Market', location: 'Thalang Rd, Phuket Town', creatorName: 'Lola Schroer', creatorHandle: '@lolaschroer', creatorAvatarColor: const Color(0xFF7C3AED), creatorInitials: 'FR', scene: StoryScene.market, tags: ['Food', 'Night', 'Local'], totalDuration: '3 hrs', stopCount: 4,
    stops: const [ItineraryStop(name: 'Oasis of Phuket Town', type: 'Coffee Shop', duration: '1 hr', distance: 'Start'), ItineraryStop(name: 'Kobkaew Phuket', type: 'Local clothing store', duration: '45 min', distance: '200 m'), ItineraryStop(name: 'Thaiverto Ice Cream', type: 'Food', duration: '30 min', distance: '150 m'), ItineraryStop(name: 'Hogs Head', type: 'Food', duration: '45 min', distance: '400 m'), ItineraryStop(name: 'Pun Te Phuket Food Center', type: 'Food', duration: '30 min', distance: '150 m'), ItineraryStop(name: 'Honda Cafe', type: 'Food', duration: '40 min', distance: '200 m'), ItineraryStop(name: 'Sunday Food Market', type: 'Food', duration: '20 min', distance: '100 m')],
    videoPath: 'assets/videos/old_phuket_town.mov'),
];

// ══════════════════════════════════════════════════════════════
// EXPLORE SCREEN
// ══════════════════════════════════════════════════════════════
class ExploreScreen extends StatefulWidget {
  final int initialPage;
  const ExploreScreen({super.key, this.initialPage = 0});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
late final PageController _pageCtrl;  int    _currentPage  = 0;
  String _searchQuery  = '';
  bool   _showSearch   = false;
  final  TextEditingController _searchCtrl = TextEditingController();
  late final List<StoryVlog> _stories;

  @override
  void initState() {
    super.initState();
    _stories = List.from(seedStories);
    // Sync isSaved from store on entry
    for (final s in _stories) { s.isSaved = AppStore.isVlogSaved(s.id); }
    _currentPage = widget.initialPage.clamp(0, _stories.length - 1);
    _pageCtrl = PageController(initialPage: _currentPage);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _searchCtrl.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  // ── Filtered stories ──────────────────────────────────────
  List<StoryVlog> get _filteredStories {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _stories;
    return _stories.where((s) =>
      s.title.toLowerCase().contains(q) ||
      s.location.toLowerCase().contains(q) ||
      s.creatorName.toLowerCase().contains(q) ||
      s.tags.any((t) => t.toLowerCase().contains(q))
    ).toList();
  }

  // ── Save toggle wired to AppStore ─────────────────────────
  void _handleSaveToggle(StoryVlog story) {
    AppStore.toggleVlog(SavedVlogSummary(
      id: story.id, title: story.title, location: story.location,
      creatorName: story.creatorName, creatorInitials: story.creatorInitials,
      creatorAvatarColor: story.creatorAvatarColor,
      totalDuration: story.totalDuration, stopCount: story.stopCount,
      tags: story.tags, thumbColors: _sceneThumbColors(story.scene),
      storyIndex: _stories.indexWhere((s) => s.id == story.id),
    ));
    setState(() => story.isSaved = AppStore.isVlogSaved(story.id));
  }

  List<Color> _sceneThumbColors(StoryScene scene) {
    switch (scene) {
      case StoryScene.beach:  return [const Color(0xFF1A6B9A), const Color(0xFF38BED6)];
      case StoryScene.temple: return [const Color(0xFF0D2B3E), const Color(0xFF2E86AB)];
      case StoryScene.jungle: return [const Color(0xFF2C5F3A), const Color(0xFF1A3D22)];
      case StoryScene.sunset: return [const Color(0xFF6B1F4E), const Color(0xFFD45F1A)];
      case StoryScene.market: return [const Color(0xFF1A100A), const Color(0xFF2A1505)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStories;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          filtered.isEmpty
              ? _buildEmptyState()
              : PageView.builder(
                  controller: _pageCtrl,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _StoryPage(
                    story: filtered[i],
                    isActive: i == _currentPage,
                    onSaveToggle: () => _handleSaveToggle(filtered[i]),
                    onViewItinerary: () => _showItinerarySheet(context, filtered[i]),
                  ),
                ),
          _buildTopBar(),
          if (!_showSearch && filtered.isNotEmpty)
            _buildPageDots(filtered.length),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: _showSearch
              ? _buildSearchBar()
              : Row(children: [
                  _glassBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.maybePop(context)),
                  const Spacer(),
                  Text('Explore', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, shadows: const [Shadow(color: Color(0x80000000), blurRadius: 8)])),
                  const Spacer(),
                  _glassBtn(icon: Icons.search_rounded, onTap: () => setState(() { _showSearch = true; })),
                ]),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withOpacity(0.20))),
      child: Row(children: [
        const SizedBox(width: 14),
        const Icon(Icons.search_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 0; }),
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search vlogs, places, tags…',
              hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.white.withOpacity(0.45)),
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        GestureDetector(
          onTap: () { _searchCtrl.clear(); setState(() { _searchQuery = ''; _showSearch = false; _currentPage = 0; }); },
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.70), size: 18)),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.travel_explore_rounded, size: 52, color: Colors.white.withOpacity(0.25)),
      const SizedBox(height: 14),
      Text('No vlogs found', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.60))),
      const SizedBox(height: 6),
      Text('Try a different keyword', style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.35))),
    ]));
  }

  Widget _glassBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap,
      child: Container(width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.30), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.white.withOpacity(0.18))),
        child: Icon(icon, color: Colors.white, size: 20)));
  }

  Widget _buildPageDots(int count) {
    return Positioned(left: 10, top: 0, bottom: 0,
      child: Center(child: Column(mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final active = i == _currentPage;
          return AnimatedContainer(duration: const Duration(milliseconds: 250),
            width: 3, height: active ? 22 : 6, margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(color: active ? Colors.white : Colors.white.withOpacity(0.35), borderRadius: BorderRadius.circular(AppRadius.full)));
        }))));
  }

  void _showItinerarySheet(BuildContext context, StoryVlog story) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _ItinerarySheet(story: story));
  }
}

// ══════════════════════════════════════════════════════════════
// STORY PAGE
// ══════════════════════════════════════════════════════════════
class _StoryPage extends StatefulWidget {
  final StoryVlog story;
  final bool isActive;
  final VoidCallback onSaveToggle;
  final VoidCallback onViewItinerary;
  const _StoryPage({required this.story, required this.isActive, required this.onSaveToggle, required this.onViewItinerary});
  @override
  State<_StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<_StoryPage> {
  late VideoPlayerController _videoCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _videoCtrl = VideoPlayerController.asset(widget.story.videoPath)
      ..setLooping(true)
      ..setVolume(0) // muted like Reels/TikTok
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          if (widget.isActive) _videoCtrl.play();
        }
      });
  }

  @override
  void didUpdateWidget(_StoryPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _videoCtrl.seekTo(Duration.zero);
      _videoCtrl.play();
    } else if (!widget.isActive && old.isActive) {
      _videoCtrl.pause();
    }
  }

  @override
  void dispose() {
    _videoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(fit: StackFit.expand, children: [
      // ── Video background (fills screen, cropped to cover) ──
      if (_initialized)
        Container(
          color: Colors.black,
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoCtrl.value.aspectRatio,
              child: VideoPlayer(_videoCtrl),
            ),
          ),
        )
      else
        // Fallback: painted scene while video loads
        CustomPaint(
          size: size,
          painter: ScenePainter(scene: widget.story.scene, kenBurns: 0),
        ),

      // ── Top gradient ──
      Positioned(top: 0, left: 0, right: 0, height: size.height * 0.35,
        child: Container(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.65), Colors.transparent])))),

      // ── Bottom gradient ──
      Positioned(bottom: 0, left: 0, right: 0, height: size.height * 0.55,
        child: Container(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.88), Colors.black.withOpacity(0.40), Colors.transparent],
          stops: const [0, 0.55, 1])))),

      // ── Action buttons (right side) ──
      Positioned(right: 14, bottom: size.height * 0.14,
        child: _buildActionColumn()),

      // ── Bottom content (creator info, title, tags) ──
      Positioned(left: 20, right: 80, bottom: 0,
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _buildBottomContent()))),
    ]);
  }

  void _shareVlog(StoryVlog story) {
    final stopLines = story.stops
        .map((s) => '📍 ${s.name} · ${s.duration}')
        .join('\n');
    final text = '🎬 ${story.title}\n'
        '📍 ${story.location}\n'
        '🎥 by ${story.creatorName}\n\n'
        'Itinerary (${story.totalDuration} · ${story.stopCount} stops):\n'
        '$stopLines\n\n'
        'Discover Phuket with AndaMove 👉 https://andamove.app';
    Share.share(text);
  }

  Widget _buildActionColumn() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _ActionButton(icon: widget.story.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        label: widget.story.isSaved ? 'Saved' : 'Save', active: widget.story.isSaved,
        activeColor: AppColors.goldLight, onTap: widget.onSaveToggle),
      const SizedBox(height: 20),
      _ActionButton(
        icon: Icons.ios_share_rounded,
        label: 'Share',
        onTap: () => _shareVlog(widget.story),
      ),
      const SizedBox(height: 20),
      _ItineraryButton(onTap: widget.onViewItinerary),
    ]);
  }

  Widget _buildBottomContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: widget.story.creatorAvatarColor, shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.70), width: 1.5)),
          child: Center(child: Text(widget.story.creatorInitials, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)))),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(widget.story.creatorName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, shadows: const [Shadow(color: Color(0x80000000), blurRadius: 6)])),
          Text(widget.story.creatorHandle, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white.withOpacity(0.65))),
        ]),
      ]),
      const SizedBox(height: 12),
      Text(widget.story.title, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2, shadows: const [Shadow(color: Color(0x99000000), blurRadius: 10)])),
      const SizedBox(height: 8),
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.40), borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: Colors.white.withOpacity(0.20))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_on_rounded, color: AppColors.coral, size: 12),
            const SizedBox(width: 4),
            Text(widget.story.location, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ])),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        _metaChip(icon: Icons.access_time_rounded, label: widget.story.totalDuration),
        const SizedBox(width: 8),
        _metaChip(icon: Icons.place_rounded, label: '${widget.story.stopCount} stops'),
      ]),
      const SizedBox(height: 10),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: Row(children: widget.story.tags.map((tag) => Padding(padding: const EdgeInsets.only(right: 6), child: _tagPill(tag))).toList())),
    ]);
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: Colors.white.withOpacity(0.20))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.white.withOpacity(0.80)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ]));
  }

  Widget _tagPill(String tag) {
    final Color accent = {'Beach': AppColors.oceanMid, 'Temple': AppColors.gold, 'Food': AppColors.coral, 'Nature': AppColors.green, 'Hiking': AppColors.green, 'Sunset': const Color(0xFFE8A020), 'Night': const Color(0xFF9B59B6), 'Culture': AppColors.gold, 'Chill': AppColors.oceanMid, 'Scenic': const Color(0xFFE8A020), 'Couples': AppColors.coral, 'Local': AppColors.green, 'Market': const Color(0xFFE8A020), 'Wildlife': AppColors.green, 'Photography': AppColors.gold}[tag] ?? AppColors.text3;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: accent.withOpacity(0.20), borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: accent.withOpacity(0.45))),
      child: Text(tag, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: accent)));
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap; final bool active; final Color? activeColor;
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.active = false, this.activeColor});
  @override
  Widget build(BuildContext context) {
    final Color iconCol = active ? (activeColor ?? Colors.white) : Colors.white;
    return GestureDetector(onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(duration: const Duration(milliseconds: 200), width: 46, height: 46,
          decoration: BoxDecoration(color: active ? Colors.white.withOpacity(0.20) : Colors.black.withOpacity(0.35), shape: BoxShape.circle,
            border: Border.all(color: active ? (activeColor ?? Colors.white).withOpacity(0.60) : Colors.white.withOpacity(0.20), width: 1.5)),
          child: Icon(icon, color: iconCol, size: 22)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: iconCol, shadows: const [Shadow(color: Color(0x80000000), blurRadius: 4)])),
      ]));
  }
}

class _ItineraryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ItineraryButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.oceanDeep, AppColors.oceanMid]),
            shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.oceanDeep.withOpacity(0.50), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Icon(Icons.route_rounded, color: Colors.white, size: 22)),
        const SizedBox(height: 4),
        Text('Itinerary', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, shadows: const [Shadow(color: Color(0x80000000), blurRadius: 4)])),
      ]));
  }
}

// ══════════════════════════════════════════════════════════════
// ITINERARY SHEET — StatefulWidget so Follow btn updates
// ══════════════════════════════════════════════════════════════
class _ItinerarySheet extends StatefulWidget {
  final StoryVlog story;
  const _ItinerarySheet({required this.story});
  @override
  State<_ItinerarySheet> createState() => _ItinerarySheetState();
}

class _ItinerarySheetState extends State<_ItinerarySheet> {
  late bool _followed;

  @override
  void initState() {
    super.initState();
    _followed = AppStore.isTripFollowed(widget.story.id);
  }

  void _onFollowTap() {
    if (!_followed) {
      AppStore.followTrip(StoredTrip(
        id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
        name: widget.story.title,
        totalDuration: widget.story.totalDuration,
        stops: widget.story.stops.map((s) => StoredTripStop(name: s.name, type: s.type, duration: s.duration, distance: s.distance)).toList(),
        sourceVlogId: widget.story.id,
      ));
      setState(() => _followed = true);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(
          _followed && AppStore.isTripFollowed(widget.story.id)
              ? '"${widget.story.title}" added to Trips as Draft'
              : '"${widget.story.title}" is already in your Trips',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    return DraggableScrollableSheet(initialChildSize: 0.60, minChildSize: 0.40, maxChildSize: 0.88,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.only(topLeft: Radius.circular(AppRadius.xl), topRight: Radius.circular(AppRadius.xl))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 4), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(story.title, style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text1)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: AppColors.text3),
                  const SizedBox(width: 4),
                  Text(story.totalDuration, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.text2)),
                  const SizedBox(width: 10),
                  const Icon(Icons.place_rounded, size: 12, color: AppColors.text3),
                  const SizedBox(width: 4),
                  Text('${story.stopCount} stops', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.text2)),
                ]),
              ])),
              GestureDetector(
                onTap: _onFollowTap,
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: _followed ? null : const LinearGradient(colors: [AppColors.oceanDeep, AppColors.oceanMid]),
                    color: _followed ? AppColors.green : null,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: [BoxShadow(color: (_followed ? AppColors.green : AppColors.oceanDeep).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Text(_followed ? 'Following ✓' : 'Follow Trip',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ])),
          Container(height: 1, color: AppColors.borderLight),
          Expanded(child: ListView.builder(controller: scrollCtrl, padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: story.stops.length,
            itemBuilder: (_, i) => _buildStopRow(i, story.stops[i], story.stops.length))),
        ]),
      ));
  }

  Widget _buildStopRow(int index, ItineraryStop stop, int total) {
    final isLast  = index == total - 1;
    final isFirst = index == 0;
    final dotColor = isFirst ? AppColors.green : isLast ? AppColors.gold : AppColors.oceanDeep;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 32, child: Column(children: [
          const SizedBox(height: 14),
          Container(width: 14, height: 14, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: dotColor.withOpacity(0.40), blurRadius: 6, spreadRadius: 1)])),
          if (!isLast) Expanded(child: Container(width: 2, color: AppColors.borderLight)),
        ])),
        Expanded(child: Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 8),
          child: Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.borderLight)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(stop.name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text1)),
                const SizedBox(height: 4),
                Row(children: [
                  _sheetChip(icon: Icons.access_time_rounded, label: stop.duration),
                  const SizedBox(width: 6),
                  _sheetChip(icon: stop.distance == 'Start' ? Icons.flag_rounded : Icons.directions_walk_rounded, label: stop.distance),
                ]),
              ])),
              Container(width: 28, height: 28,
                decoration: BoxDecoration(color: dotColor.withOpacity(0.12), shape: BoxShape.circle, border: Border.all(color: dotColor.withOpacity(0.30))),
                child: Center(child: Text('${index + 1}', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: dotColor)))),
            ])))),
      ]));
  }

  Widget _sheetChip({required IconData icon, required String label}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: AppColors.text2),
        const SizedBox(width: 3),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text2)),
      ]));
  }
}
