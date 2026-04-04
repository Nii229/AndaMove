// ============================================================
// AndaMove — Forgot Password Screen
// File: lib/screens/screen4_forgotPassword.dart
//
// UPDATED:
//   - Firebase Auth password reset email
//   - Loading state
//   - Error handling with friendly messages
//   - Resend link wired to Firebase too
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screen2_login.dart';

// ── COLOR TOKENS ─────────────────────────────────────────────
class AppColors {
  static const Color oceanDeep = Color(0xFF0A7FAB);
  static const Color oceanMid = Color(0xFF1AAECF);
  static const Color oceanTint = Color(0xFFEAF8FD);
  static const Color gold = Color(0xFFC8912E);
  static const Color goldLight = Color(0xFFF0C060);
  static const Color coral = Color(0xFFE8634C);
  static const Color green = Color(0xFF16A34A);
  static const Color greenTint = Color(0xFFEEF5EE);
  static const Color bg = Color(0xFFFBF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF5F1EB);
  static const Color border = Color(0xFFE6DDD1);
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
List<BoxShadow> get shadowOcean => [
  BoxShadow(
    color: AppColors.oceanDeep.withOpacity(0.28),
    blurRadius: 24,
    offset: const Offset(0, 8),
  ),
];

// ============================================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _submitted  = false;
  bool _isLoading  = false;

  late final AnimationController _sheenCtrl;
  late final Animation<double> _sheenAnim;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
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
    _emailCtrl.dispose();
    _sheenCtrl.dispose();
    super.dispose();
  }

  // ── SHOW ERROR SNACKBAR ──────────────────────────────────
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.outfit(
                fontSize: 13, fontWeight: FontWeight.w500)),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── SEND RESET EMAIL ─────────────────────────────────────
  Future<void> _onSend() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (mounted) {
        setState(() {
          _submitted = true;
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found with this email';
          break;
        case 'invalid-email':
          msg = 'Please enter a valid email address';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please try again later';
          break;
        default:
          msg = e.message ?? 'Something went wrong. Please try again';
      }
      if (mounted) {
        _showError(msg);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showError('Something went wrong. Please try again');
        setState(() => _isLoading = false);
      }
    }
  }

  // ── RESEND RESET EMAIL ───────────────────────────────────
  Future<void> _onResend() async {
    setState(() => _submitted = false);
    // Small delay so user sees the form again before auto-sending
    await Future.delayed(const Duration(milliseconds: 300));
    _onSend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 60, 28, 32),
                    child: _submitted
                        ? _buildSuccessState()
                        : _buildFormState(),
                  ),
                ),
              ],
            ),
            // ── Loading overlay ──
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.oceanDeep,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 40, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 19,
                color: AppColors.text1,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Logo + AndaMove
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: 1,
                        child: Image.asset(
                          'assets/images/andamove_logo.png',
                          width: 42,
                          height: 42,
                          color: AppColors.text1,
                          colorBlendMode: BlendMode.srcIn,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Anda',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text1,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.goldLight, AppColors.gold],
                    ).createShader(bounds),
                    child: Text(
                      'Move',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FORM STATE
  // ══════════════════════════════════════════════════════════
  Widget _buildFormState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.oceanTint,
            border: Border.all(
              color: AppColors.gold.withOpacity(0.40),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.oceanDeep.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 36,
            color: AppColors.oceanDeep,
          ),
        ),
        const SizedBox(height: 24),

        // Heading
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
              height: 1.2,
            ),
            children: [
              const TextSpan(text: 'Lost your\n'),
              TextSpan(
                text: 'way back?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: AppColors.oceanDeep,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Subtitle
        Text(
          'No worries — enter your email and we\'ll\nsend a secure reset link within minutes.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppColors.text2,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 32),

        // Email field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Registered Email',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
              letterSpacing: 0.24,
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.text1,
          ),
          decoration: InputDecoration(
            hintText: 'you@example.com',
            hintStyle: GoogleFonts.outfit(fontSize: 15, color: AppColors.text3),
            prefixIcon: const Icon(
              Icons.mail_outline_rounded,
              size: 19,
              color: AppColors.text3,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
              borderSide: BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
              borderSide: BorderSide(color: AppColors.oceanDeep, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.oceanTint,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.oceanDeep.withOpacity(0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.oceanDeep,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A secure link will be sent to your email. '
                  'It expires in 15 minutes for your safety.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.oceanDeep,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Send Reset Link button
        _buildCtaButton(),
        const SizedBox(height: 20),

        // Back to Login
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_back_rounded,
                size: 15,
                color: AppColors.text2,
              ),
              const SizedBox(width: 6),
              Text(
                'Back to Login',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // SUCCESS STATE
  // ══════════════════════════════════════════════════════════
  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        // Success icon
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.greenTint,
            border: Border.all(
              color: AppColors.green.withOpacity(0.30),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 42,
            color: AppColors.green,
          ),
        ),
        const SizedBox(height: 28),

        Text(
          'Check your inbox!',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.text1,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'We\'ve sent a password reset link to\n${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppColors.text2,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 32),

        // Resend hint
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.text3,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Didn\'t receive it? Check your spam folder '
                  'or wait a moment before resending.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.text2,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Back to login button
        _buildCtaButton(
          label: 'Back to Login',
          icon: Icons.login_rounded,
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          ),
        ),
        const SizedBox(height: 16),

        // Resend link — now wired to Firebase
        GestureDetector(
          onTap: _isLoading ? null : _onResend,
          child: Text(
            'Resend reset link',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.oceanDeep,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // CTA BUTTON
  // ══════════════════════════════════════════════════════════
  Widget _buildCtaButton({String? label, IconData? icon, VoidCallback? onTap}) {
    final btnLabel = label ?? 'Send Reset Link';
    final btnIcon = icon ?? Icons.send_rounded;
    final btnTap = onTap ?? _onSend;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
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
              // Sheen — behind content
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _sheenAnim,
                  builder: (_, __) => CustomPaint(
                    painter: _SheenPainter(position: _sheenAnim.value),
                  ),
                ),
              ),
              // Button content
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : btnTap,
                    splashColor: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          btnLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(btnIcon, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
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
// SHEEN PAINTER
// ══════════════════════════════════════════════════════════════
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