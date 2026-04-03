// ============================================================
// AndaMove — Map View Screen
// File: lib/screens/screen9_mapView.dart
//
// Changes vs original:
//   • Search bar removed
//   • Filter button removed
//   • Full bottom sheet removed (active stop card, progress,
//     stop pills, Timeline button all gone)
//   • Only "Navigate Here" button remains — floating at bottom
//   • Navigate Here taps to screen10_navigation.dart
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screen10_navigation.dart';

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
  static const Color mapBg = Color(0xFF071520);
}

class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;
}

List<BoxShadow> get shadowOcean => [
  BoxShadow(
    color: AppColors.oceanDeep.withOpacity(0.30),
    blurRadius: 20,
    offset: const Offset(0, 8),
  ),
];

// ══════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════
enum StopState { done, current, upcoming }

class _MapStop {
  final StopState state;
  final String number;
  final String label;
  final double bottom;
  final double left;
  const _MapStop({
    required this.state,
    required this.number,
    required this.label,
    required this.bottom,
    required this.left,
  });
}

class _TitleStop {
  final String number;
  final Color dotColor;
  final String name;
  final bool isDone;
  const _TitleStop(
    this.number,
    this.dotColor,
    this.name, {
    this.isDone = false,
  });
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});
  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen>
    with TickerProviderStateMixin {
  late final AnimationController _beaconCtrl;
  late final Animation<double> _beaconScale;
  late final Animation<double> _beaconOpacity;
  late final AnimationController _sheenCtrl;
  late final Animation<double> _sheenAnim;

  static const _stops = [
    _MapStop(
      state: StopState.done,
      number: '✓',
      label: 'Kata Beach',
      bottom: 0.35,
      left: 0.30,
    ),
    _MapStop(
      state: StopState.current,
      number: '2',
      label: 'Big Buddha 📍',
      bottom: 0.47,
      left: 0.49,
    ),
    _MapStop(
      state: StopState.upcoming,
      number: '3',
      label: 'Wat Chalong',
      bottom: 0.60,
      left: 0.66,
    ),
    _MapStop(
      state: StopState.upcoming,
      number: '4',
      label: 'Old Town',
      bottom: 0.68,
      left: 0.78,
    ),
  ];

  static const _titleStops = [
    _TitleStop('1', AppColors.green, 'Kata', isDone: true),
    _TitleStop('2', AppColors.gold, 'Big Buddha'),
    _TitleStop('3', Color(0x1FFFFFFF), 'Chalong'),
    _TitleStop('4', Color(0x1AFFFFFF), 'Old Town'),
  ];

  static const _areaLabels = [
    ('PATONG', 0.20, 0.08, false),
    ('KARON', 0.35, 0.06, false),
    ('KATA', 0.52, 0.10, false),
    ('RAWAI', 0.15, 0.08, true),
    ('CHALONG', 0.28, 0.06, true),
    ('NAKKERD', 0.42, 0.08, true),
  ];

  @override
  void initState() {
    super.initState();
    _beaconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _beaconScale = Tween<double>(
      begin: 1.0,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _beaconCtrl, curve: Curves.easeOut));
    _beaconOpacity = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _beaconCtrl, curve: Curves.easeOut));
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
    _beaconCtrl.dispose();
    _sheenCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mapBg,
      body: Stack(
        children: [
          // Full-screen map
          Positioned.fill(child: _buildFullMap()),

          // Top bar — back button only (search + filter removed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 10),
                    _buildTripTitleCard(),
                  ],
                ),
              ),
            ),
          ),

          // Side controls
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(child: _buildSideControls()),
          ),

          // Navigate Here button — floating at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildNavigateHereButton(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FULL MAP
  // ══════════════════════════════════════════════════════════
  Widget _buildFullMap() {
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.3, -1),
                    end: Alignment(0.3, 1),
                    stops: [0.0, 0.30, 0.60, 0.85, 1.0],
                    colors: [
                      Color(0xFF071520),
                      Color(0xFF0A2535),
                      Color(0xFF0A3D5C),
                      Color(0xFF0A5878),
                      Color(0xFF0A7098),
                    ],
                  ),
                ),
              ),
            ),

            // Grid
            Positioned.fill(
              child: CustomPaint(
                painter: _MapGridPainter(spacing: 28, opacity: 0.04),
              ),
            ),

            // Atmospheric glows
            _glow(
              top: h * 0.25,
              left: w * 0.40,
              size: 260,
              color: AppColors.oceanDeep,
              opacity: 0.20,
            ),
            _glow(
              top: h * 0.50,
              right: w * 0.10,
              size: 180,
              color: AppColors.gold,
              opacity: 0.10,
            ),
            _glow(
              bottom: h * 0.20,
              left: w * 0.20,
              size: 200,
              color: AppColors.oceanMid,
              opacity: 0.08,
            ),

            // Area labels
            for (final lbl in _areaLabels)
              Positioned(
                top: h * lbl.$2,
                left: lbl.$4 ? null : w * lbl.$3,
                right: lbl.$4 ? w * lbl.$3 : null,
                child: Text(
                  lbl.$1,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
              ),

            // Route
            Positioned.fill(
              child: CustomPaint(
                painter: _MapViewRoutePainter(w: w, h: h),
              ),
            ),

            // Stop markers
            for (final stop in _stops) _buildStopMarker(stop, w, h),

            // Beacon
            Positioned(bottom: h * 0.42, left: w * 0.42, child: _buildBeacon()),
          ],
        );
      },
    );
  }

  Widget _glow({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required double opacity,
  }) => Positioned(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
          stops: const [0.0, 0.65],
        ),
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════
  // STOP MARKERS
  // ══════════════════════════════════════════════════════════
  Widget _buildStopMarker(_MapStop stop, double w, double h) {
    Color circleBg, textColor, tailColor, labelBg, labelText;
    Color? circleGlow, labelBorder;

    switch (stop.state) {
      case StopState.done:
        circleBg = AppColors.green;
        textColor = Colors.white;
        tailColor = AppColors.green;
        labelBg = const Color(0xB3061018);
        labelText = Colors.white.withOpacity(0.85);
      case StopState.current:
        circleBg = AppColors.gold;
        circleGlow = AppColors.gold;
        textColor = Colors.white;
        tailColor = AppColors.gold;
        labelBg = AppColors.goldTint;
        labelText = AppColors.gold;
        labelBorder = AppColors.gold.withOpacity(0.30);
      case StopState.upcoming:
        circleBg = Colors.white.withOpacity(0.12);
        textColor = Colors.white;
        tailColor = Colors.white.withOpacity(0.20);
        labelBg = const Color(0xB3061018);
        labelText = Colors.white.withOpacity(0.85);
    }

    return Positioned(
      bottom: h * stop.bottom,
      left: w * stop.left,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleBg,
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                if (circleGlow != null)
                  BoxShadow(
                    color: circleGlow.withOpacity(0.25),
                    spreadRadius: 6,
                    blurRadius: 0,
                  ),
              ],
            ),
            child: Center(
              child: Text(
                stop.number,
                style: GoogleFonts.outfit(
                  fontSize: stop.state == StopState.upcoming ? 12 : 13,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(
            width: 2,
            height: 7,
            decoration: BoxDecoration(
              color: tailColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(1),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: labelBg,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: labelBorder != null
                  ? Border.all(color: labelBorder)
                  : null,
            ),
            child: Text(
              stop.label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: labelText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BEACON
  // ══════════════════════════════════════════════════════════
  Widget _buildBeacon() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _beaconCtrl,
            builder: (_, __) => Transform.scale(
              scale: _beaconScale.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.oceanMid.withOpacity(
                      _beaconOpacity.value * 0.4,
                    ),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.oceanDeep, AppColors.oceanMid],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.oceanMid.withOpacity(0.20),
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.50),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin_circle_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: -22,
            child: Text(
              'You',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.oceanMid,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.80),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TOP BAR — back button only (search & filter removed)
  // ══════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF061010).withOpacity(0.85),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 19,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // TRIP TITLE CARD
  // ══════════════════════════════════════════════════════════
  Widget _buildTripTitleCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF061010).withOpacity(0.88),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phuket Cultural & Beach Day',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.oceanMid.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: AppColors.oceanMid.withOpacity(0.30),
                  ),
                ),
                child: Text(
                  'Stop 2 / 4',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.oceanMid,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(children: _buildTitleStopSequence()),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTitleStopSequence() {
    final widgets = <Widget>[];
    for (int i = 0; i < _titleStops.length; i++) {
      final stop = _titleStops[i];
      final textStyle = stop.isDone
          ? GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.40),
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.white.withOpacity(0.40),
            )
          : GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: i == 1
                  ? AppColors.goldLight
                  : Colors.white.withOpacity(0.70),
            );

      widgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stop.dotColor,
              ),
              child: Center(
                child: Text(
                  stop.number,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(stop.name, style: textStyle),
          ],
        ),
      );

      if (i < _titleStops.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '›',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white.withOpacity(0.30),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  // ══════════════════════════════════════════════════════════
  // SIDE CONTROLS
  // ══════════════════════════════════════════════════════════
  Widget _buildSideControls() {
    final frosted = BoxDecoration(
      color: const Color(0xFF061010).withOpacity(0.85),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: Colors.white.withOpacity(0.15)),
    );
    final active = BoxDecoration(
      color: AppColors.oceanDeep,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.oceanDeep),
    );

    Widget btn(IconData icon, {bool isActive = false}) => Container(
      width: 40,
      height: 40,
      decoration: isActive ? active : frosted,
      child: Icon(icon, size: 19, color: Colors.white),
    );

    Widget divider() => Container(
      width: 40,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: Colors.white.withOpacity(0.10),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.my_location_rounded, isActive: true),
        divider(),
        btn(Icons.add_rounded),
        const SizedBox(height: 8),
        btn(Icons.remove_rounded),
        divider(),
        btn(Icons.layers_rounded),
        const SizedBox(height: 8),
        btn(Icons.traffic_rounded),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // NAVIGATE HERE BUTTON — full width floating, wired to screen10
  // ══════════════════════════════════════════════════════════
  Widget _buildNavigateHereButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [0.60, 1.0],
          colors: [Color(0xCC071520), Colors.transparent],
        ),
      ),
      child: AnimatedBuilder(
        animation: _sheenAnim,
        builder: (_, child) => GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NavigationScreen()),
          ),
          child: Container(
            height: 54,
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
                'Navigatate Here',
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
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════
class _MapGridPainter extends CustomPainter {
  final double spacing;
  final double opacity;
  const _MapGridPainter({this.spacing = 30, this.opacity = 0.06});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1AAECF).withOpacity(opacity)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter old) => old.spacing != spacing;
}

