// ============================================================
// AndaMove — Notification Screen
// File: lib/screens/notification_screen.dart
//
// Elements:
//   • Compact header — back button, "Notifications" title,
//     "Mark all read" text action
//   • Filter chip row — All / Trips / Nearby / System
//     (horizontally scrollable, animated selection)
//   • Grouped notification list — "Today" + "Yesterday" sections
//     each with date label and divider
//   • Notification tile — 4 types (Trip, Nearby, Alert, System)
//     each with colour-coded leading icon box, title, body,
//     relative time badge, and unread dot indicator
//   • Swipe-to-dismiss — DismissDirection.endToStart with
//     coral delete background
//   • Empty state — illustration + message when list is empty
//   • Mark-all-read animation — AnimatedSwitcher fades unread
//     dots to zero
//
// Dependencies (pubspec.yaml):
//   google_fonts: ^6.2.1
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════
// STEP 1 — COLOR TOKENS
// ══════════════════════════════════════════════════════════════
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
  static const Color bg          = Color(0xFFFBF8F3);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color surface2    = Color(0xFFF5F1EB);
  static const Color border      = Color(0xFFE6DDD1);
  static const Color borderLight = Color(0xFFF0EBE2);
  static const Color text1       = Color(0xFF0A1E28);
  static const Color text2       = Color(0xFF5A7A8A);
  static const Color text3       = Color(0xFF9AB0B8);
}

// ══════════════════════════════════════════════════════════════
// STEP 2 — RADIUS & SHADOW TOKENS
// ══════════════════════════════════════════════════════════════
class AppRadius {
  static const double sm   = 8;
  static const double md   = 14;
  static const double lg   = 20;
  static const double xl   = 28;
  static const double full = 9999;
}

BoxShadow get shadowSm => const BoxShadow(
  color: Color(0x0F0A1F28), blurRadius: 4, offset: Offset(0, 1));

BoxShadow get shadowMd => const BoxShadow(
  color: Color(0x140A1F28), blurRadius: 16, offset: Offset(0, 4));

// ══════════════════════════════════════════════════════════════
// STEP 3 — NOTIFICATION TYPE ENUM
// Drives icon, icon colour, and background tint per tile
// ══════════════════════════════════════════════════════════════
enum NotifType { trip, nearby, alert, system }

extension NotifTypeStyle on NotifType {
  Color get iconBg {
    switch (this) {
      case NotifType.trip:    return AppColors.goldTint;
      case NotifType.nearby:  return AppColors.oceanTint;
      case NotifType.alert:   return AppColors.coralTint;
      case NotifType.system:  return AppColors.surface2;
    }
  }

  Color get iconColor {
    switch (this) {
      case NotifType.trip:    return AppColors.gold;
      case NotifType.nearby:  return AppColors.oceanDeep;
      case NotifType.alert:   return AppColors.coral;
      case NotifType.system:  return AppColors.text2;
    }
  }

  IconData get icon {
    switch (this) {
      case NotifType.trip:    return Icons.map_rounded;
      case NotifType.nearby:  return Icons.location_on_rounded;
      case NotifType.alert:   return Icons.warning_amber_rounded;
      case NotifType.system:  return Icons.info_outline_rounded;
    }
  }

  // Filter label
  String get label {
    switch (this) {
      case NotifType.trip:    return 'Trips';
      case NotifType.nearby:  return 'Nearby';
      case NotifType.alert:   return 'Alerts';
      case NotifType.system:  return 'System';
    }
  }
}

// ══════════════════════════════════════════════════════════════
// STEP 4 — NOTIFICATION DATA MODEL
// ══════════════════════════════════════════════════════════════
class NotifItem {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final String time;
  bool isRead;

  NotifItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });
}

