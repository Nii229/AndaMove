import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screen2_login.dart';

class AppColors {
  static const Color oceanDeep = Color(0xFF0A7FAB);
  static const Color oceanMid = Color(0xFF1AAECF);
  static const Color gold = Color(0xFFC8912E);
  static const Color goldLight = Color(0xFFF0C060);
  static const Color coral = Color(0xFFE8634C);
  static const Color bgDark = Color(0xFF071520);
  static const Color bgDeepest = Color(0xFF061018);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final AnimationController _waveCtrl;
  late final AnimationController _sparkleCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _btnGlowCtrl;
  late final AnimationController _progressCtrl;

  late final Animation<double> _sparkleAnim;
  late final Animation<double> _btnGlowAnim;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _sparkleAnim = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _sparkleCtrl, curve: Curves.easeInOut),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _btnGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _btnGlowAnim = Tween<double>(begin: 0.5, end: 0.85).animate(
      CurvedAnimation(parent: _btnGlowCtrl, curve: Curves.easeInOut),
    );

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _progressCtrl.forward();

    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _waveCtrl.dispose();
    _sparkleCtrl.dispose();
    _shimmerCtrl.dispose();
    _btnGlowCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeepest,
      body: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    return Stack(
      children: [
        _buildBackground(),
        _buildStars(),
        _buildGoldGlow(),
        _buildOceanGlow(),
        _buildHorizon(),
        _buildWaves(),
        _buildSparkles(),
        _buildContent(),
      ],
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.0, -1.0),
          end: Alignment(0.09, 1.0),
          stops: [0.0, 0.20, 0.50, 0.75, 1.0],
          colors: [
            Color(0xFF061018),
            Color(0xFF082030),
            Color(0xFF0A3D5C),
            Color(0xFF0A6A95),
            Color(0xFF0D8FB8),
          ],
        ),
      ),
    );
  }

  Widget _buildStars() {
    return const Positioned.fill(
      child: CustomPaint(painter: StarsPainter()),
    );
  }

  Widget _buildGoldGlow() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.18,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.gold.withOpacity(0.18),
                AppColors.gold.withOpacity(0.06),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.7],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOceanGlow() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 500,
          height: 300,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppColors.oceanMid.withOpacity(0.15),
                Colors.transparent,
              ],
              stops: const [0.0, 0.65],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizon() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.38,
      left: 0,
      right: 0,
      child: Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Color(0x40C8912E),
              Color(0x80F0C060),
              Color(0x40C8912E),
              Colors.transparent,
            ],
            stops: [0.0, 0.3, 0.5, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildWaves() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.42,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) {
                final dx = Curves.easeInOut.transform(_waveCtrl.value) * -0.03;
                return Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.42 * 0.58,
                  left: -MediaQuery.of(context).size.width * 0.1 +
                      dx * MediaQuery.of(context).size.width,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 1.2,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.oceanDeep.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _waveCtrl,
              builder: (_, __) {
                final dx =
                    (1 - Curves.easeInOut.transform(_waveCtrl.value)) * -0.03;
                return Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.42 * 0.48,
                  left: -MediaQuery.of(context).size.width * 0.1 +
                      dx * MediaQuery.of(context).size.width,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 1.2,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.oceanDeep.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xF2061018),
                      Color(0x660A3F5C),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkles() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.33,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _sparkleAnim,
        builder: (_, __) {
          return Transform.translate(
            offset: Offset(0, _sparkleAnim.value),
            child: Opacity(
              opacity: 0.7 + (_sparkleAnim.value / -4) * 0.3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(9, (i) {
                  final isEven = i.isEven;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 9),
                    width: isEven ? 3 : 4,
                    height: isEven ? 3 : 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          AppColors.goldLight.withOpacity(isEven ? 0.35 : 0.7),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldLight.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── FIX 2: hero centered in upper half, bottom card pinned ──
  Widget _buildContent() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildHero(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 52),
            child: _buildBottom(),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogoRing(),
        const SizedBox(height: 24),
        _buildBrandName(),
        const SizedBox(height: 10),
        _buildTagline(),
        const SizedBox(height: 16),
        _buildOrnament(),
        const SizedBox(height: 4),
        _buildFeaturePills(),
      ],
    );
  }

  Widget _buildLogoRing() {
  return SizedBox(
    width: 150,        // ← was 96
    height: 150,       // ← was 96
    child: AnimatedBuilder(
      animation: _ringCtrl,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: _ringCtrl.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(134, 134),   // ← was 100
                painter: ConicRingPainter(),
              ),
            ),
            Container(
              width: 124,                     // ← was 88
              height: 124,                    // ← was 88
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xE6061826),
              ),
            ),
            Image.asset(
              'assets/images/andamove_logo.png',
              width: 130,                      // ← was 150 (was being clipped)
              height: 130,                     // ← was 150
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
          ],
        );
      },
    ),
  );
}

  // ── FIX 1: baseline-aligned Row instead of RichText + WidgetSpan ──
  Widget _buildBrandName() {
    final baseStyle = GoogleFonts.playfairDisplay(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      letterSpacing: 0.5,
      height: 1,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'Anda',
          style: baseStyle.copyWith(
            shadows: [
              Shadow(
                color: AppColors.gold.withOpacity(0.3),
                blurRadius: 40,
              ),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.goldLight, AppColors.gold],
          ).createShader(bounds),
          child: Text('Move', style: baseStyle),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      'PHUKET · THAILAND',
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.5),
        letterSpacing: 2.6,
      ),
    );
  }

  Widget _buildOrnament() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0x80C8912E)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x80C8912E), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePills() {
    final pills = [
      (Icons.beach_access_rounded, 'Beaches'),
      (Icons.restaurant_rounded, 'Flavors'),
      (Icons.map_rounded, 'Routes'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pills.map((p) => _featPill(p.$1, p.$2)).toList(),
    );
  }

  Widget _featPill(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.goldLight),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.6),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return Column(
      children: [
        _buildLoadingCard(),
        const SizedBox(height: 14),
        _buildCtaButton(),
        const SizedBox(height: 14),
        _buildTerms(),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20).copyWith(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PREPARING ROUTES',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 1.4,
                  ),
                ),
                AnimatedBuilder(
                  animation: _progressCtrl,
                  builder: (_, __) => Text(
                    '${((_progressCtrl.value * 99) + 1).toInt()}%',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 3,
                child: AnimatedBuilder(
                  animation: _progressCtrl,
                  builder: (_, __) => Stack(
                    children: [
                      Container(color: Colors.white.withOpacity(0.10)),
                      FractionallySizedBox(
                        widthFactor: _progressCtrl.value,
                        child: AnimatedBuilder(
                          animation: _shimmerCtrl,
                          builder: (_, __) => ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin:
                                  Alignment(-1 + _shimmerCtrl.value * 4, 0),
                              end: Alignment(1 + _shimmerCtrl.value * 4, 0),
                              colors: const [
                                AppColors.gold,
                                AppColors.goldLight,
                                AppColors.gold,
                              ],
                            ).createShader(bounds),
                            child: Container(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mapping nearby attractions…',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaButton() {
    return const SizedBox.shrink();
  }

  Widget _buildTerms() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.outfit(
          fontSize: 10,
          color: Colors.white.withOpacity(0.25),
          letterSpacing: 0.4,
        ),
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          TextSpan(
            text: 'Terms',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              decoration: TextDecoration.underline,
            ),
          ),
          const TextSpan(text: ' & '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class StarsPainter extends CustomPainter {
  const StarsPainter();

  static const List<Offset> _positions = [
    Offset(80, 60),
    Offset(200, 40),
    Offset(300, 90),
    Offset(60, 160),
    Offset(340, 130),
    Offset(150, 200),
    Offset(260, 170),
    Offset(100, 240),
  ];

  static const List<double> _opacities = [
    0.5,
    0.4,
    0.3,
    0.4,
    0.5,
    0.2,
    0.35,
    0.25,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _positions.length; i++) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(_opacities[i]);
      final radius = i.isOdd ? 0.75 : 0.5;
      canvas.drawCircle(_positions[i], radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConicRingPainter extends CustomPainter {
  const ConicRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - 2.5;

    final paint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0xCCC8912E),
          Color(0x991AAECF),
          Color(0xCCC8912E),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawCircle(center, (outerRadius + innerRadius) / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}