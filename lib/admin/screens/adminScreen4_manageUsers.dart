// ============================================================
// AndaMove Admin — Screen 4: Manage Users
// File: lib/admin/screens/adminScreen4_manageUsers.dart
//
// FIXED:
//   • Filter tabs now match adminScreen2_managePOI header style
//     — same height (44), same padding (16,6,16,6), same navy bg
//     — horizontal ListView.separated instead of centered Row
//     — removed 450px padding bug
//   • Search bar height matches POI screen (38)
//   • Consistent spacing between search → chips → strip
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin_theme.dart';

// ── Data models ───────────────────────────────────────────────
enum UserRole { tourist, business }

enum UserStatus { active, newUser, banned, reported }

class _User {
  final String initial;
  final Gradient avatarGrad;
  final String name;
  final String email;
  final String country;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final UserRole role;
  final UserStatus status;
  final String tripCount;
  final String? trips, pois, dist, rating;
  bool expanded;

  _User({
    required this.initial,
    required this.avatarGrad,
    required this.name,
    required this.email,
    required this.country,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.role,
    required this.status,
    required this.tripCount,
    this.trips,
    this.pois,
    this.dist,
    this.rating,
    this.expanded = false,
  });
}

final _mockUsers = [
  _User(
    initial: 'S',
    avatarGrad: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AC.ocean, AC.oceanMid],
    ),
    name: 'Sarah Johnson',
    email: 'sarah@email.com',
    country: 'UK',
    badge: 'Gold',
    badgeBg: AC.goldTint,
    badgeFg: AC.gold,
    role: UserRole.tourist,
    status: UserStatus.active,
    tripCount: '6 trips',
    trips: '6',
    pois: '18',
    dist: '86km',
    rating: '4.9★',
    expanded: true,
  ),
  _User(
    initial: 'A',
    avatarGrad: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AC.green, Color(0xFF4ADE80)],
    ),
    name: 'Arjun Patel',
    email: 'arjun@email.in',
    country: 'India',
    badge: 'Explorer',
    badgeBg: AC.oceanTint,
    badgeFg: AC.ocean,
    role: UserRole.tourist,
    status: UserStatus.active,
    tripCount: '3 trips',
  ),
  _User(
    initial: 'M',
    avatarGrad: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AC.gold, AC.goldLight],
    ),
    name: 'Marie Lefebvre',
    email: 'marie@email.fr',
    country: 'France',
    badge: 'New',
    badgeBg: AC.greenTint,
    badgeFg: AC.green,
    role: UserRole.tourist,
    status: UserStatus.newUser,
    tripCount: '0 trips',
  ),
  _User(
    initial: 'P',
    avatarGrad: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AC.purple, Color(0xFFA78BFA)],
    ),
    name: 'Phuket Beach Resort',
    email: 'info@phuketresort.th',
    country: 'Thailand',
    badge: 'Business',
    badgeBg: AC.purpleTint,
    badgeFg: AC.purple,
    role: UserRole.business,
    status: UserStatus.active,
    tripCount: '—',
    trips: '—',
    pois: '4',
    dist: '—',
    rating: '4.7★',
  ),
  _User(
    initial: 'K',
    avatarGrad: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF888888), Color(0xFFAAAAAA)],
    ),
    name: 'Kevin T.',
    email: 'kevin@email.com',
    country: 'USA',
    badge: 'Banned',
    badgeBg: AC.coralTint,
    badgeFg: AC.coral,
    role: UserRole.tourist,
    status: UserStatus.banned,
    tripCount: '2 trips',
  ),
  _User(
    initial: 'T',
    avatarGrad: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AC.purple, Color(0xFFA78BFA)],
    ),
    name: 'Takeshi Mori',
    email: 'take@email.jp',
    country: 'Japan',
    badge: 'Reported',
    badgeBg: AC.amberTint,
    badgeFg: AC.amber,
    role: UserRole.tourist,
    status: UserStatus.reported,
    tripCount: '1 trip',
  ),
];

