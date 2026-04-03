// ============================================================
// AndaMove — Login Screen
// File: lib/screens/screen2_login.dart
//
// UPDATED: Added admin email detection.
//   If email == 'admin@andamove.com' → AdminDashboardScreen
//   Otherwise → tourist HomeScreen (default behaviour)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screen3_register.dart';
import 'screen4_forgotPassword.dart';
import 'screen5_home.dart';

// ── Admin screen import for routing ──
import '../admin/screens/adminScreen1_analyticsDashboard.dart';

// ── COLOR TOKENS ─────────────────────────────────────────────
class AppColors {
  static const Color oceanDeep = Color(0xFF0A7FAB);
  static const Color oceanMid  = Color(0xFF1AAECF);
  static const Color oceanTint = Color(0xFFEAF8FD);
  static const Color gold      = Color(0xFFC8912E);
  static const Color goldLight = Color(0xFFF0C060);
  static const Color coral     = Color(0xFFE8634C);
  static const Color bg        = Color(0xFFFBF8F3);
  static const Color surface   = Color(0xFFFFFFFF);
  static const Color surface2  = Color(0xFFF5F1EB);
  static const Color border    = Color(0xFFE6DDD1);
  static const Color text1     = Color(0xFF0A1E28);
  static const Color text2     = Color(0xFF5A7A8A);
  static const Color text3     = Color(0xFF9AB0B8);
}

class AppRadius {
  static const double sm   = 8;
  static const double md   = 14;
  static const double lg   = 20;
  static const double xl   = 28;
  static const double full = 999;
}

List<BoxShadow> get shadowSm => [
  BoxShadow(color: const Color(0xFF0A1F28).withOpacity(0.06),
      blurRadius: 3, offset: const Offset(0, 1)),
  BoxShadow(color: const Color(0xFF0A1F28).withOpacity(0.04),
      blurRadius: 2, offset: const Offset(0, 1)),
];

List<BoxShadow> get shadowOcean => [
  BoxShadow(color: AppColors.oceanDeep.withOpacity(0.28),
      blurRadius: 24, offset: const Offset(0, 8)),
];

// ── Admin email constant ──
const String _adminEmail = 'admin@andamove.com';

