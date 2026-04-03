// ============================================================
// AndaMove Admin — Screen 6: Admin Profile
// File: lib/admin/screens/admin_profile_screen.dart
//
// NEW patterns introduced in this screen:
//   1. Navy hero with gradient avatar + role chip overlay
//   2. Info row — 32×32 tinted icon + label + value (right-aligned)
//      Used in Account Details section
//   3. DM Mono admin ID inline with other non-mono rows
//   4. Permissions grid — Wrap of tinted tag chips, 3 colours:
//        green (granted), ocean (limited), coral (denied ✕)
//   5. Console toggle row — icon + title+sub + toggle widget
//      Toggle uses AnimatedContainer (pill) + AnimatedAlign (dot)
//      — same pattern as tourist Profile but in admin style
//   6. Admin action log — 6px dot + text + DM Mono time
//      Log dots use status colours (green/coral/amber/ocean)
//   7. Coral sign-out button — full width, r-xl, centred row
//   8. Version footer — RichText: "Fatini" in oceanMid bold
//      (same pattern as tourist Profile screen)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin_theme.dart';
import '../../screens/screen2_login.dart';

// ── Data models ───────────────────────────────────────────────
class _InfoRow {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool mono;
  const _InfoRow(
    this.icon,
    this.iconColor,
    this.label,
    this.value, {
    this.mono = false,
  });
}

class _PermTag {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _PermTag(this.label, this.bg, this.fg, this.icon);
}

class _ToggleRow {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String sub;
  bool on;
  _ToggleRow(
    this.icon,
    this.iconColor,
    this.title,
    this.sub, {
    required this.on,
  });
}

class _LogRow {
  final Color dot;
  final String text;
  final String time;
  const _LogRow(this.dot, this.text, this.time);
}

