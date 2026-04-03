// ============================================================
// AndaMove — Register Screen
// File: lib/screens/screen3_register.dart
//
// Hero panel updated to match screen2_login:
//   • Height 340px (was 220px)
//   • Vertical layout: logo on top → "AndaMove" → subtitle
//   • ClipRect logo crop + Transform.translate gap fix
//   • Same gold glow, horizon line, stars, wave cutout
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screen2_login.dart';

// ── COLOR TOKENS ─────────────────────────────────────────────
class AppColors {
  static const Color oceanDeep = Color(0xFF0A7FAB);
  static const Color oceanMid  = Color(0xFF1AAECF);
  static const Color gold      = Color(0xFFC8912E);
  static const Color goldLight = Color(0xFFF0C060);
  static const Color coral     = Color(0xFFE8634C);
  static const Color bg        = Color(0xFFFBF8F3);
  static const Color surface   = Color(0xFFFFFFFF);
  static const Color border    = Color(0xFFE6DDD1);
  static const Color text1     = Color(0xFF0A1E28);
  static const Color text2     = Color(0xFF5A7A8A);
  static const Color text3     = Color(0xFF9AB0B8);
}

class AppRadius {
  static const double sm   = 8;
  static const double md   = 14;
  static const double full = 999;
}

List<BoxShadow> get shadowSm => [
  BoxShadow(color: const Color(0xFF0A1F28).withOpacity(0.06),
      blurRadius: 3, offset: const Offset(0, 1)),
];
List<BoxShadow> get shadowOcean => [
  BoxShadow(color: AppColors.oceanDeep.withOpacity(0.28),
      blurRadius: 24, offset: const Offset(0, 8)),
];

enum PasswordStrength { none, weak, fair, strong, veryStrong }

PasswordStrength _evalStrength(String pw) {
  if (pw.isEmpty)    return PasswordStrength.none;
  if (pw.length < 6) return PasswordStrength.weak;
  final hasUpper  = pw.contains(RegExp(r'[A-Z]'));
  final hasDigit  = pw.contains(RegExp(r'\d'));
  final hasSymbol = pw.contains(RegExp(r'[!@#\$%^&*]'));
  final score     = [hasUpper, hasDigit, hasSymbol].where((b) => b).length;
  if (score == 0) return PasswordStrength.weak;
  if (score == 1) return PasswordStrength.fair;
  if (score == 2) return PasswordStrength.strong;
  return PasswordStrength.veryStrong;
}

