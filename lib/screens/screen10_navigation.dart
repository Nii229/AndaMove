// ============================================================
// AndaMove — Navigation Screen
// File: lib/screens/screen10_navigation.dart
//
// Changes from previous version:
//   1. Back button navigates to screen8_itineraryResult (Navigator.pop)
//   2. Map layers button removed; title pill stays centred via SizedBox placeholder
//   3. "Next Stop" advances through _steps list and updates the instruction card
//   4. "End Trip" shows a confirmation bottom sheet then pushes screen11_trips
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screen11_trips.dart';
import '../app_store.dart';

// ══════════════════════════════════════════════════════════════
// STEP 1 — COLOR TOKENS
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
  static const Color bg = Color(0xFFFBF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF5F1EB);
  static const Color border = Color(0xFFE6DDD1);
  static const Color borderLight = Color(0xFFF0EBE2);
  static const Color text1 = Color(0xFF0A1E28);
  static const Color text2 = Color(0xFF5A7A8A);
  static const Color text3 = Color(0xFF9AB0B8);

  static const Color mapBase = Color(0xFF0A2030);
  static const Color mapOverlay = Color(0xFF061520);
}

// ══════════════════════════════════════════════════════════════
// STEP 2 — RADIUS & SHADOW TOKENS
// ══════════════════════════════════════════════════════════════
class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 9999;
}

BoxShadow get shadowOcean => const BoxShadow(
  color: Color(0x400A7FAB),
  blurRadius: 20,
  offset: Offset(0, 8),
);

// ══════════════════════════════════════════════════════════════
// STEP 3 — SHEEN PAINTER
// ══════════════════════════════════════════════════════════════
class SheenPainter extends CustomPainter {
  final double progress;
  SheenPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final double sweep = size.width * 0.35;
    final double x = -sweep + (size.width + sweep * 2) * progress;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, sweep, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0),
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromLTWH(x, 0, sweep, size.height)),
    );
  }

  @override
  bool shouldRepaint(SheenPainter o) => o.progress != progress;
}

// ══════════════════════════════════════════════════════════════
// STEP 4 — MAP BACKGROUND PAINTER
// ══════════════════════════════════════════════════════════════
class MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.28),
      120,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF0A7FAB).withOpacity(0.22),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.5, size.height * 0.28),
                radius: 120,
              ),
            ),
    );

    final grid = Paint()
      ..color = const Color(0xFF1AAECF).withOpacity(0.06)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final road = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawRoad(Offset a, Offset b, double w, double op) {
      road.color = Colors.white.withOpacity(op);
      road.strokeWidth = w;
      canvas.drawLine(a, b, road);
    }

    drawRoad(
      Offset(0, size.height * .45),
      Offset(size.width, size.height * .45),
      3,
      .08,
    );
    drawRoad(
      Offset(size.width * .10, size.height * .65),
      Offset(size.width, size.height * .65),
      2,
      .05,
    );
    drawRoad(
      Offset(size.width * .35, 0),
      Offset(size.width * .35, size.height),
      3,
      .08,
    );
    drawRoad(
      Offset(size.width * .70, size.height * .20),
      Offset(size.width * .70, size.height),
      2,
      .05,
    );

    canvas.save();
    canvas.translate(0, size.height * .20);
    canvas.rotate(15 * math.pi / 180);
    drawRoad(Offset.zero, const Offset(200, 0), 2, .05);
    canvas.restore();
  }

  @override
  bool shouldRepaint(MapBackgroundPainter o) => false;
}

