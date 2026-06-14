import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/screen5_home.dart' show HomeScreen;
import '../screens/screen14_explore.dart' show ExploreScreen;
import '../screens/screen11_trips.dart' show TripsScreen;
import '../screens/screen12_profile.dart' show ProfileScreen;
import '../screens/screen7_generateItinerary.dart' show GenerateItineraryScreen;

class AppBottomNav extends StatefulWidget {
  /// 0 = Home, 1 = Explore, 3 = Trips, 4 = Profile
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  static const _oceanDeep = Color(0xFF0A7FAB);
  static const _oceanMid = Color(0xFF1AAECF);
  static const _oceanTint = Color(0xFFEAF8FD);
  static const _text3 = Color(0xFF9AB0B8);

  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (index == widget.currentIndex) return;
    late final Widget target;
    switch (index) {
      case 0: target = const HomeScreen(); break;
      case 1: target = const ExploreScreen(); break;
      case 3: target = const TripsScreen(); break;
      case 4: target = const ProfileScreen(); break;
      default: return;
    }
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => target), (r) => false);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => target));
    }
  }

  void _onPlanTap() {
    _spin.forward(from: 0); // 360° spin plays during the push transition
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GenerateItineraryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // ↓ bottom gap from screen edge. Lower this number if the bar sits too high.
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Glass bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55), // translucency
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A1F28).withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _navItem(0, Icons.home_rounded, 'Home')),
                    Expanded(
                        child: _navItem(1, Icons.explore_rounded, 'Explore')),
                    const SizedBox(width: 56), // gap for floating PLAN button
                    Expanded(child: _navItem(3, Icons.map_rounded, 'Trips')),
                    Expanded(
                        child: _navItem(4, Icons.person_rounded, 'Profile')),
                  ],
                ),
              ),
            ),
          ),
          // ── Floating PLAN button (spins on tap) ──
          Positioned(
            top: -20, // ↑ how far the button pokes above the bar. Raise toward
                      //   -14 if it sits too high.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: _spin,
                  child: GestureDetector(
                    onTap: _onPlanTap,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_oceanDeep, _oceanMid],
                        ),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _oceanDeep.withOpacity(0.45),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          size: 24, color: Colors.white),
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
                    color: _oceanDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = index == widget.currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _go(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: active ? _oceanTint : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: active ? _oceanDeep : _text3),
                const SizedBox(height: 3),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: active ? _oceanDeep : _text3,
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