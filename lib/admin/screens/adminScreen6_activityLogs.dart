// ============================================================
// AndaMove Admin — Screen 6: Activity Logs
// File: lib/admin/screens/adminScreen6_activityLogs.dart
//
// Full-screen activity log view navigated from
// Dashboard → "All logs →" link.
//
// Features:
//   • AdminTopNavPage with back button
//   • Filter chip row (All / Users / POIs / Trips / System)
//   • Scrollable log list with coloured icon + title + sub + time
//   • Each log entry has a date divider when the day changes
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin_theme.dart';

// ── Data model ────────────────────────────────────────────────
class _LogEntry {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   sub;
  final String   time;
  final String   category; // user / poi / trip / system
  const _LogEntry({
    required this.icon, required this.iconColor,
    required this.title, required this.sub,
    required this.time, required this.category,
  });
}

// ── Main screen ───────────────────────────────────────────────
class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});
  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {

  int _filterIndex = 0;
  final _filters = ['All', 'Users', 'POIs', 'Trips', 'System'];

  static final _logs = [
    // ── Today ──
    _LogEntry(
      icon: Icons.person_add_rounded, iconColor: AC.green,
      title: 'New user registered',
      sub: 'tourist@email.com · Tourist',
      time: '2m ago', category: 'user',
    ),
    _LogEntry(
      icon: Icons.map_rounded, iconColor: AC.ocean,
      title: 'Trip generated',
      sub: 'Phi Phi Escape · 5 stops · Boat',
      time: '14m ago', category: 'trip',
    ),
    _LogEntry(
      icon: Icons.location_on_rounded, iconColor: AC.gold,
      title: 'New POI submitted',
      sub: 'Surin Beach Resort · Pending review',
      time: '1h ago', category: 'poi',
    ),
    _LogEntry(
      icon: Icons.check_circle_rounded, iconColor: AC.green,
      title: 'POI approved',
      sub: 'Surin Beach Resort → Active',
      time: '2h ago', category: 'poi',
    ),
    _LogEntry(
      icon: Icons.block_rounded, iconColor: AC.coral,
      title: 'User banned',
      sub: 'kevin@email.com · Reason: Spam reviews',
      time: '5h ago', category: 'user',
    ),
    // ── Yesterday ──
    _LogEntry(
      icon: Icons.visibility_off_rounded, iconColor: AC.amber,
      title: 'POI hidden',
      sub: 'Sunset Rooftop Bar → Hidden',
      time: '1d ago', category: 'poi',
    ),
    _LogEntry(
      icon: Icons.person_add_rounded, iconColor: AC.green,
      title: 'New user registered',
      sub: 'arjun@email.in · Tourist',
      time: '1d ago', category: 'user',
    ),
    _LogEntry(
      icon: Icons.map_rounded, iconColor: AC.ocean,
      title: 'Trip generated',
      sub: 'Temple Hopper · 4 stops · Car',
      time: '1d ago', category: 'trip',
    ),
    // ── 2 days ago ──
    _LogEntry(
      icon: Icons.download_rounded, iconColor: AC.ocean,
      title: 'Data exported',
      sub: 'User report CSV · 3,841 records',
      time: '2d ago', category: 'system',
    ),
    _LogEntry(
      icon: Icons.edit_rounded, iconColor: AC.ocean,
      title: 'POI updated',
      sub: 'The Big Buddha · Description edited',
      time: '2d ago', category: 'poi',
    ),
    _LogEntry(
      icon: Icons.person_add_rounded, iconColor: AC.green,
      title: 'New user registered',
      sub: 'marie@email.fr · Tourist',
      time: '2d ago', category: 'user',
    ),
    _LogEntry(
      icon: Icons.settings_rounded, iconColor: AC.purple,
      title: 'System setting changed',
      sub: 'Session timeout → 30 minutes',
      time: '3d ago', category: 'system',
    ),
  ];

  List<_LogEntry> get _filteredLogs {
    if (_filterIndex == 0) return _logs;
    final cat = _filters[_filterIndex].toLowerCase();
    // Map plural filter labels to singular categories
    final catKey = switch (cat) {
      'users' => 'user',
      'pois'  => 'poi',
      'trips' => 'trip',
      _       => cat,
    };
    return _logs.where((l) => l.category == catKey).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;

    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          // ── Top nav ──
          AdminTopNavPage(title: 'Activity Logs'),

          // ── Filter chips ──
          _buildFilterChips(),

          // ── Log count strip ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AC.surface,
              border: Border(
                  bottom: BorderSide(color: AC.borderLight)),
            ),
            child: Text(
              '${filtered.length} log entries',
              style: adminUi(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AC.text3),
            ),
          ),

          // ── Scrollable log list ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _buildLogCard(filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chip row ───────────────────────────────────────────
  Widget _buildFilterChips() {
    return Container(
      color: AC.navy,
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == _filterIndex;
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
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
                _filters[i],
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

  // ── Individual log card ───────────────────────────────────────
  Widget _buildLogCard(_LogEntry log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(AR.card),
        border: Border.all(color: AC.borderLight),
        boxShadow: aShadowSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: log.iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AR.md),
            ),
            child: Icon(log.icon, size: 16,
                color: log.iconColor),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.title,
                    style: adminUi(
                        size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(log.sub,
                    style: adminUi(
                        size: 11, color: AC.text2)),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Time
          Text(log.time,
              style: adminMono(size: 10, color: AC.text3)),
        ],
      ),
    );
  }
}