// ============================================================
// MAIN SCREEN WIDGET
// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _obscurePass  = true;

  late final AnimationController _sheenCtrl;
  late final Animation<double>   _sheenAnim;

  @override
  void initState() {
    super.initState();
    _sheenCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _sheenAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _sheenCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _sheenCtrl.dispose();
    super.dispose();
  }

  // ── LOGIN HANDLER (checks admin vs tourist) ──────────────
  void _handleLogin() {
    final email = _emailCtrl.text.trim().toLowerCase();

    if (email == _adminEmail) {
      // ═══ ADMIN ROUTE ═══
      // pushAndRemoveUntil clears the nav stack so the admin
      // can't swipe-back to the login screen.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen()),
        (_) => false,
      );
    } else {
      // ═══ TOURIST ROUTE (default) ═══
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildHeroPanel(),
          Expanded(child: _buildFormPanel()),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HERO PANEL
  // ══════════════════════════════════════════════════════════
  Widget _buildHeroPanel() {
    const double heroH = 340;

    return SizedBox(
      height: heroH,
      child: Stack(
        children: [
          // ① Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.3, -1.0),
                  end:   Alignment( 0.3,  1.0),
                  stops: [0.0, 0.4, 0.8, 1.0],
                  colors: [
                    Color(0xFF061018),
                    Color(0xFF082234),
                    Color(0xFF0A5C85),
                    Color(0xFF0A7FAB),
                  ],
                ),
              ),
            ),
          ),

          // ② Star dots
          const Positioned.fill(
            child: CustomPaint(painter: HeroStarsPainter()),
          ),

          // ③ Gold glow
          Positioned(
            top: 0, bottom: 80, left: 0, right: 0,
            child: Center(
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withOpacity(0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.65],
                  ),
                ),
              ),
            ),
          ),

          // ④ Horizon shimmer line
          Positioned(
            top: heroH * 0.72,
            left: 0, right: 0,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0x4DC8912E),
                    Color(0x99F0C060),
                    Color(0x4DC8912E),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // ⑤ Brand block — pinned from top
          Positioned(
            top: 30,
            left: 0, right: 0,
            child: _buildHeroBrand(),
          ),

          // ⑥ Wave cutout
          Positioned(
            bottom: -20,
            left: -MediaQuery.of(context).size.width * 0.05,
            right: -MediaQuery.of(context).size.width * 0.05,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.elliptical(9999, 60),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero brand ──────────────────────────────────────────
  Widget _buildHeroBrand() {
    final baseStyle = GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: 0.7,
      height: 1.5,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 0.78,
            child: Image.asset(
              'assets/images/andamove_logo.png',
              width: 150,
              height: 150,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),

        Transform.translate(
          offset: const Offset(0, -8),
          child: Row(
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
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                  colors: [AppColors.goldLight, AppColors.gold],
                ).createShader(bounds),
                child: Text('Move', style: baseStyle),
              ),
            ],
          ),
        ),

        Transform.translate(
          offset: const Offset(0, -6),
          child: Text(
            'PHUKET · THAILAND',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.45),
              letterSpacing: 1.92,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // FORM PANEL
  // ══════════════════════════════════════════════════════════
  Widget _buildFormPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormHeading(),
          const SizedBox(height: 24),
          _buildFieldLabel('Email Address'),
          const SizedBox(height: 5),
          _buildEmailField(),
          const SizedBox(height: 14),
          _buildPasswordLabelRow(),
          const SizedBox(height: 5),
          _buildPasswordField(),
          const SizedBox(height: 20),
          _buildCtaButton(),
          const SizedBox(height: 20),
          _buildRegisterRow(),
        ],
      ),
    );
  }

  Widget _buildFormHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: 26, fontWeight: FontWeight.w700,
              color: AppColors.text1, height: 1.2,
            ),
            children: const [
              TextSpan(text: 'Welcome back,\n'),
              TextSpan(text: 'Explorer.',
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('Sign in to continue your journey',
            style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.text2)),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.text1, letterSpacing: 0.24));
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.outfit(fontSize: 15,
          fontWeight: FontWeight.w500, color: AppColors.text1),
      decoration: _fieldDecoration(
          hint: 'you@example.com',
          prefixIcon: Icons.mail_outline_rounded),
    );
  }

  Widget _buildPasswordLabelRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFieldLabel('Password'),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const ForgotPasswordScreen())),
          child: Text('Forgot password?',
              style: GoogleFonts.outfit(fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 0.24)),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePass,
      style: GoogleFonts.outfit(fontSize: 15,
          fontWeight: FontWeight.w500, color: AppColors.text1),
      decoration: _fieldDecoration(
        hint: '••••••••',
        prefixIcon: Icons.lock_outline_rounded,
        suffix: GestureDetector(
          onTap: () =>
              setState(() => _obscurePass = !_obscurePass),
          child: Icon(
            _obscurePass
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: AppColors.text3,
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String   hint,
    required IconData prefixIcon,
    Widget?           suffix,
  }) {
    const border = OutlineInputBorder(
      borderRadius:
          BorderRadius.all(Radius.circular(AppRadius.md)),
      borderSide:
          BorderSide(color: AppColors.border, width: 1.5),
    );
    const focusBorder = OutlineInputBorder(
      borderRadius:
          BorderRadius.all(Radius.circular(AppRadius.md)),
      borderSide:
          BorderSide(color: AppColors.oceanDeep, width: 1.5),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.text3),
      prefixIcon:
          Icon(prefixIcon, size: 19, color: AppColors.text3),
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 14),
              child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(
              horizontal: 14, vertical: 15),
      enabledBorder:      border,
      focusedBorder:      focusBorder,
      errorBorder:        border,
      focusedErrorBorder: focusBorder,
    );
  }

  // ── CTA BUTTON — now calls _handleLogin() ──────────────
  Widget _buildCtaButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end:   Alignment.centerRight,
          colors: [AppColors.oceanDeep, AppColors.oceanMid],
        ),
        boxShadow: shadowOcean,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: _handleLogin,  // ← CHANGED: was inline Navigator.push
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Continue to Adventure',
                    style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.64)),
                const SizedBox(width: 8),
                const Icon(Icons.explore_rounded,
                    color: Colors.white, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterRow() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.outfit(
              fontSize: 13, color: AppColors.text2),
          children: [
            const TextSpan(text: 'New to AndaMove?  '),
            TextSpan(
              text: 'Create account →',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.oceanDeep),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const RegisterScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════
class HeroStarsPainter extends CustomPainter {
  const HeroStarsPainter();

  static const _stars = [
    (Offset( 60,  50), 0.75, 0.50),
    (Offset(200,  30), 0.50, 0.40),
    (Offset(320,  70), 0.50, 0.30),
    (Offset( 80, 130), 0.75, 0.35),
    (Offset(280, 110), 0.50, 0.40),
    (Offset(140, 160), 0.50, 0.25),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      canvas.drawCircle(
          s.$1, s.$2,
          Paint()..color = Colors.white.withOpacity(s.$3));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}