// ══════════════════════════════════════════════════════════════
// STEP 5 — ROUTE PATH PAINTER
// ══════════════════════════════════════════════════════════════
class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390;
    final sy = size.height / 380;

    final fullPath = Path()
      ..moveTo(148 * sx, 160 * sy)
      ..cubicTo(170 * sx, 150 * sy, 200 * sx, 155 * sy, 200 * sx, 155 * sy)
      ..cubicTo(240 * sx, 160 * sy, 260 * sx, 130 * sy, 310 * sx, 90 * sy);

    _dashed(
      canvas,
      fullPath,
      Paint()
        ..color = const Color(0xFF1AAECF).withOpacity(0.8)
        ..strokeWidth = 3 * sx
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
      6 * sx,
      3 * sx,
    );

    canvas.drawPath(
      Path()
        ..moveTo(148 * sx, 160 * sy)
        ..quadraticBezierTo(170 * sx, 150 * sy, 200 * sx, 155 * sy),
      Paint()
        ..color = const Color(0xFF1AAECF)
        ..strokeWidth = 3.5 * sx
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _dashed(Canvas c, Path path, Paint paint, double dash, double gap) {
    for (final m in path.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      while (dist < m.length) {
        final len = draw ? dash : gap;
        if (draw) c.drawPath(m.extractPath(dist, dist + len), paint);
        dist += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(RoutePainter o) => false;
}

// ══════════════════════════════════════════════════════════════
// STEP 6 — BEACON DOT PAINTER
// ══════════════════════════════════════════════════════════════
class BeaconDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = const Color(0xFF1AAECF).withOpacity(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, 8, Paint()..color = const Color(0xFF1AAECF));
  }

  @override
  bool shouldRepaint(BeaconDotPainter o) => false;
}

// ══════════════════════════════════════════════════════════════
// STEP 7 — NAV STEP DATA MODEL
// ══════════════════════════════════════════════════════════════
class _NavStep {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String action; // e.g. "Turn right onto"
  final String road; // e.g. "Karon–Kata Hill Rd"
  final String secondaryInfo; // shown under road name
  final String distance;
  final bool isDestination;

  const _NavStep({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.action,
    required this.road,
    required this.secondaryInfo,
    required this.distance,
    this.isDestination = false,
  });
}

// ══════════════════════════════════════════════════════════════
// STEP 8 — NAVIGATION SCREEN
// ══════════════════════════════════════════════════════════════
class NavigationScreen extends StatefulWidget {
  final String? tripId; // ← add this
  const NavigationScreen({super.key, this.tripId});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  // Beacon pulse: 2s repeat
  late final AnimationController _beaconCtrl;
  late final Animation<double> _beaconScale;
  late final Animation<double> _beaconOpacity;

  // Sheen: 4s repeat
  late final AnimationController _sheenCtrl;

  // FIX 3: track which step the user is currently on
  int _currentStepIndex = 0;

  // Step data (immutable)
  static const List<_NavStep> _steps = [
    _NavStep(
      icon: Icons.turn_right_rounded,
      iconColor: AppColors.oceanDeep,
      iconBg: AppColors.oceanTint,
      action: 'Turn right onto',
      road: 'Karon–Kata Hill Rd',
      secondaryInfo: 'Continue for 380 m',
      distance: '380 m',
    ),
    _NavStep(
      icon: Icons.turn_left_rounded,
      iconColor: AppColors.oceanDeep,
      iconBg: AppColors.oceanTint,
      action: 'Turn left at',
      road: 'Nakkerd Roundabout',
      secondaryInfo: 'Soi Nakkerd 1',
      distance: '1.2 km',
    ),
    _NavStep(
      icon: Icons.straight_rounded,
      iconColor: AppColors.oceanDeep,
      iconBg: AppColors.oceanTint,
      action: 'Continue straight uphill',
      road: 'Nakkerd Hill Access Road',
      secondaryInfo: 'Heading north',
      distance: '800 m',
    ),
    _NavStep(
      icon: Icons.flag_rounded,
      iconColor: AppColors.gold,
      iconBg: AppColors.goldTint,
      action: 'Arrive at',
      road: 'The Big Buddha',
      secondaryInfo: 'Stop 2 of 4 · Park at base',
      distance: 'Dest.',
      isDestination: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _beaconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _beaconScale = Tween<double>(
      begin: 1.0,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _beaconCtrl, curve: Curves.easeOut));
    _beaconOpacity = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _beaconCtrl, curve: Curves.easeOut));

    _sheenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _beaconCtrl.dispose();
    _sheenCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // FIX 3: advance to next step
  // ──────────────────────────────────────────────────────────
  void _onNextStop() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() => _currentStepIndex++);
    } else {
      // Already at destination — prompt user to end trip
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You\'ve reached your destination! Tap "End Trip" to finish.',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.gold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // FIX 4: End Trip confirmation bottom sheet
  // ──────────────────────────────────────────────────────────
  void _onEndTrip() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EndTripSheet(
        onConfirm: () {
          if (widget.tripId != null) {
            AppStore.completeTrip(widget.tripId!);
          }
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const TripsScreen()),
            (route) => false,
          );
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mapBase,
      body: Column(
        children: [
          _buildMapArea(),
          Expanded(child: _buildBottomSheet()),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // MAP AREA
  // ══════════════════════════════════════════════════════════
  Widget _buildMapArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const mapH = 356.0;
        return SizedBox(
          width: w,
          height: mapH,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF071520),
                        Color(0xFF0A2535),
                        Color(0xFF0A4060),
                        Color(0xFF0A6080),
                      ],
                      stops: [0, .4, .7, 1],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: MapBackgroundPainter()),
              ),
              Positioned.fill(child: CustomPaint(painter: RoutePainter())),
              _mapPin(
                top: mapH * 0.55,
                left: w * 0.36,
                bg: AppColors.green,
                icon: Icons.flag_rounded,
                label: 'Kata',
                labelColor: Colors.white.withOpacity(0.9),
              ),
              _mapPin(
                top: mapH * 0.28,
                left: w * 0.56,
                bg: AppColors.gold,
                icon: Icons.temple_buddhist_rounded,
                label: 'Big Buddha',
                labelColor: AppColors.goldLight,
              ),
              _mapPin(
                top: mapH * 0.20,
                left: w * 0.72,
                bg: Colors.white.withOpacity(0.10),
                border: Colors.white.withOpacity(0.25),
                icon: Icons.account_balance_rounded,
                iconColor: AppColors.text3,
                label: 'Chalong',
                labelColor: AppColors.text3,
              ),
              _buildBeacon(top: mapH * 0.42, left: w * 0.38),
              _buildMapTopControls(),
              // Progress bar — advances with _currentStepIndex
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 4,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (_currentStepIndex + 1) * 25,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.oceanDeep, AppColors.oceanMid],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 100 - (_currentStepIndex + 1) * 25,
                        child: Container(color: Colors.white.withOpacity(0.10)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mapPin({
    required double top,
    required double left,
    required Color bg,
    Color? border,
    required IconData icon,
    Color iconColor = Colors.white,
    required String label,
    required Color labelColor,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: border != null
                  ? Border.all(color: border, width: 1.5)
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          Container(
            width: 2,
            height: 7,
            decoration: BoxDecoration(
              color: border ?? bg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(1),
                bottomRight: Radius.circular(1),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.50),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeacon({required double top, required double left}) {
    return Positioned(
      top: top,
      left: left,
      child: SizedBox(
        width: 40,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: Text(
                'You',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.oceanMid,
                  shadows: const [
                    Shadow(color: Color(0x99000000), blurRadius: 4),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              child: AnimatedBuilder(
                animation: _beaconCtrl,
                builder: (_, __) => Opacity(
                  opacity: _beaconOpacity.value,
                  child: Transform.scale(
                    scale: _beaconScale.value,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.oceanMid, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              child: CustomPaint(
                size: const Size(20, 20),
                painter: BeaconDotPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FIX 1: back navigates to previous screen
  // ── FIX 2: layers button removed; SizedBox placeholder keeps title centred
  Widget _buildMapTopControls() {
    return Positioned(
      top: 10,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // FIX 1 — back button with Navigator.pop
          _frostedMapBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mapOverlay.withOpacity(0.85),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'To: The Big Buddha',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Stop 2 of 4',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.50),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // FIX 2 — same width as the removed layers button to keep title centred
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _frostedMapBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.mapOverlay.withOpacity(0.85),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BOTTOM SHEET
  // ══════════════════════════════════════════════════════════
  Widget _buildBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildCurrentStep(),
          _buildEtaStrip(),
          Expanded(child: _buildStepsList()),
          _buildNavControls(),
        ],
      ),
    );
  }

  // ── FIX 3: current instruction card reads from _currentStepIndex
  Widget _buildCurrentStep() {
    final step = _steps[_currentStepIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(_currentStepIndex),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: step.isDestination
                      ? [AppColors.gold, AppColors.goldLight]
                      : [AppColors.oceanDeep, AppColors.oceanMid],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [shadowOcean],
              ),
              child: Icon(step.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.action,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text1,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.road,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.text2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              step.distance,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: step.isDestination
                    ? AppColors.gold
                    : AppColors.oceanDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEtaStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.oceanTint,
        border: Border(
          bottom: BorderSide(color: AppColors.oceanDeep.withOpacity(0.12)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _etaItem('12 min', 'To Arrive'),
          Container(
            width: 1,
            height: 32,
            color: AppColors.oceanDeep.withOpacity(0.20),
          ),
          _etaItem('2.4 km', 'Remaining'),
          Container(
            width: 1,
            height: 32,
            color: AppColors.oceanDeep.withOpacity(0.20),
          ),
          _etaItem('10:54', 'ETA'),
        ],
      ),
    );
  }

  Widget _etaItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.oceanDeep,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.text3,
          ),
        ),
      ],
    );
  }

  Widget _buildStepsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _steps.length,
      itemBuilder: (_, i) {
        final s = _steps[i];
        final isCurrent = i == _currentStepIndex;
        final isDone = i < _currentStepIndex;
        return Container(
          decoration: i == _steps.length - 1
              ? null
              : const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
                ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.oceanTint
                      : isCurrent
                      ? (s.isDestination
                            ? AppColors.goldTint
                            : AppColors.oceanTint)
                      : s.iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : s.icon,
                  size: 20,
                  color: isDone
                      ? AppColors.oceanDeep
                      : isCurrent
                      ? (s.isDestination ? AppColors.gold : AppColors.oceanDeep)
                      : s.iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.action} ${s.road}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDone
                            ? AppColors.text3
                            : s.isDestination
                            ? AppColors.gold
                            : isCurrent
                            ? AppColors.oceanDeep
                            : AppColors.text1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      s.secondaryInfo,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.oceanTint
                      : s.isDestination
                      ? AppColors.goldTint
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isDone ? '✓' : s.distance,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? AppColors.oceanDeep
                        : s.isDestination
                        ? AppColors.gold
                        : AppColors.text2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── FIX 3 & 4: wired up onTap handlers
  Widget _buildNavControls() {
    final isLastStep = _currentStepIndex == _steps.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          // FIX 4 — End Trip opens confirmation sheet
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: _onEndTrip,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.coralTint,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.coral, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.stop_circle_rounded,
                      color: AppColors.coral,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'End Trip',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // FIX 3 — Next Stop advances the step; shows "Arrived" at last step
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: _sheenCtrl,
              builder: (_, __) => GestureDetector(
                onTap: _onNextStop,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLastStep
                          ? [AppColors.gold, AppColors.goldLight]
                          : [AppColors.oceanDeep, AppColors.oceanMid],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: [shadowOcean],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: SheenPainter(_sheenCtrl.value),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _onNextStop,
                            splashColor: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize
                                    .min, // ← shrink-wrap so Center can actually center it
                                children: [
                                  const Icon(
                                    Icons.navigation_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Next Stop',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
// END TRIP CONFIRMATION BOTTOM SHEET  (FIX 4)
// ══════════════════════════════════════════════════════════════
class _EndTripSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _EndTripSheet({required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.coralTint,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.coral.withOpacity(0.30),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.stop_circle_rounded,
              color: AppColors.coral,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'End This Trip?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Your progress will be saved and you\'ll\nbe returned to My Trips.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.text2,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stop_circle_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Yes, End Trip',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text1,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              child: Text(
                'Keep Navigating',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
