// ============================================================
// AndaMove Admin — Screen 4: Manage Users
// File: lib/admin/screens/adminScreen4_manageUsers.dart
//
// FIRESTORE-WIRED VERSION:
//   • Reads live from users/{uid} via StreamBuilder
//   • Tabs: All / Active / Suspended / Recent (last 7 days)
//   • Suspend: writes { status: 'suspended' } to user doc
//   • Unsuspend: writes { status: 'active' }
//   • Delete: removes Firestore doc (auth account persists —
//     delete confirmation sheet warns admin about this)
//   • Lazy migration: user docs without a 'status' field
//     are treated as 'active' (no backfill needed)
//   • UI matches adminScreen2_managePOI exactly
//     (navy search, chip row, stats strip, card style)
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_theme.dart';

// ══════════════════════════════════════════════════════════════
// DATA MODEL — wraps a Firestore user doc with UI helpers
// ══════════════════════════════════════════════════════════════
enum UserStatus { active, suspended }

class _UserDoc {
  final String uid;
  final String name;
  final String email;
  final String country;
  final String phone;
  final UserStatus status;
  final DateTime? createdAt;

  const _UserDoc({
    required this.uid,
    required this.name,
    required this.email,
    required this.country,
    required this.phone,
    required this.status,
    this.createdAt,
  });

  factory _UserDoc.fromSnap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final statusStr = (d['status'] as String?)?.toLowerCase() ?? 'active';
    return _UserDoc(
      uid: doc.id,
      name: (d['name'] as String?)?.trim().isNotEmpty == true
          ? d['name'] as String
          : 'Unnamed User',
      email: d['email'] as String? ?? '—',
      country: d['country'] as String? ?? '—',
      phone: d['phone'] as String? ?? '',
      status: statusStr == 'suspended' ? UserStatus.suspended : UserStatus.active,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// First letter of name for avatar fallback
  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  /// Gradient derived deterministically from uid so the same user
  /// always gets the same avatar colour across rebuilds/sessions.
  Gradient get avatarGrad {
    const palettes = <List<Color>>[
      [AC.ocean, AC.oceanMid],
      [AC.green, Color(0xFF4ADE80)],
      [AC.gold, AC.goldLight],
      [AC.purple, Color(0xFFA78BFA)],
      [AC.coral, Color(0xFFF97316)],
      [AC.amber, Color(0xFFFBBF24)],
    ];
    final hash = uid.hashCode.abs();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: palettes[hash % palettes.length],
    );
  }

