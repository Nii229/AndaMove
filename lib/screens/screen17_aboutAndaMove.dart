// ============================================================
// AndaMove — About AndaMove Screen
// File: lib/screens/screen17_aboutAndaMove.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color oceanDeep   = Color(0xFF0A7FAB);
  static const Color oceanMid    = Color(0xFF1AAECF);
  static const Color oceanTint   = Color(0xFFEAF8FD);
  static const Color gold        = Color(0xFFC8912E);
  static const Color goldLight   = Color(0xFFF0C060);
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

class _LinkRow {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   title;
  final String   subtitle;

  const _LinkRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });
}

class _TechRow {
  final IconData icon;
  final Color    color;
  final String   name;
  final String   version;

  const _TechRow(this.icon, this.color, this.name, this.version);
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class AboutAndaMoveScreen extends StatelessWidget {
  const AboutAndaMoveScreen({super.key});

  static const _legalLinks = [
    _LinkRow(
      icon:      Icons.privacy_tip_rounded,
      iconColor: AppColors.oceanDeep,
      iconBg:    AppColors.oceanTint,
      title:     'Privacy Policy',
      subtitle:  'How we handle your data',
    ),
    _LinkRow(
      icon:      Icons.gavel_rounded,
      iconColor: AppColors.gold,
      iconBg:    AppColors.goldTint,
      title:     'Terms of Service',
      subtitle:  'Rules and conditions of use',
    ),
    _LinkRow(
      icon:      Icons.description_rounded,
      iconColor: AppColors.purple,
      iconBg:    AppColors.purpleTint,
      title:     'Open Source Licenses',
      subtitle:  'Third-party libraries used',
    ),
    _LinkRow(
      icon:      Icons.cookie_rounded,
      iconColor: AppColors.coral,
      iconBg:    AppColors.coralTint,
      title:     'Cookie Policy',
      subtitle:  'Local storage and analytics',
    ),
  ];

  static const _techStack = [
    _TechRow(Icons.phone_android_rounded, AppColors.oceanDeep,
        'Flutter', '3.22 (Dart 3.4)'),
    _TechRow(Icons.map_rounded, AppColors.green,
        'Google Maps SDK', 'v6.x'),
    _TechRow(Icons.text_fields_rounded, AppColors.gold,
        'Google Fonts', '^6.2.1'),
    _TechRow(Icons.storage_rounded, AppColors.purple,
        'Shared Preferences', '^2.3'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppCard(),
                  const SizedBox(height: 24),
                  _buildMissionSection(),
                  const SizedBox(height: 24),
                  _buildDeveloperCard(),
                  const SizedBox(height: 24),
                  _buildTechStackSection(),
                  const SizedBox(height: 24),
                  _buildLegalSection(context),
                  const SizedBox(height: 24),
                  _buildVersionFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                onTap: () => Navigator.pop(context),
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
                    Text('About AndaMove',
                        style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text1)),
                    Text('Version, licenses & team',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppColors.text2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
          colors: [Color(0xFF061018), Color(0xFF0A3D5C), Color(0xFF0A7FAB)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            Positioned(
              top: -30, right: -30,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withOpacity(0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.65],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                // Logo circle
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.20), width: 2),
                  ),
                  child: const Icon(Icons.explore_rounded,
                      size: 36, color: Colors.white),
                ),
                const SizedBox(height: 14),
                // App name
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    children: [
                      const TextSpan(text: 'Anda'),
                      WidgetSpan(
                        child: ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                          ).createShader(b),
                          child: Text('Move',
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'GPS-Based Itinerary Planner\nfor Phuket, Thailand',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.60),
                      height: 1.5),
                ),
                const SizedBox(height: 16),
                // Version + platform badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _glassChip(Icons.tag_rounded, 'v1.0.0'),
                    const SizedBox(width: 8),
                    _glassChip(Icons.android_rounded, 'Android'),
                    const SizedBox(width: 8),
                    _glassChip(Icons.school_rounded, 'FYP 2026'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.goldLight),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('OUR MISSION'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.oceanTint,
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Icon(Icons.lightbulb_rounded,
                        size: 20, color: AppColors.oceanDeep),
                  ),
                  const SizedBox(width: 12),
                  Text('Why AndaMove?',
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1)),
                ]),
                const SizedBox(height: 14),
                Text(
                  'AndaMove was built to solve a real problem: tourists visiting Phuket '
                  'often struggle to organise their day efficiently. Global apps rely '
                  'on popularity rankings rather than proximity and travel time, '
                  'leaving visitors wasting time between scattered attractions.',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.text2,
                      height: 1.65),
                ),
                const SizedBox(height: 12),
                Text(
                  'This app provides a lightweight, distance- and travel-time-aware '
                  'itinerary system tailored specifically for Phuket — helping tourists '
                  'plan realistic, enjoyable days with minimal friction.',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.text2,
                      height: 1.65),
                ),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _featureChip(Icons.near_me_rounded, 'Distance-Aware', AppColors.oceanDeep, AppColors.oceanTint),
                  _featureChip(Icons.schedule_rounded, 'Travel-Time Optimised', AppColors.gold, AppColors.goldTint),
                  _featureChip(Icons.location_on_rounded, 'Phuket-Focused', AppColors.green, AppColors.greenTint),
                  _featureChip(Icons.auto_fix_high_rounded, 'AI-Powered Routes', AppColors.purple, AppColors.purpleTint),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(
      IconData icon, String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg)),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('DEVELOPMENT TEAM'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            child: Column(
              children: [
                // Developer row
                Row(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.purple, Color(0xFF9B5CF6)],
                      ),
                      border: Border.all(
                          color: AppColors.gold, width: 2),
                    ),
                    child: Center(
                      child: Text('NF',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nur Fatini binti Mahamad Razali',
                            style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text1)),
                        const SizedBox(height: 2),
                        Text('Matric No. 301193',
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: AppColors.text3)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.purpleTint,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text('Flutter Developer · FYP 2026',
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purple)),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 16),
                // Supervisor row
                Row(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.oceanDeep, AppColors.oceanMid],
                      ),
                      border: Border.all(
                          color: AppColors.oceanMid.withOpacity(0.40),
                          width: 2),
                    ),
                    child: Center(
                      child: Text('SC',
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Suwannit Chareen Chit A/L Sop Chit',
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text1)),
                        const SizedBox(height: 2),
                        Text('Project Supervisor',
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: AppColors.text3)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.oceanTint,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text('Academic Supervisor',
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.oceanDeep)),
                        ),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechStackSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('BUILT WITH'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _techStack.asMap().entries.map((e) {
                final i   = e.key;
                final t   = e.value;
                final isLast = i == _techStack.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: t.color.withOpacity(0.10),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(t.icon, size: 20, color: t.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(t.name,
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text1)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(t.version,
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text2)),
                        ),
                      ]),
                    ),
                    if (!isLast)
                      const Divider(
                          height: 1, color: AppColors.borderLight),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('LEGAL'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _legalLinks.asMap().entries.map((e) {
                final i   = e.key;
                final row = e.value;
                final isLast = i == _legalLinks.length - 1;
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                  color: row.iconBg,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.md)),
                              child: Icon(row.icon,
                                  size: 20, color: row.iconColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(row.title,
                                      style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text1)),
                                  const SizedBox(height: 1),
                                  Text(row.subtitle,
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppColors.text2)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                size: 18, color: AppColors.text3),
                          ]),
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                          height: 1, color: AppColors.borderLight),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: shadowSm,
        ),
        child: Column(children: [
          const Icon(Icons.explore_rounded,
              size: 28, color: AppColors.oceanMid),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.outfit(
                  fontSize: 12, color: AppColors.text3, height: 1.6),
              children: [
                const TextSpan(text: 'AndaMove  '),
                TextSpan(
                    text: 'v1.0.0',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.oceanMid)),
                const TextSpan(text: '\nBuilt for STIZK3993 Academic Project 1\n'),
                TextSpan(
                    text: 'Universiti Malaysia Perlis (UniMAP)',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text2)),
                const TextSpan(text: '\n© 2026 Nur Fatini · All rights reserved'),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AppColors.text3));
  }
}