// ══════════════════════════════════════════════════════════════
// STEP 5 — NOTIFICATION SCREEN
// ══════════════════════════════════════════════════════════════
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {

  // ── Selected filter: null = All
  NotifType? _filter;

  // ── Animation controller for "Mark all read" fade
  late final AnimationController _markAllCtrl;

  // ── Notification data — today
  final List<NotifItem> _today = [
    NotifItem(
      id: 't1',
      type: NotifType.trip,
      title: 'Your itinerary is ready!',
      body: '5 stops planned for today — Kata Beach → Big Buddha → Chalong Temple and more.',
      time: '2 min ago',
      isRead: false,
    ),
    NotifItem(
      id: 't2',
      type: NotifType.nearby,
      title: 'Hidden gem nearby',
      body: 'Yanui Beach is only 800 m away and has a 4.8 ★ rating. Add it to your trip?',
      time: '18 min ago',
      isRead: false,
    ),
    NotifItem(
      id: 't3',
      type: NotifType.alert,
      title: 'Traffic alert on your route',
      body: 'Heavy congestion on Chao Fa West Rd. Estimated delay: 12 min. Tap to reroute.',
      time: '45 min ago',
      isRead: false,
    ),
    NotifItem(
      id: 't4',
      type: NotifType.trip,
      title: 'Stop 3 coming up',
      body: 'Chalong Temple is 1.2 km ahead. Expected arrival in 8 minutes.',
      time: '1 hr ago',
      isRead: true,
    ),
  ];

  // ── Notification data — yesterday
  final List<NotifItem> _yesterday = [
    NotifItem(
      id: 'y1',
      type: NotifType.nearby,
      title: 'Popular restaurant spotted',
      body: 'Rum Jungle Phuket is open now and just 350 m from your last stop.',
      time: 'Yesterday, 7:30 PM',
      isRead: true,
    ),
    NotifItem(
      id: 'y2',
      type: NotifType.system,
      title: 'AndaMove updated to v1.2',
      body: 'New: offline map support, improved tuk-tuk time estimates, and bug fixes.',
      time: 'Yesterday, 10:00 AM',
      isRead: true,
    ),
    NotifItem(
      id: 'y3',
      type: NotifType.trip,
      title: 'Trip summary ready',
      body: 'You visited 4 places and covered 14.3 km yesterday. View your recap!',
      time: 'Yesterday, 9:15 PM',
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _markAllCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _markAllCtrl.dispose();
    super.dispose();
  }

  // Count of unread in visible list
  int get _unreadCount {
    int count = 0;
    for (final n in _allVisible) {
      if (!n.isRead) count++;
    }
    return count;
  }

  List<NotifItem> get _allVisible {
    final all = [..._today, ..._yesterday];
    if (_filter == null) return all;
    return all.where((n) => n.type == _filter).toList();
  }

  List<NotifItem> get _todayVisible {
    if (_filter == null) return _today;
    return _today.where((n) => n.type == _filter).toList();
  }

  List<NotifItem> get _yesterdayVisible {
    if (_filter == null) return _yesterday;
    return _yesterday.where((n) => n.type == _filter).toList();
  }

  void _markAllRead() {
    setState(() {
      for (final n in _today)     n.isRead = true;
      for (final n in _yesterday) n.isRead = true;
    });
  }

  void _dismissNotif(String id) {
    setState(() {
      _today.removeWhere((n) => n.id == id);
      _yesterday.removeWhere((n) => n.id == id);
    });
  }

  void _tapNotif(NotifItem n) {
    setState(() => n.isRead = true);
  }

  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HEADER
  // back button | title + unread badge | "Mark all read"
  // ══════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.text1, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // Title + unread count badge
          Expanded(
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1,
                  ),
                ),
                if (_unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_unreadCount),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.oceanDeep, AppColors.oceanMid],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Mark all read
          if (_unreadCount > 0)
            GestureDetector(
              onTap: _markAllRead,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.oceanTint,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                      color: AppColors.oceanDeep.withOpacity(0.20)),
                ),
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.oceanDeep,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FILTER CHIP ROW
  // "All" + one chip per NotifType, horizontally scrollable
  // ══════════════════════════════════════════════════════════
  Widget _buildFilterRow() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          _filterChip(label: 'All', selected: _filter == null,
              onTap: () => setState(() => _filter = null)),
          const SizedBox(width: 8),
          // One chip per type
          ...NotifType.values.map((t) {
            final selected = _filter == t;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _filterChip(
                label: t.label,
                icon: t.icon,
                iconColor: selected ? Colors.white : t.iconColor,
                selected: selected,
                onTap: () => setState(() => _filter = t),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    IconData? icon,
    Color? iconColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: selected ? AppColors.oceanDeep : AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected
                ? AppColors.oceanDeep
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: iconColor ??
                      (selected ? Colors.white : AppColors.text2)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BODY — grouped list or empty state
  // ══════════════════════════════════════════════════════════
  Widget _buildBody() {
    final hasAny = _todayVisible.isNotEmpty || _yesterdayVisible.isNotEmpty;

    if (!hasAny) return _buildEmptyState();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (_todayVisible.isNotEmpty) ...[
          _sectionLabel('Today'),
          ..._todayVisible.map((n) => _buildTile(n)),
        ],
        if (_yesterdayVisible.isNotEmpty) ...[
          _sectionLabel('Yesterday'),
          ..._yesterdayVisible.map((n) => _buildTile(n)),
        ],
        // Hint at bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swipe_left_rounded,
                  size: 14, color: AppColors.text3),
              const SizedBox(width: 6),
              Text('Swipe left to dismiss',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.text3,
                    fontStyle: FontStyle.italic,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section label (e.g. "Today")
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.text3,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: AppColors.borderLight),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // NOTIFICATION TILE
  // Swipeable, tappable, colour-coded leading icon, unread dot
  // ══════════════════════════════════════════════════════════
  Widget _buildTile(NotifItem n) {
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _dismissNotif(n.id),

      // Red delete background revealed on swipe
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.coral,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_rounded,
                color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text('Remove',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
          ],
        ),
      ),

      child: GestureDetector(
        onTap: () => _tapNotif(n),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.isRead ? AppColors.surface : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: n.isRead
                  ? AppColors.borderLight
                  : AppColors.border,
              width: n.isRead ? 1 : 1.5,
            ),
            boxShadow: n.isRead ? [shadowSm] : [shadowMd],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Coloured icon box
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: n.type.iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(n.type.icon,
                    size: 22, color: n.type.iconColor),
              ),
              const SizedBox(width: 12),

              // ── Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: n.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                              color: AppColors.text1,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Unread dot
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: n.isRead
                              ? const SizedBox(
                                  key: ValueKey('read'),
                                  width: 8, height: 8)
                              : Container(
                                  key: const ValueKey('unread'),
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.oceanMid,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Body text
                    Text(
                      n.body,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: n.isRead
                            ? AppColors.text3
                            : AppColors.text2,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Bottom row: type badge + time
                    Row(
                      children: [
                        // Type label badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: n.type.iconBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            n.type.label.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: n.type.iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Time
                        Text(
                          n.time,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: AppColors.text3,
                          ),
                        ),

                        const Spacer(),

                        // Chevron (only for actionable types)
                        if (n.type == NotifType.trip ||
                            n.type == NotifType.nearby ||
                            n.type == NotifType.alert)
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: n.isRead
                                ? AppColors.text3
                                : AppColors.text2,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // EMPTY STATE
  // Shown when the filtered list is empty
  // ══════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    final bool isFiltered = _filter != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon circle
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: AppColors.text3,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isFiltered
                  ? 'No ${_filter!.label} notifications'
                  : 'All caught up!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              isFiltered
                  ? 'There are no notifications in this category right now.'
                  : 'You have no new notifications.\nEnjoy exploring Phuket! 🌊',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.text2,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            if (isFiltered) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => setState(() => _filter = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.oceanTint,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                        color: AppColors.oceanDeep.withOpacity(0.25)),
                  ),
                  child: Text(
                    'Show all notifications',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.oceanDeep,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