  /// "Recent" = created within the last 7 days.
  /// Users without a createdAt are never considered recent.
  bool get isRecent {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt!).inDays < 7;
  }

  /// "3 days ago", "2h ago", "just now" — for the right-hand time column.
  /// Returns an empty string if createdAt is missing.
  String get joinedLabel {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  int _filterTab = 0;
  final _filterTabs = ['All', 'Active', 'Suspended', 'Recent'];
  String _searchQuery = '';

  /// Firestore stream — orders by createdAt desc so new signups
  /// appear at the top. Users without createdAt fall to the bottom
  /// of the list (Firestore places nulls last when desc).
  Stream<List<_UserDoc>> get _usersStream {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_UserDoc.fromSnap).toList());
  }

  // ──────────────────────────────────────────────────────────
  // FILTER + SEARCH
  // ──────────────────────────────────────────────────────────
  List<_UserDoc> _applyFilters(List<_UserDoc> users) {
    return users.where((u) {
      final matchesTab = switch (_filterTab) {
        0 => true,
        1 => u.status == UserStatus.active,
        2 => u.status == UserStatus.suspended,
        3 => u.isRecent,
        _ => true,
      };
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.country.toLowerCase().contains(q);
      return matchesTab && matchesSearch;
    }).toList();
  }

  // ──────────────────────────────────────────────────────────
  // FIRESTORE WRITES
  // ──────────────────────────────────────────────────────────
  Future<void> _suspendUser(_UserDoc u) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .update({'status': 'suspended'});
      if (mounted) _snack('Suspended "${u.name}"', AC.amber);
    } catch (e) {
      if (mounted) _snack('Failed to suspend user', AC.coral);
    }
  }

  Future<void> _unsuspendUser(_UserDoc u) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .update({'status': 'active'});
      if (mounted) _snack('Reactivated "${u.name}"', AC.green);
    } catch (e) {
      if (mounted) _snack('Failed to reactivate user', AC.coral);
    }
  }

  Future<void> _deleteUser(_UserDoc u) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .delete();
      if (mounted) _snack('Deleted "${u.name}"', AC.coral);
    } catch (e) {
      if (mounted) _snack('Failed to delete user', AC.coral);
    }
  }

  // ──────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          AdminTopNavPage(title: 'Manage Users', showBack: false),
          _buildSearchRow(),
          _buildFilterChips(),

          Expanded(
            child: StreamBuilder<List<_UserDoc>>(
              stream: _usersStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                if (snap.hasError) {
                  return _buildErrorState(snap.error.toString());
                }
                final all = snap.data ?? [];
                final filtered = _applyFilters(all);

                return Column(
                  children: [
                    _buildStatsStrip(all),
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyState(all.isEmpty)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildUserCard(filtered[i]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),

          AdminBottomNav(activeIndex: 2),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SEARCH ROW — matches adminScreen2_managePOI exactly
  // ══════════════════════════════════════════════════════════
  Widget _buildSearchRow() {
    return Container(
      color: AC.navy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AR.full),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 15, color: Colors.white.withOpacity(0.40)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: adminUi(size: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search users by name, email, country…',
                  hintStyle: adminUi(size: 13, color: Colors.white.withOpacity(0.40)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _searchQuery = ''),
                child: Icon(Icons.close_rounded, size: 15, color: Colors.white.withOpacity(0.60)),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FILTER CHIPS — matches adminScreen2_managePOI exactly
  // ══════════════════════════════════════════════════════════
  Widget _buildFilterChips() {
    return Container(
      color: AC.navy,
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        itemCount: _filterTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == _filterTab;
          return GestureDetector(
            onTap: () => setState(() => _filterTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                _filterTabs[i],
                style: adminUi(
                  size: 12,
                  weight: FontWeight.w700,
                  color: active ? AC.oceanMid : Colors.white.withOpacity(0.50),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // STATS STRIP — 4 live counts from current snapshot
  // ══════════════════════════════════════════════════════════
  Widget _buildStatsStrip(List<_UserDoc> users) {
    final total = users.length;
    final active = users.where((u) => u.status == UserStatus.active).length;
    final suspended = users.where((u) => u.status == UserStatus.suspended).length;
    final recent = users.where((u) => u.isRecent).length;

    final items = [
      ('$total', 'Total', AC.text1),
      ('$active', 'Active', AC.green),
      ('$recent', 'New 7d', AC.ocean),
      ('$suspended', 'Suspended', AC.amber),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AC.surface,
        border: Border(bottom: BorderSide(color: AC.borderLight)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        items[i].$1,
                        style: adminMono(size: 16, color: items[i].$3),
                      ),
                      Text(
                        items[i].$2,
                        style: adminUi(
                          size: 9,
                          weight: FontWeight.w700,
                          color: AC.text3,
                        ).copyWith(letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: AC.borderLight,
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // LOADING / ERROR / EMPTY STATES
  // ══════════════════════════════════════════════════════════
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AC.ocean,
        strokeWidth: 2.5,
      ),
    );
  }

  Widget _buildErrorState(String err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 36, color: AC.coral),
            const SizedBox(height: 10),
            Text(
              'Couldn\'t load users',
              style: adminUi(size: 14, weight: FontWeight.w700, color: AC.text1),
            ),
            const SizedBox(height: 4),
            Text(
              err,
              style: adminUi(size: 11, color: AC.text3),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noUsersAtAll) {
    final title = noUsersAtAll ? 'No users yet' : 'No users match';
    final sub = noUsersAtAll
        ? 'New signups will appear here in real time'
        : 'Try a different search or filter';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search_rounded, size: 32, color: AC.text3),
          const SizedBox(height: 10),
          Text(
            title,
            style: adminUi(size: 14, weight: FontWeight.w600, color: AC.text2),
          ),
          const SizedBox(height: 4),
          Text(sub, style: adminUi(size: 12, color: AC.text3)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // USER CARD
  // ══════════════════════════════════════════════════════════
  Widget _buildUserCard(_UserDoc u) {
    final isSuspended = u.status == UserStatus.suspended;

    return Container(
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(AR.card),
        border: Border.all(color: AC.borderLight),
        boxShadow: aShadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (isSuspended)
            _buildBanner(
              icon: Icons.block_rounded,
              iconColor: AC.amber,
              bgColor: AC.amberTint,
              text: 'Suspended — tap "Reactivate" to restore access',
            ),

          Opacity(
            opacity: isSuspended ? 0.65 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: u.avatarGrad,
                    ),
                    child: Center(
                      child: Text(
                        u.initial,
                        style: adminUi(
                          size: 16,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                u.name,
                                style: adminUi(size: 13, weight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (u.isRecent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AC.greenTint,
                                  borderRadius: BorderRadius.circular(AR.full),
                                ),
                                child: Text(
                                  'NEW',
                                  style: adminUi(
                                    size: 9,
                                    weight: FontWeight.w800,
                                    color: AC.green,
                                  ).copyWith(letterSpacing: 0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.mail_outline_rounded, size: 11, color: AC.text3),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                u.email,
                                style: adminUi(size: 11, color: AC.text2),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.language_rounded, size: 11, color: AC.text3),
                            const SizedBox(width: 3),
                            Text(u.country, style: adminUi(size: 11, color: AC.text2)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status dot + joined time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSuspended ? AC.amber : AC.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSuspended ? 'Suspended' : 'Active',
                            style: adminUi(
                              size: 10,
                              weight: FontWeight.w700,
                              color: isSuspended ? AC.amber : AC.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (u.joinedLabel.isNotEmpty)
                        Text(
                          'Joined ${u.joinedLabel}',
                          style: adminUi(size: 11, color: AC.text3),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AC.borderLight),
          _buildActions(u),
        ],
      ),
    );
  }

  Widget _buildBanner({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        border: Border(
          left: BorderSide(color: iconColor, width: 3),
          bottom: const BorderSide(color: AC.borderLight),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: adminUi(size: 11, color: iconColor)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // ACTION BUTTONS — View / Suspend-Reactivate / Delete
  // Matches adminScreen2_managePOI action strip style
  // ══════════════════════════════════════════════════════════
  Widget _buildActions(_UserDoc u) {
    final isSuspended = u.status == UserStatus.suspended;

    final acts = <(IconData, String, Color, VoidCallback)>[
      (
        Icons.visibility_rounded,
        'View',
        AC.ocean,
        () => _showUserDetail(u),
      ),
      if (isSuspended)
        (
          Icons.check_circle_rounded,
          'Reactivate',
          AC.green,
          () => _unsuspendUser(u),
        )
      else
        (
          Icons.block_rounded,
          'Suspend',
          AC.amber,
          () => _confirmSuspend(u),
        ),
      (
        Icons.delete_rounded,
        'Delete',
        AC.coral,
        () => _confirmDelete(u),
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        children: acts.asMap().entries.map((e) {
          final i = e.key;
          final a = e.value;
          return Expanded(
            child: GestureDetector(
              onTap: a.$4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    right: i < acts.length - 1
                        ? const BorderSide(color: AC.borderLight)
                        : BorderSide.none,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(a.$1, size: 16, color: a.$3),
                    const SizedBox(height: 3),
                    Text(
                      a.$2,
                      style: adminUi(
                        size: 11,
                        weight: FontWeight.w700,
                        color: a.$3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // DETAIL SHEET — read-only view of user doc
  // ══════════════════════════════════════════════════════════
  void _showUserDetail(_UserDoc u) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AC.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AR.xl)),
        ),
        padding: EdgeInsets.fromLTRB(
          20, 12, 20,
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AC.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Avatar + name
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: u.avatarGrad,
                  ),
                  child: Center(
                    child: Text(
                      u.initial,
                      style: adminUi(
                        size: 22,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: adminDisplay(size: 18)),
                      const SizedBox(height: 2),
                      Text(
                        u.status == UserStatus.suspended ? 'Suspended' : 'Active',
                        style: adminUi(
                          size: 12,
                          weight: FontWeight.w700,
                          color: u.status == UserStatus.suspended ? AC.amber : AC.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _detailRow(Icons.badge_rounded, AC.purple, 'UID', u.uid, mono: true),
            _detailRow(Icons.mail_rounded, AC.gold, 'Email', u.email),
            _detailRow(Icons.language_rounded, AC.ocean, 'Country', u.country),
            if (u.phone.isNotEmpty)
              _detailRow(Icons.phone_rounded, AC.green, 'Phone', u.phone),
            if (u.createdAt != null)
              _detailRow(
                Icons.calendar_today_rounded,
                AC.coral,
                'Joined',
                _formatDate(u.createdAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, Color iconColor, String label, String value,
      {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AR.md),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: adminUi(size: 11, weight: FontWeight.w600, color: AC.text3),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: mono ? adminMono(size: 12) : adminUi(size: 13, weight: FontWeight.w600),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ══════════════════════════════════════════════════════════
  // CONFIRMATION SHEETS
  // ══════════════════════════════════════════════════════════
  void _confirmSuspend(_UserDoc u) {
    _showConfirmSheet(
      icon: Icons.block_rounded,
      iconColor: AC.amber,
      title: 'Suspend user?',
      body: '"${u.name}" will lose access until you reactivate them.\n\n'
            'Their account data will be preserved.',
      confirmLabel: 'Suspend',
      confirmColor: AC.amber,
      onConfirm: () => _suspendUser(u),
    );
  }

  void _confirmDelete(_UserDoc u) {
    _showConfirmSheet(
      icon: Icons.delete_rounded,
      iconColor: AC.coral,
      title: 'Delete user?',
      body: '"${u.name}" will be permanently removed from Firestore.\n\n'
            'Note: their Firebase Auth account persists — they could '
            're-register with the same email.',
      confirmLabel: 'Delete',
      confirmColor: AC.coral,
      onConfirm: () => _deleteUser(u),
    );
  }

  void _showConfirmSheet({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AC.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AR.xl)),
        ),
        padding: EdgeInsets.fromLTRB(
          20, 16, 20,
          MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AC.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 12),
            Text(title, style: adminDisplay(size: 18)),
            const SizedBox(height: 8),
            Text(
              body,
              style: adminUi(size: 13, color: AC.text2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AC.surface,
                        borderRadius: BorderRadius.circular(AR.full),
                        border: Border.all(color: AC.border),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: adminUi(
                            size: 14,
                            weight: FontWeight.w700,
                            color: AC.text1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onConfirm();
                    },
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: confirmColor,
                        borderRadius: BorderRadius.circular(AR.full),
                      ),
                      child: Center(
                        child: Text(
                          confirmLabel,
                          style: adminUi(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SNACK
  // ══════════════════════════════════════════════════════════
  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Text(msg, style: adminUi(size: 13, color: Colors.white)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}