// ── Main screen ───────────────────────────────────────────────
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  int _filterTab = 0;
  final _filterTabs = ['All', 'Tourist', 'Business', 'Banned'];
  String _searchQuery = '';

  List<_User> get _filteredUsers {
    return _mockUsers.where((u) {
      final matchesTab = switch (_filterTab) {
        0 => true,
        1 => u.role == UserRole.tourist && u.status != UserStatus.banned,
        2 => u.role == UserRole.business,
        3 => u.status == UserStatus.banned,
        _ => true,
      };
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.country.toLowerCase().contains(q);
      return matchesTab && matchesSearch;
    }).toList();
  }

  int get _totalCount => _mockUsers.length;
  int get _activeCount => _mockUsers
      .where((u) => u.status == UserStatus.active || u.status == UserStatus.newUser)
      .length;
  int get _newCount => _mockUsers.where((u) => u.status == UserStatus.newUser).length;
  int get _bannedCount => _mockUsers.where((u) => u.status == UserStatus.banned).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          AdminTopNavPage(title: 'Manage Users', showBack: false),

          // ── Search bar (matches POI screen exactly) ──
          _buildSearchRow(),

          // ── Filter chip row (NOW matches POI screen exactly) ──
          _buildFilterChips(),

          // ── Stats strip ──
          _buildStatsStrip(),

          // ── Scrollable user list ──
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildUserCard(filtered[i]),
                    ),
                  ),
          ),

          AdminBottomNav(activeIndex: 2),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SEARCH ROW — identical to adminScreen2_managePOI._searchRow()
  // Same: navy bg, 38px height, 16px horizontal padding,
  //       12px bottom padding, same border + bg opacity
  // ══════════════════════════════════════════════════════════════
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
            Icon(
              Icons.search_rounded,
              size: 15,
              color: Colors.white.withOpacity(0.40),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: adminUi(size: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search users…',
                  hintStyle: adminUi(
                    size: 13,
                    color: Colors.white.withOpacity(0.40),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // FILTER CHIPS — NOW identical to adminScreen2_managePOI._chipRow()
  //
  // FIXED from original:
  //   ✗ Was: Container with padding 450,0,450,20 + Row (broken)
  //   ✓ Now: Container height:44 + ListView.separated horizontal
  //          padding: fromLTRB(16,6,16,6) — matches POI exactly
  // ══════════════════════════════════════════════════════════════
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
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
                  color: active
                      ? AC.oceanMid
                      : Colors.white.withOpacity(0.50),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Stats strip ───────────────────────────────────────────────
  Widget _buildStatsStrip() {
    final items = [
      ('$_totalCount', 'Total', AC.text1),
      ('$_activeCount', 'Active', AC.green),
      ('$_newCount', 'New Today', AC.ocean),
      ('$_bannedCount', 'Banned', AC.coral),
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

  // ── Empty state ───────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search_rounded, size: 32, color: AC.text3),
          const SizedBox(height: 10),
          Text(
            'No users found',
            style: adminUi(size: 14, weight: FontWeight.w600, color: AC.text2),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search or filter',
            style: adminUi(size: 12, color: AC.text3),
          ),
        ],
      ),
    );
  }

  // ── User card ─────────────────────────────────────────────────
  Widget _buildUserCard(_User u) {
    return GestureDetector(
      onTap: () {
        if (u.trips != null) {
          setState(() => u.expanded = !u.expanded);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AC.surface,
          borderRadius: BorderRadius.circular(AR.card),
          border: Border.all(color: AC.borderLight),
          boxShadow: aShadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (u.status == UserStatus.banned)
              _buildBanner(
                iconColor: AC.coral,
                bgColor: AC.coralTint,
                text: 'Banned · Reason: Spam reviews · 10 Mar 2026',
              ),
            if (u.status == UserStatus.reported)
              _buildBanner(
                iconColor: AC.amber,
                bgColor: AC.amberTint,
                text: 'Reported by 2 users · Under review',
                icon: Icons.warning_rounded,
              ),

            Opacity(
              opacity: u.status == UserStatus.banned ? 0.55 : 1.0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
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

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  u.name,
                                  style: adminUi(
                                    size: 13,
                                    weight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: u.badgeBg,
                                  borderRadius: BorderRadius.circular(AR.full),
                                ),
                                child: Text(
                                  u.badge,
                                  style: adminUi(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: u.badgeFg,
                                  ),
                                ),
                              ),
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
                                color: _statusColor(u.status),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(u.status),
                              style: adminUi(
                                size: 10,
                                weight: FontWeight.w700,
                                color: _statusColor(u.status),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(u.tripCount, style: adminUi(size: 11, color: AC.text3)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (u.trips != null)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: u.expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const Divider(height: 1, color: AC.borderLight),
                    _buildExpandedDetail(u),
                  ],
                ),
              ),

            if (u.status == UserStatus.banned) _buildBannedActions(u),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner({
    required Color iconColor,
    required Color bgColor,
    required String text,
    IconData icon = Icons.block_rounded,
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

  Widget _buildExpandedDetail(_User u) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                for (final stat in [
                  (u.trips!, 'Trips'),
                  (u.pois!, 'POIs'),
                  (u.dist!, 'Dist.'),
                  (u.rating!, 'Rating'),
                ])
                  Expanded(
                    child: Column(
                      children: [
                        Text(stat.$1, style: adminMono(size: 15, weight: FontWeight.w500)),
                        Text(stat.$2, style: adminUi(size: 10, color: AC.text3)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _actionBtn(Icons.visibility_rounded, 'View Profile', AC.ocean, u),
              const SizedBox(width: 6),
              _actionBtn(Icons.mail_rounded, 'Message', AC.gold, u),
              const SizedBox(width: 6),
              _actionBtn(Icons.block_rounded, 'Ban', AC.coral, u),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, _User u) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AC.navy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              content: Text(
                '$label: "${u.name}" — coming soon',
                style: adminUi(size: 13, color: Colors.white),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AR.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: adminUi(size: 11, weight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannedActions(_User u) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 11),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AC.borderLight)),
      ),
      child: Row(
        children: [
          _actionBtn(Icons.check_circle_rounded, 'Unban User', AC.green, u),
          const SizedBox(width: 6),
          _actionBtn(Icons.delete_rounded, 'Delete', AC.coral, u),
        ],
      ),
    );
  }

  Color _statusColor(UserStatus s) => switch (s) {
    UserStatus.active => AC.green,
    UserStatus.newUser => AC.ocean,
    UserStatus.banned => AC.coral,
    UserStatus.reported => AC.amber,
  };

  String _statusLabel(UserStatus s) => switch (s) {
    UserStatus.active => 'Active',
    UserStatus.newUser => 'New',
    UserStatus.banned => 'Banned',
    UserStatus.reported => 'Flagged',
  };
}