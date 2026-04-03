// ============================================================
// AndaMove Admin — Design System & Shared Widgets
// File: lib/admin/admin_theme.dart
//
// Contains:
//   • AC  — Admin colour tokens
//   • AR  — Admin radius tokens
//   • adminDisplay / adminUi / adminMono — font helpers
//   • aShadowSm — shared shadow
//   • AdminTopNavBrand  — dashboard top nav with pill tabs
//   • AdminTopNavPage   — sub-page top nav (back + title + action)
//   • AdminBottomNav    — 4-tab bottom nav with screen routing
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Screen imports for bottom-nav routing
import 'screens/adminScreen1_analyticsDashboard.dart';
import 'screens/adminScreen2_managePOI.dart';
import 'screens/adminScreen4_manageUsers.dart';
import 'screens/adminScreen5_profile.dart';

// ══════════════════════════════════════════════════════════════
// COLOUR TOKENS — AC (Admin Colours)
// ══════════════════════════════════════════════════════════════
class AC {
  // ── Navy (backgrounds, nav bars) ──
  static const Color navy      = Color(0xFF0A1E28);
  static const Color navyLight = Color(0xFF1A3040);

  // ── Brand colours ──
  static const Color ocean     = Color(0xFF0A7FAB);
  static const Color oceanMid  = Color(0xFF1AAECF);
  static const Color gold      = Color(0xFFC8912E);
  static const Color goldLight = Color(0xFFF0C060);
  static const Color coral     = Color(0xFFE8634C);
  static const Color green     = Color(0xFF22C55E);
  static const Color purple    = Color(0xFF8B5CF6);
  static const Color amber     = Color(0xFFF59E0B);

  // ── Tint backgrounds (8-12% tint for badges / pills) ──
  static const Color oceanTint  = Color(0xFFEAF8FD);
  static const Color goldTint   = Color(0xFFFFF8EC);
  static const Color coralTint  = Color(0xFFFDECE8);
  static const Color greenTint  = Color(0xFFECFDF5);
  static const Color purpleTint = Color(0xFFF3EFFE);
  static const Color amberTint  = Color(0xFFFEF3C7);

  // ── Surfaces ──
  static const Color bg         = Color(0xFFF5F7FA);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surface2   = Color(0xFFF0F2F5);

  // ── Borders ──
  static const Color border      = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);

  // ── Text ──
  static const Color text1 = Color(0xFF111827);
  static const Color text2 = Color(0xFF6B7280);
  static const Color text3 = Color(0xFF9CA3AF);
}

// ══════════════════════════════════════════════════════════════
// RADIUS TOKENS — AR (Admin Radii)
// ══════════════════════════════════════════════════════════════
class AR {
  static const double sm   = 8;
  static const double md   = 10;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double full = 999;
  static const double card = 16;
}

// ══════════════════════════════════════════════════════════════
// FONT HELPERS
// DM Serif Display  — headings / display text
// Plus Jakarta Sans — UI labels, body, buttons
// DM Mono           — numeric values, codes
// ══════════════════════════════════════════════════════════════
TextStyle adminDisplay({
  double     size   = 20,
  Color      color  = AC.text1,
  FontWeight weight = FontWeight.w400,
}) => GoogleFonts.dmSerifDisplay(
    fontSize: size, color: color, fontWeight: weight);

TextStyle adminUi({
  double     size   = 14,
  Color      color  = AC.text1,
  FontWeight weight = FontWeight.w400,
}) => GoogleFonts.plusJakartaSans(
    fontSize: size, color: color, fontWeight: weight);

TextStyle adminMono({
  double     size   = 14,
  Color      color  = AC.text1,
  FontWeight weight = FontWeight.w500,
}) => GoogleFonts.dmMono(
    fontSize: size, color: color, fontWeight: weight);

// ══════════════════════════════════════════════════════════════
// SHADOW
// ══════════════════════════════════════════════════════════════
List<BoxShadow> aShadowSm = [
  BoxShadow(
    color: const Color(0xFF111827).withOpacity(0.05),
    blurRadius: 3,
    offset: const Offset(0, 1),
  ),
  BoxShadow(
    color: const Color(0xFF111827).withOpacity(0.03),
    blurRadius: 2,
    offset: const Offset(0, 1),
  ),
];

// ══════════════════════════════════════════════════════════════
// SHARED WIDGET 1 — AdminTopNavBrand
// Used by: AdminDashboardScreen
// Navy bar with AndaMove logo + pill tab row
// ══════════════════════════════════════════════════════════════
class AdminTopNavBrand extends StatelessWidget {
  final int              selectedTab;
  final List<String>     tabs;
  final ValueChanged<int> onTabChanged;

