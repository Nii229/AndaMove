// ============================================================
// AndaMove — Edit Personal Info Screen
// File: lib/screens/screen15_editPersonalInfo.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color oceanDeep   = Color(0xFF0A7FAB);
  static const Color oceanMid    = Color(0xFF1AAECF);
  static const Color oceanTint   = Color(0xFFEAF8FD);
  static const Color gold        = Color(0xFFC8912E);
  static const Color goldTint    = Color(0xFFFDF5E7);
  static const Color coral       = Color(0xFFE8634C);
  static const Color coralTint   = Color(0xFFFDF0EE);
  static const Color green       = Color(0xFF16A34A);
  static const Color greenTint   = Color(0xFFEEF5EE);
  static const Color purple      = Color(0xFF7C3AED);
  static const Color purpleTint  = Color(0xFFF3EFFE);
  static const Color bg          = Color(0xFFFBF8F3);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color surface2    = Color(0xFFF5F1EB);
  static const Color border      = Color(0xFFE6DDD1);
  static const Color borderLight = Color(0xFFF0EBE2);
  static const Color text1       = Color(0xFF0A1E28);
  static const Color text2       = Color(0xFF5A7A8A);
  static const Color text3       = Color(0xFF9AB0B8);
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
      blurRadius: 4, offset: const Offset(0, 1))
];
List<BoxShadow> get shadowOcean => [
  BoxShadow(color: AppColors.oceanDeep.withOpacity(0.25),
      blurRadius: 20, offset: const Offset(0, 8))
];

// ══════════════════════════════════════════════════════════════
// DATA MODEL — passed in from ProfileScreen
// ══════════════════════════════════════════════════════════════
class PersonalInfo {
  final String fullName;
  final String email;
  final String phone;
  final String country;

  const PersonalInfo({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.country,
  });