class _MapViewRoutePainter extends CustomPainter {
  final double w;
  final double h;
  const _MapViewRoutePainter({required this.w, required this.h});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390;
    final sy = size.height / 600;

    final roadPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roads = [
      ('M0,290 Q100,280 200,270 Q280,260 390,250', 3.0, 0.06),
      ('M80,0 Q100,120 110,200 Q120,300 130,420 Q140,520 150,600', 2.5, 0.05),
      ('M220,0 Q230,100 240,200 Q250,310 260,420 Q265,510 270,600', 2.0, 0.05),
      ('M0,400 Q120,380 220,370 Q310,360 390,350', 2.0, 0.04),
      ('M40,100 Q80,150 120,180 Q170,210 220,200', 2.0, 0.04),
    ];
    for (final r in roads) {
      roadPaint
        ..strokeWidth = r.$2
        ..color = Colors.white.withOpacity(r.$3);
      canvas.drawPath(_scaledPath(r.$1, sx, sy), roadPaint);
    }

    // Coastline
    canvas.drawPath(
      _scaledPath(
        'M0,200 Q30,195 50,210 Q70,225 60,250 Q50,270 30,280 Q10,290 0,310',
        sx,
        sy,
      ),
      Paint()
        ..color = AppColors.oceanMid.withOpacity(0.15)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Done segment — glow + solid
    final donePts = [
      Offset(130 * sx, 430 * sy),
      Offset(155 * sx, 410 * sy),
      Offset(175 * sx, 380 * sy),
      Offset(195 * sx, 350 * sy),
      Offset(205 * sx, 310 * sy),
    ];
    canvas.drawPath(
      _polyline(donePts),
      Paint()
        ..color = AppColors.oceanMid.withOpacity(0.30)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      _polyline(donePts),
      Paint()
        ..color = AppColors.oceanMid
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    // Gold dashed — current to next
    _dashed(
      canvas,
      [
        Offset(205 * sx, 310 * sy),
        Offset(225 * sx, 270 * sy),
        Offset(250 * sx, 240 * sy),
        Offset(275 * sx, 210 * sy),
        Offset(295 * sx, 190 * sy),
      ],
      Paint()
        ..color = AppColors.gold.withOpacity(0.60)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
      dashLen: 7,
      gapLen: 4,
    );

    // Faint dashed — remaining
    _dashed(
      canvas,
      [
        Offset(295 * sx, 190 * sy),
        Offset(305 * sx, 170 * sy),
        Offset(310 * sx, 155 * sy),
        Offset(315 * sx, 138 * sy),
        Offset(320 * sx, 125 * sy),
      ],
      Paint()
        ..color = Colors.white.withOpacity(0.20)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
      dashLen: 5,
      gapLen: 4,
    );

    // Connector dots
    canvas.drawCircle(
      Offset(175 * sx, 380 * sy),
      3,
      Paint()..color = AppColors.oceanMid.withOpacity(0.50),
    );
    canvas.drawCircle(
      Offset(205 * sx, 310 * sy),
      3,
      Paint()..color = AppColors.gold.withOpacity(0.60),
    );
  }

  Path _scaledPath(String d, double sx, double sy) {
    final path = Path();
    final tokens = d.split(' ');
    String cmd = '';
    final nums = <double>[];
    for (final t in tokens) {
      if (RegExp(r'^[MQ]$').hasMatch(t)) {
        if (cmd == 'M' && nums.length >= 2) {
          path.moveTo(nums[0] * sx, nums[1] * sy);
        }
        nums.clear();
        cmd = t;
      } else {
        for (final s in t.split(',')) {
          if (s.isNotEmpty) nums.add(double.tryParse(s) ?? 0);
        }
        if (cmd == 'Q' && nums.length >= 6) {
          path.quadraticBezierTo(
            nums[nums.length - 4] * sx,
            nums[nums.length - 3] * sy,
            nums[nums.length - 2] * sx,
            nums[nums.length - 1] * sy,
          );
        }
      }
    }
    if (cmd == 'M' && nums.length >= 2) {
      path.moveTo(nums[0] * sx, nums[1] * sy);
    }
    return path;
  }

  Path _polyline(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) path.lineTo(pts[i].dx, pts[i].dy);
    return path;
  }

  void _dashed(
    Canvas canvas,
    List<Offset> pts,
    Paint paint, {
    required double dashLen,
    required double gapLen,
  }) {
    double accumulated = 0;
    bool drawing = true;
    for (int i = 1; i < pts.length; i++) {
      final segLen = (pts[i] - pts[i - 1]).distance;
      double segStart = 0;
      while (segStart < segLen) {
        final remaining = drawing ? dashLen : gapLen;
        final take = math.min(remaining - accumulated, segLen - segStart);
        final t1 = segStart / segLen;
        final t2 = (segStart + take) / segLen;
        if (drawing) {
          canvas.drawLine(
            Offset.lerp(pts[i - 1], pts[i], t1)!,
            Offset.lerp(pts[i - 1], pts[i], t2)!,
            paint,
          );
        }
        segStart += take;
        accumulated += take;
        if (accumulated >= remaining) {
          accumulated = 0;
          drawing = !drawing;
        }
      }
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
  bool shouldRepaint(_SheenPainter old) => old.position != position;
}