// ── Main screen ───────────────────────────────────────────────
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});
  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  // Account detail rows
  static final _accountRows = [
    _InfoRow(
      Icons.person_rounded,
      AC.ocean,
      'Full Name',
      'Nur Fatini bt. Mahamad Razali',
    ),
    _InfoRow(Icons.mail_rounded, AC.gold, 'Email', 'fatini@andamove.com'),
    _InfoRow(
      Icons.badge_rounded,
      AC.purple,
      'Admin ID',
      'ADMIN-0042',
      mono: true,
    ),
    _InfoRow(Icons.calendar_today_rounded, AC.green, 'Since', '4 August 2025'),
  ];

  // Permission tags
  // CSS: green = granted, ocean = limited, coral = denied
  // Icon: check (green/ocean) or close (coral)
  static final _perms = [
    _PermTag('Manage POIs', AC.greenTint, AC.green, Icons.check_rounded),
    _PermTag('Manage Users', AC.greenTint, AC.green, Icons.check_rounded),
    _PermTag('View Analytics', AC.greenTint, AC.green, Icons.check_rounded),
    _PermTag('Ban Users', AC.greenTint, AC.green, Icons.check_rounded),
    _PermTag('Export Data', AC.oceanTint, AC.ocean, Icons.check_rounded),
    _PermTag('Billing', AC.coralTint, AC.coral, Icons.close_rounded),
  ];

  // Toggle rows (mutable because toggling changes state)
  final _toggles = [
    _ToggleRow(
      Icons.notifications_rounded,
      AC.ocean,
      'Alert Notifications',
      'New users, flagged reports, POI submissions',
      on: true,
    ),
    _ToggleRow(
      Icons.shield_rounded,
      AC.purple,
      '2FA Authentication',
      'Required on every login',
      on: true,
    ),
    _ToggleRow(
      Icons.schedule_rounded,
      AC.gold,
      'Session Timeout',
      'Auto-logout after 30 minutes',
      on: true,
    ),
  ];

  // Admin action log
  static final _logs = [
    _LogRow(AC.green, 'Approved POI: Surin Beach Resort', '2h ago'),
    _LogRow(AC.coral, 'Banned user: kevin@email.com', '5h ago'),
    _LogRow(AC.amber, 'Hidden POI: Sunset Rooftop Bar', '1d ago'),
    _LogRow(AC.ocean, 'Exported user report CSV', '2d ago'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          // ── STEP 1: Navy hero with avatar + role chip
          _buildHero(context),

          // ── Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                children: [
                  // ── STEP 2: Account details section
                  _buildSection(
                    icon: Icons.person_rounded,
                    iconColor: AC.ocean,
                    title: 'Account Details',
                    child: Column(
                      children: _accountRows
                          .map((r) => _buildInfoRow(r))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── STEP 4: Permissions grid
                  _buildSection(
                    icon: Icons.shield_rounded,
                    iconColor: AC.purple,
                    title: 'Permissions',
                    child: _buildPermissionsGrid(),
                  ),
                  const SizedBox(height: 14),

                  // ── STEP 5: Console settings toggles
                  _buildSection(
                    icon: Icons.settings_rounded,
                    iconColor: AC.gold,
                    title: 'Console Settings',
                    child: Column(
                      children: _toggles
                          .asMap()
                          .entries
                          .map((e) => _buildToggleRow(e.key, e.value))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── STEP 6: Recent admin actions log
                  _buildSection(
                    icon: Icons.assignment_rounded,
                    iconColor: AC.coral,
                    title: 'Recent Admin Actions',
                    child: Column(
                      children: _logs
                          .asMap()
                          .entries
                          .map(
                            (e) => _buildLogRow(
                              e.value,
                              isLast: e.key == _logs.length - 1,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── STEP 7: Sign out button
                  _buildSignOutBtn(),
                  const SizedBox(height: 14),

                  // ── STEP 8: Version footer
                  _buildVersionFooter(),
                ],
              ),
            ),
          ),

          AdminBottomNav(activeIndex: 3),
        ],
      ),
    );
  }

  // ── STEP 1: Hero area ─────────────────────────────────────────
  // CSS: .profile-hero navy bg, pad-top:status-bar+10
  //   .ph-avatar 72×72 gradient circle, initials
  //   .ph-name DM Serif 20px white
  //   .ph-role ocean-tint pill "Super Admin"
  //   .ph-id DM Mono 11px white 40%
  //
  // NEW: Admin hero is all-navy (no wave cutout, no star bg).
  // The avatar uses a gradient circle exactly like user cards,
  // but 72×72. Role chip sits below name as an inline pill.
  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AC.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AC.ocean, AC.oceanMid],
              ),
              // Subtle white ring around avatar
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                'NF',
                style: adminUi(
                  size: 24,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            'Nur Fatini',
            style: adminDisplay(size: 20, color: Colors.white),
          ),
          const SizedBox(height: 6),

          // Role chip — ocean tint pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AC.ocean.withOpacity(0.20),
              borderRadius: BorderRadius.circular(AR.full),
              border: Border.all(color: AC.ocean.withOpacity(0.40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 12,
                  color: AC.oceanMid,
                ),
                const SizedBox(width: 5),
                Text(
                  'Super Admin',
                  style: adminUi(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AC.oceanMid,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Admin ID in DM Mono
          Text(
            'ADMIN-0042',
            style: adminMono(size: 11, color: Colors.white.withOpacity(0.35)),
          ),
        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────
  // CSS: .profile-section surface r-16 border shadow-sm
  //   .ps-header flex gap:8 items-center, 32×32 icon + title
  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(AR.card),
        border: Border.all(color: AC.borderLight),
        boxShadow: aShadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AR.md),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(title, style: adminUi(size: 14, weight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1, color: AC.borderLight),
          child,
        ],
      ),
    );
  }

  // ── STEP 2: Info row ──────────────────────────────────────────
  // CSS: .info-row flex gap:10 items-center pad:11 14
  //   .ir-icon 32×32 r-md tinted
  //   .ir-label 11px text-3 flex:1
  //   .ir-value 13px text-1 text-right (mono if flagged)
  //
  // NEW: right-aligned value. In CSS: margin-left:auto on .ir-value.
  // Flutter equivalent: Expanded(child: label) pushes value right.
  Widget _buildInfoRow(_InfoRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AC.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: row.iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AR.md),
            ),
            child: Icon(row.icon, size: 15, color: row.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.label,
              style: adminUi(
                size: 11,
                weight: FontWeight.w600,
                color: AC.text3,
              ),
            ),
          ),
          // ── STEP 3: DM Mono for admin ID only
          // CSS: .ir-value[admin-id] { font-family: DM Mono; font-size:13px }
          // Other rows use Plus Jakarta Sans at 13px.
          Text(
            row.value,
            style: row.mono
                ? adminMono(size: 13)
                : adminUi(size: 13, weight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  // ── STEP 4: Permissions grid ──────────────────────────────────
  // CSS: .perm-grid flex flex-wrap gap:8
  //   .perm-tag r-full pad:5 10 flex gap:5 items-center
  //   3 colour states:
  //     green-tint + green icon+text (granted)
  //     ocean-tint + ocean icon+text (limited)
  //     coral-tint + coral ✕ icon+text (denied)
  //
  // NEW: Wrap widget for auto-wrapping tag grid.
  // Flutter's Wrap is the direct equivalent of CSS flexbox with
  // flex-wrap:wrap. spacing = column gap, runSpacing = row gap.
  Widget _buildPermissionsGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _perms
            .map(
              (p) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: BorderRadius.circular(AR.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p.icon, size: 13, color: p.fg),
                    const SizedBox(width: 5),
                    Text(
                      p.label,
                      style: adminUi(
                        size: 11,
                        weight: FontWeight.w700,
                        color: p.fg,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── STEP 5: Console toggle row ────────────────────────────────
  // CSS: .toggle-row flex gap:10 items-center pad:11 14
  //   .tr-icon 34×34 tinted r-md
  //   .tr-content flex:1 (.tr-label 13px w700 + .tr-sub 11px text-2)
  //   .toggle 44×24 pill:
  //     .toggle.toggle-on — bg:ocean
  //     .toggle-thumb 18×18 white circle
  //   Transition: CSS "transition: all 0.2s" on both pill and dot
  //
  // Flutter: AnimatedContainer for pill bg colour change +
  // AnimatedAlign for dot sliding left↔right.
  // This is identical in logic to the tourist Profile screen toggle,
  // but uses AC (admin) colours instead of tourist app colours.
  Widget _buildToggleRow(int index, _ToggleRow row) {
    return GestureDetector(
      onTap: () => setState(() => row.on = !row.on),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AC.borderLight)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: row.iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AR.md),
              ),
              child: Icon(row.icon, size: 17, color: row.iconColor),
            ),
            const SizedBox(width: 10),

            // Label + sub
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    style: adminUi(size: 13, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 1),
                  Text(row.sub, style: adminUi(size: 11, color: AC.text2)),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Toggle pill
            // CSS: width:44 height:24 border-radius:full padding:3
            // Inner dot: 18×18 white circle
            // On: bg=ocean, dot aligned right
            // Off: bg=border, dot aligned left
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: row.on ? AC.ocean : AC.border,
                borderRadius: BorderRadius.circular(AR.full),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: row.on
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 6: Admin action log row ─────────────────────────────
  // CSS: .log-row flex items-center gap:10 pad:10 14
  //   .log-dot 8×8 circle coloured
  //   .log-text flex:1 12px text-1 w600
  //   .log-time DM Mono 10px text-3
  Widget _buildLogRow(_LogRow row, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AC.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: row.dot),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.text,
              style: adminUi(size: 12, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(row.time, style: adminMono(size: 10, color: AC.text3)),
        ],
      ),
    );
  }

  // ── STEP 7: Sign-out button ───────────────────────────────────
  // CSS: .signout-btn full-width coral-tint bg, coral text
  //   border-radius:14px (not full — different from tourist sign-out)
  //   flex items-center justify-center gap:8 h:48
  //
  // Admin uses r-14 not r-full to match the admin card aesthetic
  Widget _buildSignOutBtn() {
    return GestureDetector(
      onTap: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      ),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: AC.coralTint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AC.coral.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 17, color: AC.coral),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: adminUi(
                size: 14,
                weight: FontWeight.w700,
                color: AC.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 8: Version footer ────────────────────────────────────
  // CSS: .version-note 11px text-3 text-center
  //   <span> inside = oceanMid bold = "Fatini"
  //
  // NEW: RichText mixed-colour footer.
  // Same pattern as tourist Profile screen version footer:
  // TextSpan children with one override span for the name.
  // "AndaMove Admin v1.0.0 · Built by Fatini · FYP 2026"
  //
  // The word "Fatini" uses oceanMid + FontWeight.w700 while the
  // surrounding text uses text3 + w400.
  Widget _buildVersionFooter() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: adminUi(size: 11, color: AC.text3),
          children: [
            const TextSpan(text: 'AndaMove Admin v1.0.0 · Built by '),
            TextSpan(
              text: 'Fatini',
              style: adminUi(
                size: 11,
                weight: FontWeight.w700,
                color: AC.oceanMid,
              ),
            ),
            const TextSpan(text: ' · FYP 2026'),
          ],
        ),
      ),
    );
  }
}