// ============================================================
// MAIN SCREEN
// ============================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {

  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool    _obscurePass    = true;
  bool    _termsAccepted  = true;
  String? _selectedCountry;

  PasswordStrength get _strength => _evalStrength(_passwordCtrl.text);

  late final AnimationController _sheenCtrl;
  late final Animation<double>   _sheenAnim;

  final int _currentStep = 2;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() => setState(() {}));
    _sheenCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _sheenAnim = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _sheenCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _sheenCtrl.dispose();
    super.dispose();
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
  // HERO PANEL — now matches screen2_login exactly
  // 340px tall, vertical layout, ClipRect logo
  // ══════════════════════════════════════════════════════════
  Widget _buildHeroPanel() {
    const double heroH = 340;

    return SizedBox(
      height: heroH,
      child: Stack(
        children: [
          // ① Background gradient (identical to login)
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
            child: CustomPaint(painter: RegisterStarsPainter()),
          ),

          // ③ Gold glow (same as login — centered behind logo)
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

          // ⑤ Brand block — vertical, pinned from top (same as login)
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

  // ── Hero brand — vertical layout matching login ───────────
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
        // Logo with ClipRect to crop built-in whitespace
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

        // "AndaMove" pulled up to close the gap
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

        // Subtitle
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
      padding: const EdgeInsets.fromLTRB(28, 7, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormHeading(),
          const SizedBox(height: 14),
          _buildStepIndicator(),
          const SizedBox(height: 14),
          _buildFieldLabel('Full Name'),
          const SizedBox(height: 5),
          _buildTextField(
            controller: _nameCtrl,
            hint: 'John Doe',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 14),
          _buildFieldLabel('Email Address'),
          const SizedBox(height: 5),
          _buildTextField(
            controller: _emailCtrl,
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildFieldLabel('Password'),
          const SizedBox(height: 5),
          _buildPasswordField(),
          const SizedBox(height: 6),
          _buildStrengthBar(),
          const SizedBox(height: 14),
          _buildFieldLabel('Home Country'),
          const SizedBox(height: 5),
          _buildCountryDropdown(),
          const SizedBox(height: 14),
          _buildTermsRow(),
          const SizedBox(height: 14),
          _buildCtaButton(),
          const SizedBox(height: 14),
          _buildSignInRow(),
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
              fontSize: 24, fontWeight: FontWeight.w700,
              color: AppColors.text1, height: 1.2,
            ),
            children: const [
              TextSpan(text: 'Create your\n'),
              TextSpan(text: 'Explorer',
                  style: TextStyle(fontStyle: FontStyle.italic)),
              TextSpan(text: ' account'),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text('Join thousands discovering Phuket',
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.text2)),
      ],
    );
  }

  Widget _buildStepIndicator() {
    const totalSteps = 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final stepNum  = i + 1;
            final isDone   = stepNum < _currentStep;
            final isActive = stepNum == _currentStep;
            final width    = isActive ? 40.0 : 28.0;
            Color color;
            if (isDone)        color = AppColors.oceanMid;
            else if (isActive) color = AppColors.oceanDeep;
            else               color = AppColors.border;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: width, height: 4,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99)),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text('STEP $_currentStep OF $totalSteps — PERSONAL DETAILS',
            style: GoogleFonts.outfit(fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.text3, letterSpacing: 1.1)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(fontSize: 14,
          fontWeight: FontWeight.w500, color: AppColors.text1),
      decoration: _inputDecoration(hint: hint, prefixIcon: icon),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePass,
      style: GoogleFonts.outfit(fontSize: 14,
          fontWeight: FontWeight.w500, color: AppColors.text1),
      decoration: _inputDecoration(
        hint: 'Min. 8 characters',
        prefixIcon: Icons.lock_outline_rounded,
        suffix: GestureDetector(
          onTap: () => setState(() => _obscurePass = !_obscurePass),
          child: Icon(
            _obscurePass
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18, color: AppColors.text3,
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthBar() {
    final (filledCount, barColor, label) = switch (_strength) {
      PasswordStrength.none       => (0, Colors.transparent, ''),
      PasswordStrength.weak       => (2, AppColors.coral,    'Weak — add numbers & symbols'),
      PasswordStrength.fair       => (3, AppColors.gold,     'Fair — getting stronger'),
      PasswordStrength.strong     => (4, const Color(0xFF22C55E), 'Strong — great password!'),
      PasswordStrength.veryStrong => (4, const Color(0xFF16A34A), 'Very strong — excellent!'),
    };
    if (_strength == PasswordStrength.none) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 3,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < filledCount ? barColor : AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 3),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(label,
              key: ValueKey(label),
              style: GoogleFonts.outfit(fontSize: 10,
                  fontWeight: FontWeight.w700, color: barColor)),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    const countries = [
      ('MY', '🇲🇾  Malaysia'),
      ('TH', '🇹🇭  Thailand'),
      ('US', '🇺🇸  United States'),
      ('UK', '🇬🇧  United Kingdom'),
      ('AU', '🇦🇺  Australia'),
      ('SG', '🇸🇬  Singapore'),
    ];
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: shadowSm,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 15),
            child: Icon(Icons.public_rounded, size: 19, color: AppColors.text3),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                isExpanded: true,
                icon: const SizedBox.shrink(),
                padding: const EdgeInsets.only(left: 12),
                hint: Text('Select your country',
                    style: GoogleFonts.outfit(fontSize: 14,
                        fontWeight: FontWeight.w400, color: AppColors.text3)),
                style: GoogleFonts.outfit(fontSize: 14,
                    fontWeight: FontWeight.w500, color: AppColors.text1),
                items: countries.map((c) =>
                    DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
                onChanged: (val) => setState(() => _selectedCountry = val),
                dropdownColor: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.expand_more_rounded,
                size: 18, color: AppColors.text3),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _termsAccepted = !_termsAccepted),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18, height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: _termsAccepted
                  ? AppColors.oceanDeep.withOpacity(0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _termsAccepted ? AppColors.oceanDeep : AppColors.border,
                width: 1.5,
              ),
            ),
            child: _termsAccepted
                ? const Icon(Icons.check_rounded, size: 13,
                    color: AppColors.oceanDeep)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 12,
                  color: AppColors.text2, height: 1.4),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      color: AppColors.oceanDeep),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      color: AppColors.oceanDeep),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Stack(
          children: [
            // Sheen layer — behind button content
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sheenAnim,
                builder: (_, __) => CustomPaint(
                  painter: SheenPainter(position: _sheenAnim.value),
                ),
              ),
            ),
            // Button content — fills the full 54px height
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _termsAccepted
                      ? () => Navigator.pushReplacement(context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()))
                      : null,
                  splashColor: Colors.white.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Join the Adventure',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.64,
                          )),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 19),
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

  Widget _buildSignInRow() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.text2),
          children: [
            const TextSpan(text: 'Already have an account?  '),
            TextSpan(
              text: 'Sign in →',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.oceanDeep),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.pushReplacement(context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.text1, letterSpacing: 0.24));
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    const enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      borderSide: BorderSide(color: AppColors.border, width: 1.5),
    );
    const focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      borderSide: BorderSide(color: AppColors.oceanDeep, width: 1.5),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(fontSize: 14,
          fontWeight: FontWeight.w400, color: AppColors.text3),
      prefixIcon: Icon(prefixIcon, size: 19, color: AppColors.text3),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix)
          : null,
      suffixIconConstraints: const BoxConstraints(),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder:      enabledBorder,
      focusedBorder:      focusBorder,
      errorBorder:        enabledBorder,
      focusedErrorBorder: focusBorder,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════
class RegisterStarsPainter extends CustomPainter {
  const RegisterStarsPainter();
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
      canvas.drawCircle(s.$1, s.$2,
          Paint()..color = Colors.white.withOpacity(s.$3));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
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
        colors: [Colors.transparent,
                 Colors.white.withOpacity(0.12),
                 Colors.transparent],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(left, 0, stripeW, size.height), paint);
  }
  @override
  bool shouldRepaint(SheenPainter old) => old.position != position;
}