  PersonalInfo copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? country,
  }) =>
      PersonalInfo(
        fullName: fullName ?? this.fullName,
        email:    email    ?? this.email,
        phone:    phone    ?? this.phone,
        country:  country  ?? this.country,
      );
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class EditPersonalInfoScreen extends StatefulWidget {
  final PersonalInfo initialInfo;

  const EditPersonalInfoScreen({
    super.key,
    required this.initialInfo,
  });

  @override
  State<EditPersonalInfoScreen> createState() =>
      _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _countryCtrl;

  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;

  // Focus nodes for field highlighting
  final _nameFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _phoneFocus   = FocusNode();
  final _countryFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.initialInfo.fullName);
    _emailCtrl   = TextEditingController(text: widget.initialInfo.email);
    _phoneCtrl   = TextEditingController(text: widget.initialInfo.phone);
    _countryCtrl = TextEditingController(text: widget.initialInfo.country);

    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _countryCtrl]) {
      c.addListener(_onAnyChange);
    }
    for (final f in [_nameFocus, _emailFocus, _phoneFocus, _countryFocus]) {
      f.addListener(() => setState(() {}));
    }
  }

  void _onAnyChange() {
    final changed =
        _nameCtrl.text    != widget.initialInfo.fullName ||
        _emailCtrl.text   != widget.initialInfo.email    ||
        _phoneCtrl.text   != widget.initialInfo.phone    ||
        _countryCtrl.text != widget.initialInfo.country;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _countryCtrl]) {
      c.dispose();
    }
    for (final f in [_nameFocus, _emailFocus, _phoneFocus, _countryFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = PersonalInfo(
      fullName: _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      phone:    _phoneCtrl.text.trim(),
      country:  _countryCtrl.text.trim(),
    );
    Navigator.pop(context, updated);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Profile updated!',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      duration: const Duration(seconds: 2),
    ));
  }

  void _onDiscard() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Text('Discard Changes?',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.text1)),
          content: Text(
            'Your unsaved changes will be lost.',
            style: GoogleFonts.outfit(
                fontSize: 14, color: AppColors.text2, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keep Editing',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text2)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
              child: Text('Discard',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('PERSONAL DETAILS'),
                    const SizedBox(height: 12),
                    _buildField(
                      label:      'Full Name',
                      controller: _nameCtrl,
                      focusNode:  _nameFocus,
                      icon:       Icons.person_rounded,
                      iconColor:  AppColors.oceanDeep,
                      iconBg:     AppColors.oceanTint,
                      hint:       'Your full name',
                      validator:  (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Name cannot be empty'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label:        'Email Address',
                      controller:   _emailCtrl,
                      focusNode:    _emailFocus,
                      icon:         Icons.mail_rounded,
                      iconColor:    AppColors.gold,
                      iconBg:       AppColors.goldTint,
                      hint:         'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email cannot be empty';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label:        'Phone Number',
                      controller:   _phoneCtrl,
                      focusNode:    _phoneFocus,
                      icon:         Icons.phone_rounded,
                      iconColor:    AppColors.green,
                      iconBg:       AppColors.greenTint,
                      hint:         '+60 12-345 6789',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      label:     'Home Country',
                      controller: _countryCtrl,
                      focusNode:  _countryFocus,
                      icon:       Icons.language_rounded,
                      iconColor:  AppColors.purple,
                      iconBg:     AppColors.purpleTint,
                      hint:       'e.g. Malaysia 🇲🇾',
                    ),
                    const SizedBox(height: 28),
                    _buildSectionLabel('ACCOUNT'),
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon:    Icons.shield_rounded,
                      iconBg:  AppColors.oceanTint,
                      iconColor: AppColors.oceanDeep,
                      title:   'Account Status',
                      value:   'Verified ✓',
                      valueColor: AppColors.green,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoTile(
                      icon:    Icons.military_tech_rounded,
                      iconBg:  AppColors.goldTint,
                      iconColor: AppColors.gold,
                      title:   'Explorer Rank',
                      value:   'Gold Explorer',
                      valueColor: AppColors.gold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 14),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _onDiscard,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 19, color: AppColors.text1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Profile',
                        style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text1)),
                    Text('Update your personal details',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppColors.text2)),
                  ],
                ),
              ),
              if (_hasChanges)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.oceanTint,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                        color: AppColors.oceanDeep.withOpacity(0.20)),
                  ),
                  child: Text('Unsaved',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.oceanDeep)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar section ────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.oceanDeep, AppColors.oceanMid],
                  ),
                  border: Border.all(color: AppColors.gold, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.gold.withOpacity(0.25),
                        blurRadius: 16, offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.person_rounded,
                    size: 42, color: Colors.white),
              ),
              Positioned(
                bottom: 0, right: -4,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.oceanDeep,
                    border: Border.all(color: AppColors.surface, width: 2),
                    boxShadow: shadowSm,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Change Photo',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.oceanDeep)),
          Text('JPG, PNG up to 5MB',
              style: GoogleFonts.outfit(
                  fontSize: 11, color: AppColors.text3)),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AppColors.text3));
  }

  // ── Editable field ────────────────────────────────────────
  Widget _buildField({
    required String                label,
    required TextEditingController controller,
    required FocusNode             focusNode,
    required IconData              icon,
    required Color                 iconColor,
    required Color                 iconBg,
    required String                hint,
    TextInputType                  keyboardType = TextInputType.text,
    String? Function(String?)?     validator,
  }) {
    final isFocused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isFocused ? AppColors.oceanDeep : AppColors.text1,
                letterSpacing: 0.3)),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: isFocused ? shadowOcean : shadowSm,
          ),
          child: TextFormField(
            controller:   controller,
            focusNode:    focusNode,
            keyboardType: keyboardType,
            validator:    validator,
            style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.text1),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                  fontSize: 14, color: AppColors.text3),
              filled:    true,
              fillColor: AppColors.surface,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 16, color: AppColors.text3),
                      onPressed: () => setState(() => controller.clear()),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(
                    color: AppColors.oceanDeep, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(
                    color: AppColors.coral, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(
                    color: AppColors.coral, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Non-editable info tile ────────────────────────────────
  Widget _buildInfoTile({
    required IconData icon,
    required Color    iconBg,
    required Color    iconColor,
    required String   title,
    required String   value,
    Color?            valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text2)),
          ),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.text1)),
        ],
      ),
    );
  }

  // ── Bottom save bar ───────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          // Discard
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: _onDiscard,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.close_rounded,
                        size: 17, color: AppColors.text2),
                    const SizedBox(width: 6),
                    Text('Cancel',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text2)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Save
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _hasChanges ? _onSave : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: _hasChanges
                      ? const LinearGradient(
                          colors: [AppColors.oceanDeep, AppColors.oceanMid])
                      : null,
                  color: _hasChanges ? null : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: _hasChanges ? shadowOcean : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded,
                        size: 18,
                        color: _hasChanges
                            ? Colors.white
                            : AppColors.text3),
                    const SizedBox(width: 8),
                    Text('Save Changes',
                        style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _hasChanges
                                ? Colors.white
                                : AppColors.text3)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