  const AdminTopNavBrand({
    super.key,
    required this.selectedTab,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AC.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Column(
        children: [
          // ── Brand row: logo text + admin badge ──
          Row(
            children: [
              // Brand name
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'Anda',
                    style: adminDisplay(
                        size: 18, color: Colors.white),
                  ),
                  TextSpan(
                    text: 'Move',
                    style: adminDisplay(
                        size: 18, color: AC.gold),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              // Admin badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AC.ocean.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(AR.full),
                  border: Border.all(
                      color: AC.ocean.withOpacity(0.40)),
                ),
                child: Text(
                  'ADMIN',
                  style: adminUi(
                    size: 9,
                    weight: FontWeight.w800,
                    color: AC.oceanMid,
                  ).copyWith(letterSpacing: 1.0),
                ),
              ),
              const Spacer(),
              // Notification bell
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(AR.md),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.10)),
                ),
                child: Icon(Icons.notifications_outlined,
                    size: 17,
                    color: Colors.white.withOpacity(0.70)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Pill tab row ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.asMap().entries.map((e) {
                final active = e.key == selectedTab;
                return GestureDetector(
                  onTap: () => onTabChanged(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                          ? AC.ocean.withOpacity(0.20)
                          : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(AR.full),
                      border: Border.all(
                        color: active
                            ? AC.ocean.withOpacity(0.40)
                            : Colors.white.withOpacity(0.10),
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: adminUi(
                        size: 12,
                        weight: FontWeight.w700,
                        color: active
                            ? AC.oceanMid
                            : Colors.white.withOpacity(0.50),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SHARED WIDGET 2 — AdminTopNavPage
// Used by: ManagePOIs, ManageUsers, Profile, CreatePOI
// Navy bar with back button + title + optional action widget
// ══════════════════════════════════════════════════════════════
class AdminTopNavPage extends StatelessWidget {
  final String  title;
  final Widget? action;
  final bool    showBack;   // set false for main-tab screens

  const AdminTopNavPage({
    super.key,
    required this.title,
    this.action,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AC.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          // Back button (hidden for main-tab screens)
          if (showBack) ...[
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(AR.md),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.10)),
                ),
                child: Icon(Icons.chevron_left_rounded,
                    size: 20,
                    color: Colors.white.withOpacity(0.80)),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Title
          Expanded(
            child: Text(title,
                style: adminDisplay(
                    size: 17, color: Colors.white)),
          ),

          // Optional action widget (e.g. "+ Add POI" button)
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SHARED WIDGET 3 — AdminBottomNav
// Used by: ALL admin screens
// Navy bottom bar, 4 tabs with routing via pushReplacement
//
// Nav items:
//   0 → Dashboard  (AdminDashboardScreen)
//   1 → POIs       (AdminPoiScreen)
//   2 → Users      (AdminUsersScreen)
//   3 → Profile    (AdminProfileScreen)
// ══════════════════════════════════════════════════════════════
class AdminBottomNav extends StatelessWidget {
  final int activeIndex;

  const AdminBottomNav({super.key, required this.activeIndex});

  static const _items = [
    (Icons.dashboard_rounded,     'Dashboard'),
    (Icons.location_on_rounded,   'POIs'),
    (Icons.group_rounded,         'Users'),
    (Icons.person_rounded,        'Profile'),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == activeIndex) return;

    Widget screen;
    switch (index) {
      case 0:
        screen = const AdminDashboardScreen();
        break;
      case 1:
        screen = const AdminPoiScreen();
        break;
      case 2:
        screen = const AdminUsersScreen();
        break;
      case 3:
        screen = const AdminProfileScreen();
        break;
      default:
        return;
    }

    // pushReplacement prevents stacking admin screens
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AC.navy,
        border: Border(
          top: BorderSide(
              color: Color(0xFF1A3040), width: 1),
        ),
      ),
      child: Row(
        children: _items.asMap().entries.map((e) {
          final i      = e.key;
          final item   = e.value;
          final active = i == activeIndex;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onTap(context, i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active indicator bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: active ? 24 : 0,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: active ? AC.ocean : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Icon with optional tinted background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 28,
                    decoration: BoxDecoration(
                      color: active
                          ? AC.ocean.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AR.sm),
                    ),
                    child: Icon(
                      item.$1,
                      size: 19,
                      color: active
                          ? AC.oceanMid
                          : Colors.white.withOpacity(0.35),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Label
                  Text(
                    item.$2,
                    style: adminUi(
                      size: 10,
                      weight: active
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: active
                          ? AC.oceanMid
                          : Colors.white.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}