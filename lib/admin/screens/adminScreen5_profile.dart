// ============================================================
// AndaMove Admin — Screen 5: Admin Profile
// File: lib/admin/screens/adminScreen5_profile.dart
//
// UPDATED — Firestore-wired:
//   • Account Details reads from Firebase Auth + Firestore
//     users/{uid} (name, email) — falls back to hardcoded if
//     the logged-in user has no Firestore doc
//   • Recent Admin Actions reads last 4 entries from
//     activityLogs collection (same source as screen6)
//   • Everything else unchanged: permissions grid, toggles,
//     sign-out button, version footer
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_theme.dart';
import '../../screens/screen2_login.dart';

// ── Data models ───────────────────────────────────────────────
class _InfoRow {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool mono;
  const _InfoRow(this.icon, this.iconColor, this.label, this.value,
      {this.mono = false});
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
  _ToggleRow(this.icon, this.iconColor, this.title, this.sub,
      {required this.on});
}

class _LiveLogRow {
  final Color dot;
  final String text;
  final DateTime? timestamp;

  const _LiveLogRow({required this.dot, required this.text, this.timestamp});

  String get timeLabel {
    if (timestamp == null) return '—';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return '${diff.inHours}h ago';
    if (diff.inDays < 30)   return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 30}mo ago';
  }

  static Color _dotFor(String cat) {
    switch (cat) {
      case 'user':   return AC.green;
      case 'poi':    return AC.gold;
      case 'trip':   return AC.ocean;
      default:       return AC.purple;
    }
  }

  factory _LiveLogRow.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d   = doc.data();
    final cat = (d['category'] as String?)?.toLowerCase() ?? 'system';
    final title = d['title'] as String? ?? '—';
    final sub   = d['sub']   as String? ?? '';
    return _LiveLogRow(
      dot:       _dotFor(cat),
      text:      sub.isNotEmpty ? '$title · $sub' : title,
      timestamp: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});
  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {

  // ── Account data ──────────────────────────────────────────────
  String _displayName   = 'Nur Fatini';
  String _email         = 'fatini@andamove.com';
  String _adminId       = 'ADMIN-0042';
  String _memberSince   = '4 August 2025';
  bool   _accountLoaded = false;

  // ── Recent actions ────────────────────────────────────────────
  List<_LiveLogRow> _recentLogs  = [];
  bool              _logsLoaded  = false;

  // ── Permissions (static — role-based access is out of FYP scope)
  static final _perms = [
    _PermTag('Manage POIs',    AC.greenTint,  AC.green,  Icons.check_rounded),
    _PermTag('Manage Users',   AC.greenTint,  AC.green,  Icons.check_rounded),
    _PermTag('View Analytics', AC.greenTint,  AC.green,  Icons.check_rounded),
    _PermTag('Ban Users',      AC.greenTint,  AC.green,  Icons.check_rounded),
    _PermTag('Export Data',    AC.oceanTint,  AC.ocean,  Icons.check_rounded),
    _PermTag('Billing',        AC.coralTint,  AC.coral,  Icons.close_rounded),
  ];

  // ── Console toggles ───────────────────────────────────────────
  final _toggles = [
    _ToggleRow(Icons.notifications_rounded, AC.ocean,
        'Alert Notifications', 'New users, flagged reports, POI submissions',
        on: true),
    _ToggleRow(Icons.shield_rounded, AC.purple,
        '2FA Authentication', 'Required on every login',
        on: true),
    _ToggleRow(Icons.schedule_rounded, AC.gold,
        'Session Timeout', 'Auto-logout after 30 minutes',
        on: true),
  ];

  @override
  void initState() {
    super.initState();
    _loadAccount();
    _loadRecentLogs();
  }

  // ── Load Firebase Auth + Firestore account data ───────────────
  Future<void> _loadAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _accountLoaded = true);
        return;
      }

      // Use Auth display name / email as immediate fallback
      String name  = user.displayName ?? _displayName;
      String email = user.email       ?? _email;

      // Try to read richer data from Firestore users doc
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          name  = doc.data()?['name']  as String? ?? name;
          email = doc.data()?['email'] as String? ?? email;
        }
      } catch (_) {}

      // Derive initials from name
      final initials = name.trim().isNotEmpty
          ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
          : 'AD';

      // Format member since from Auth createdAt
      final created = user.metadata.creationTime;
      String since = _memberSince;
      if (created != null) {
        const months = ['Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'];
        since = '${created.day} ${months[created.month - 1]} ${created.year}';
      }

      if (mounted) {
        setState(() {
          _displayName   = name;
          _email         = email;
          _adminId       = 'ADMIN-${user.uid.substring(0, 6).toUpperCase()}';
          _memberSince   = since;
          _accountLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _accountLoaded = true);
    }
  }

  // ── Load last 4 activity log entries ─────────────────────────
  Future<void> _loadRecentLogs() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('activityLogs')
          .orderBy('createdAt', descending: true)
          .limit(4)
          .get();
      if (mounted) {
        setState(() {
          _recentLogs = snap.docs.map(_LiveLogRow.fromDoc).toList();
          _logsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _logsLoaded = true);
    }
  }

  // ── Derive initials from display name ─────────────────────────
  String get _initials {
    final parts = _displayName.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return 'AD';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ── Account detail rows (built dynamically) ───────────────────
  List<_InfoRow> get _accountRows => [
    _InfoRow(Icons.person_rounded,          AC.ocean,  'Full Name', _displayName),
    _InfoRow(Icons.mail_rounded,            AC.gold,   'Email',     _email),
    _InfoRow(Icons.badge_rounded,           AC.purple, 'Admin ID',  _adminId,  mono: true),
    _InfoRow(Icons.calendar_today_rounded,  AC.green,  'Since',     _memberSince),
  ];

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          _buildHero(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                children: [
                  _buildSection(
                    icon: Icons.person_rounded,
                    iconColor: AC.ocean,
                    title: 'Account Details',
                    child: Column(
                      children: _accountRows.map(_buildInfoRow).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    icon: Icons.shield_rounded,
                    iconColor: AC.purple,
                    title: 'Permissions',
                    child: _buildPermissionsGrid(),
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    icon: Icons.settings_rounded,
                    iconColor: AC.gold,
                    title: 'Console Settings',
                    child: Column(
                      children: _toggles.asMap().entries
                          .map((e) => _buildToggleRow(e.key, e.value))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    icon: Icons.assignment_rounded,
                    iconColor: AC.coral,
                    title: 'Recent Admin Actions',
                    child: _buildRecentActions(),
                  ),
                  const SizedBox(height: 20),
                  _buildSignOutBtn(),
                  const SizedBox(height: 14),
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

  // ══════════════════════════════════════════════════════════════
  // HERO
  // ══════════════════════════════════════════════════════════════
  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AC.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16, right: 16, bottom: 20,
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AC.ocean, AC.oceanMid],
              ),
              border: Border.all(
                  color: Colors.white.withOpacity(0.15), width: 2),
            ),
            child: Center(
              child: Text(
                _initials,
                style: adminUi(size: 24, weight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(_displayName,
              style: adminDisplay(size: 20, color: Colors.white)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AC.ocean.withOpacity(0.20),
              borderRadius: BorderRadius.circular(AR.full),
              border: Border.all(color: AC.ocean.withOpacity(0.40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, size: 12,
                    color: AC.oceanMid),
                const SizedBox(width: 5),
                Text('Super Admin',
                    style: adminUi(size: 12, weight: FontWeight.w700,
                        color: AC.oceanMid)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _adminId,
            style: adminMono(size: 11,
                color: Colors.white.withOpacity(0.35)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SECTION WRAPPER
  // ══════════════════════════════════════════════════════════════
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
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AR.md),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: adminUi(size: 14, weight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1, color: AC.borderLight),
          child,
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // INFO ROW
  // ══════════════════════════════════════════════════════════════
  Widget _buildInfoRow(_InfoRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AC.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: row.iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AR.md),
            ),
            child: Icon(row.icon, size: 15, color: row.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(row.label,
                style: adminUi(size: 11, weight: FontWeight.w600,
                    color: AC.text3)),
          ),
          // Loading shimmer while account data loads
          !_accountLoaded
              ? Container(
                  width: 80, height: 14,
                  decoration: BoxDecoration(
                    color: AC.surface2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
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

  // ══════════════════════════════════════════════════════════════
  // PERMISSIONS GRID
  // ══════════════════════════════════════════════════════════════
  Widget _buildPermissionsGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _perms.map((p) => Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius: BorderRadius.circular(AR.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(p.icon, size: 13, color: p.fg),
              const SizedBox(width: 5),
              Text(p.label,
                  style: adminUi(size: 11, weight: FontWeight.w700,
                      color: p.fg)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // CONSOLE TOGGLES
  // ══════════════════════════════════════════════════════════════
  Widget _buildToggleRow(int index, _ToggleRow row) {
    return GestureDetector(
      onTap: () => setState(() => row.on = !row.on),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AC.borderLight)),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: row.iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AR.md),
              ),
              child: Icon(row.icon, size: 17, color: row.iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.title,
                      style: adminUi(size: 13, weight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(row.sub,
                      style: adminUi(size: 11, color: AC.text2)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 24,
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
                  width: 18, height: 18,
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

  // ══════════════════════════════════════════════════════════════
  // RECENT ADMIN ACTIONS — live from activityLogs
  // ══════════════════════════════════════════════════════════════
  Widget _buildRecentActions() {
    if (!_logsLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(
              color: AC.ocean, strokeWidth: 2),
        ),
      );
    }

    if (_recentLogs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 16, horizontal: 14),
        child: Text(
          'No admin actions logged yet',
          style: adminUi(size: 12, color: AC.text3),
        ),
      );
    }

    return Column(
      children: _recentLogs.asMap().entries.map((e) {
        final isLast = e.key == _recentLogs.length - 1;
        return _buildLogRow(e.value, isLast: isLast);
      }).toList(),
    );
  }

  Widget _buildLogRow(_LiveLogRow row, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AC.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: row.dot),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(row.text,
                style: adminUi(size: 12, weight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(row.timeLabel,
              style: adminMono(size: 10, color: AC.text3)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SIGN OUT
  // ══════════════════════════════════════════════════════════════
  Widget _buildSignOutBtn() {
    return GestureDetector(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      },
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
            Text('Sign Out',
                style: adminUi(size: 14, weight: FontWeight.w700,
                    color: AC.coral)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // VERSION FOOTER
  // ══════════════════════════════════════════════════════════════
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
              style: adminUi(size: 11, weight: FontWeight.w700,
                  color: AC.oceanMid),
            ),
            const TextSpan(text: ' · FYP 2026'),
          ],
        ),
      ),
    );
  }
}