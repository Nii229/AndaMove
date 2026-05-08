// ============================================================
// AndaMove Admin — Screen 1: Analytics Dashboard
// File: lib/admin/screens/adminScreen1_analyticsDashboard.dart
//
// UPDATED — Firestore-wired KPI cards + live Recent Activity:
//   • Total Users     → users collection count
//   • Trips Generated → counters/stats.tripCount (incremented
//                       by screen8 on every save)
//   • Active POIs     → pois where status == 'active' count
//   • New This Week   → users with createdAt in last 7 days
//   • Recent Activity → last 3 docs from activityLogs collection
//   • Top POIs table  → still hardcoded (view tracking is out
//                       of scope for FYP)
//   • Spark charts    → visual decoration only
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_theme.dart';
import 'adminScreen2_managePOI.dart';
import 'adminScreen6_activityLogs.dart';

// ══════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════
class _KpiCard {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String valueSuffix;
  final String label;
  final bool trendUp;
  final String trendText;
  final List<double> sparks;
  final Color sparkColor;
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    this.valueSuffix = '',
    required this.label,
    required this.trendUp,
    required this.trendText,
    required this.sparks,
    required this.sparkColor,
  });
}

class _PoiRow {
  final String rank;
  final Color dot;
  final String name;
  final String cat;
  final String views;
  final double barFraction;
  const _PoiRow(this.rank, this.dot, this.name, this.cat,
      this.views, this.barFraction);
}

// ══════════════════════════════════════════════════════════════
// LIVE STATS MODEL — holds all Firestore-loaded values
// ══════════════════════════════════════════════════════════════
class _LiveStats {
  final int totalUsers;
  final int tripsGenerated;
  final int activePois;
  final int newThisWeek;

  const _LiveStats({
    required this.totalUsers,
    required this.tripsGenerated,
    required this.activePois,
    required this.newThisWeek,
  });

  /// Fallback while loading
  static const loading = _LiveStats(
    totalUsers: 0,
    tripsGenerated: 0,
    activePois: 0,
    newThisWeek: 0,
  );
}

// ══════════════════════════════════════════════════════════════
// LIVE ACTIVITY LOG MODEL
// ══════════════════════════════════════════════════════════════
class _LiveActivityRow {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String sub;
  final DateTime? timestamp;

  const _LiveActivityRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.sub,
    this.timestamp,
  });

  String get timeLabel {
    if (timestamp == null) return '—';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 30}mo ago';
  }

  static IconData _iconFor(String category) {
    switch (category) {
      case 'user': return Icons.person_add_rounded;
      case 'trip': return Icons.map_rounded;
      case 'poi':  return Icons.location_on_rounded;
      default:     return Icons.settings_rounded;
    }
  }

  static Color _colorFor(String category) {
    switch (category) {
      case 'user':   return AC.green;
      case 'trip':   return AC.ocean;
      case 'poi':    return AC.gold;
      default:       return AC.purple;
    }
  }

  factory _LiveActivityRow.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final cat = d['category'] as String? ?? 'system';
    return _LiveActivityRow(
      icon: _iconFor(cat),
      iconColor: _colorFor(cat),
      title: d['title'] as String? ?? '—',
      sub: d['sub'] as String? ?? '',
      timestamp: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  // ── Month picker state ────────────────────────────────────────
  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;

  static final _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // ── Live data state ───────────────────────────────────────────
  _LiveStats _stats = _LiveStats.loading;
  List<_LiveActivityRow> _recentActivity = [];
  bool _statsLoaded = false;
  bool _activityLoaded = false;

  // ── Static Top POIs (view tracking out of FYP scope) ─────────
  static final _pois = [
    _PoiRow('01', AC.ocean,  'The Big Buddha',  'Culture · Karon',  '—', 1.00),
    _PoiRow('02', AC.gold,   'Old Phuket Town', 'Heritage · City',  '—', 0.74),
    _PoiRow('03', AC.coral,  'Kata Beach',      'Beach · Kata',     '—', 0.68),
    _PoiRow('04', AC.green,  'Wat Chalong',     'Temple · Chalong', '—', 0.52),
  ];

  // ── Spark data (visual decoration) ───────────────────────────
  static const _sparkSets = [
    [0.40, 0.55, 0.45, 0.70, 0.60, 0.85, 1.0],
    [0.50, 0.35, 0.65, 0.55, 0.75, 0.90, 1.0],
    [0.60, 0.60, 0.70, 0.75, 0.80, 0.90, 1.0],
    [0.40, 0.55, 0.70, 0.65, 0.80, 0.85, 1.0],
  ];

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadRecentActivity();
  }

  // ══════════════════════════════════════════════════════════════
  // FIRESTORE READS
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadStats() async {
    try {
      final db = FirebaseFirestore.instance;
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      // Run all three queries in parallel
      final results = await Future.wait([
        // 1. Total users
        db.collection('users').count().get(),

        // 2. Trips generated — from counters/stats doc
        db.collection('counters').doc('stats').get(),

        // 3. Active POIs
        db.collection('pois')
            .where('status', isEqualTo: 'active')
            .count()
            .get(),

        // 4. New users this week
        db.collection('users')
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
            .count()
            .get(),
      ]);

      final totalUsers      = (results[0] as AggregateQuerySnapshot).count ?? 0;
      final statsDoc        = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final tripsGenerated  = (statsDoc.data()?['tripCount'] as int?) ?? 0;
      final activePois      = (results[2] as AggregateQuerySnapshot).count ?? 0;
      final newThisWeek     = (results[3] as AggregateQuerySnapshot).count ?? 0;

      if (mounted) {
        setState(() {
          _stats = _LiveStats(
            totalUsers: totalUsers,
            tripsGenerated: tripsGenerated,
            activePois: activePois,
            newThisWeek: newThisWeek,
          );
          _statsLoaded = true;
        });
      }
    } catch (e) {
      // On error keep zeros — dashboard still renders
      if (mounted) setState(() => _statsLoaded = true);
    }
  }

  Future<void> _loadRecentActivity() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('activityLogs')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      if (mounted) {
        setState(() {
          _recentActivity =
              snap.docs.map(_LiveActivityRow.fromDoc).toList();
          _activityLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _activityLoaded = true);
    }
  }

  // ── Format large numbers: 3841 → "3,841" ─────────────────────
  String _fmt(int n) {
    if (n == 0 && !_statsLoaded) return '—';
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ── Build live KPI list ───────────────────────────────────────
  List<_KpiCard> get _kpis => [
    _KpiCard(
      icon: Icons.group_rounded,
      iconColor: AC.ocean,
      value: _fmt(_stats.totalUsers),
      label: 'Total Users',
      trendUp: true,
      trendText: '+${_stats.newThisWeek} this wk',
      sparks: _sparkSets[0].cast<double>(),
      sparkColor: AC.ocean,
    ),
    _KpiCard(
      icon: Icons.map_rounded,
      iconColor: AC.gold,
      value: _fmt(_stats.tripsGenerated),
      label: 'Trips Generated',
      trendUp: true,
      trendText: 'all time',
      sparks: _sparkSets[1].cast<double>(),
      sparkColor: AC.gold,
    ),
    _KpiCard(
      icon: Icons.location_on_rounded,
      iconColor: AC.coral,
      value: _fmt(_stats.activePois),
      label: 'Active POIs',
      trendUp: true,
      trendText: 'live count',
      sparks: _sparkSets[2].cast<double>(),
      sparkColor: AC.coral,
    ),
    _KpiCard(
      icon: Icons.fiber_new_rounded,
      iconColor: AC.green,
      value: _fmt(_stats.newThisWeek),
      label: 'New This Week',
      trendUp: _stats.newThisWeek > 0,
      trendText: 'users',
      sparks: _sparkSets[3].cast<double>(),
      sparkColor: AC.green,
    ),
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
          _buildTopNav(context),
          Expanded(
            child: RefreshIndicator(
              color: AC.ocean,
              onRefresh: () async {
                await Future.wait([_loadStats(), _loadRecentActivity()]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateHeader(),
                    const SizedBox(height: 14),
                    _buildKpiGrid(),
                    const SizedBox(height: 14),
                    _buildChartCard(),
                    const SizedBox(height: 14),
                    _buildTableCard(
                      title: 'Top POIs This Week',
                      link: 'View all →',
                      onLinkTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminPoiScreen()),
                      ),
                      child: Column(
                        children: _pois.map(_buildPoiRow).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildTableCard(
                      title: 'Recent Activity',
                      link: 'All logs →',
                      onLinkTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminLogsScreen()),
                      ),
                      child: _buildRecentActivitySection(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AdminBottomNav(activeIndex: 0),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TOP NAV
  // ══════════════════════════════════════════════════════════════
  Widget _buildTopNav(BuildContext context) {
    return Container(
      color: AC.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16, right: 16, bottom: 16,
      ),
      child: Row(
        children: [
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1.0,
              child: Image.asset(
                'assets/images/andamove_logo.png',
                width: 80, height: 80,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: 'Anda',
                  style: adminDisplay(size: 22, color: Colors.white)),
              TextSpan(text: 'Move',
                  style: adminDisplay(size: 22, color: AC.gold)),
            ]),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AC.ocean.withOpacity(0.20),
              borderRadius: BorderRadius.circular(AR.full),
              border: Border.all(color: AC.ocean.withOpacity(0.40)),
            ),
            child: Text(
              'ADMIN',
              style: adminUi(size: 9, weight: FontWeight.w800,
                  color: AC.oceanMid).copyWith(letterSpacing: 1.0),
            ),
          ),
          const Spacer(),
          // Refresh indicator
          GestureDetector(
            onTap: () async {
              await Future.wait([_loadStats(), _loadRecentActivity()]);
            },
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(AR.md),
                border: Border.all(
                    color: Colors.white.withOpacity(0.10)),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 17,
                color: _statsLoaded
                    ? Colors.white.withOpacity(0.70)
                    : AC.oceanMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // DATE HEADER
  // ══════════════════════════════════════════════════════════════
  Widget _buildDateHeader() {
    final monthLabel = '${_months[_selectedMonth - 1]} $_selectedYear';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Dashboard', style: adminDisplay(size: 20)),
        GestureDetector(
          onTap: _showMonthPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AC.surface,
              borderRadius: BorderRadius.circular(AR.full),
              border: Border.all(color: AC.border),
              boxShadow: aShadowSm,
            ),
            child: Row(
              children: [
                Text(monthLabel,
                    style: adminUi(size: 12, weight: FontWeight.w700,
                        color: AC.text2)),
                const SizedBox(width: 5),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14, color: AC.text3),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMonthPicker() {
    int tempMonth = _selectedMonth;
    int tempYear  = _selectedYear;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AC.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AR.xl)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).padding.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AC.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Select Month', style: adminDisplay(size: 18)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setModalState(() => tempYear--),
                    child: Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: AC.surface2,
                        borderRadius: BorderRadius.circular(AR.md),
                        border: Border.all(color: AC.borderLight)),
                      child: const Icon(Icons.chevron_left_rounded,
                          size: 20, color: AC.text2)),
                  ),
                  Text('$tempYear',
                      style: adminMono(size: 20, weight: FontWeight.w500)),
                  GestureDetector(
                    onTap: () => setModalState(() => tempYear++),
                    child: Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: AC.surface2,
                        borderRadius: BorderRadius.circular(AR.md),
                        border: Border.all(color: AC.borderLight)),
                      child: const Icon(Icons.chevron_right_rounded,
                          size: 20, color: AC.text2)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final m = i + 1;
                  final isSel = m == tempMonth;
                  return GestureDetector(
                    onTap: () => setModalState(() => tempMonth = m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSel ? AC.ocean : AC.surface2,
                        borderRadius: BorderRadius.circular(AR.md),
                        border: Border.all(
                            color: isSel ? AC.ocean : AC.borderLight)),
                      child: Center(child: Text(_months[i],
                          style: adminUi(size: 13,
                              weight: FontWeight.w700,
                              color: isSel ? Colors.white : AC.text2))),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMonth = tempMonth;
                    _selectedYear  = tempYear;
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity, height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AC.ocean, AC.oceanMid]),
                    borderRadius: BorderRadius.circular(AR.full),
                    boxShadow: [BoxShadow(
                        color: AC.ocean.withOpacity(0.30),
                        blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: Text('Apply',
                      style: adminUi(size: 14, weight: FontWeight.w700,
                          color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // KPI GRID
  // ══════════════════════════════════════════════════════════════
  Widget _buildKpiGrid() {
    final kpis = _kpis;
    return Column(
      children: [
        Row(children: [
          Expanded(child: _buildKpiCard(kpis[0])),
          const SizedBox(width: 10),
          Expanded(child: _buildKpiCard(kpis[1])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _buildKpiCard(kpis[2])),
          const SizedBox(width: 10),
          Expanded(child: _buildKpiCard(kpis[3])),
        ]),
      ],
    );
  }

  Widget _buildKpiCard(_KpiCard k) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(AR.card),
        border: Border.all(color: AC.borderLight),
        boxShadow: aShadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: k.iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AR.md),
                ),
                child: Icon(k.icon, size: 17, color: k.iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: k.trendUp ? AC.greenTint : AC.coralTint,
                  borderRadius: BorderRadius.circular(AR.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      k.trendUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 11,
                      color: k.trendUp ? AC.green : AC.coral,
                    ),
                    const SizedBox(width: 3),
                    Text(k.trendText,
                        style: adminUi(size: 10, weight: FontWeight.w800,
                            color: k.trendUp ? AC.green : AC.coral)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Loading shimmer vs real value
          !_statsLoaded
              ? Container(
                  width: 60, height: 24,
                  decoration: BoxDecoration(
                    color: AC.surface2,
                    borderRadius: BorderRadius.circular(AR.sm),
                  ),
                )
              : RichText(
                  text: TextSpan(children: [
                    TextSpan(text: k.value,
                        style: adminMono(size: 24)),
                    if (k.valueSuffix.isNotEmpty)
                      TextSpan(text: k.valueSuffix,
                          style: adminMono(size: 14, color: AC.text3)),
                  ]),
                ),
          Text(
            k.label.toUpperCase(),
            style: adminUi(size: 11, weight: FontWeight.w600,
                color: AC.text3).copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: k.sparks.asMap().entries.map((e) {
                final i = e.key;
                final h = e.value;
                final isLast = i == k.sparks.length - 1;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                    height: (h * 28).clamp(4.0, 28.0),
                    decoration: BoxDecoration(
                      color: isLast
                          ? k.sparkColor
                          : k.sparkColor.withOpacity(0.20 + h * 0.50),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
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

  // ══════════════════════════════════════════════════════════════
  // WEEKLY CHART CARD (visual only — real data needs Analytics)
  // ══════════════════════════════════════════════════════════════
  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AC.surface,
        borderRadius: BorderRadius.circular(AR.card),
        border: Border.all(color: AC.borderLight),
        boxShadow: aShadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Signups',
                  style: adminUi(size: 14, weight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AC.oceanTint,
                  borderRadius: BorderRadius.circular(AR.full),
                ),
                child: Text(
                  '${_stats.newThisWeek} new users',
                  style: adminUi(size: 10, weight: FontWeight.w700,
                      color: AC.ocean),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _WeeklyChartPainter(),
              size: const Size(double.infinity, 80),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Text(d,
                    style: adminMono(
                      size: 10,
                      color: d == 'Fri' ? AC.gold : AC.text3,
                      weight: d == 'Fri'
                          ? FontWeight.w700
                          : FontWeight.w400,
                    )))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TABLE CARD WRAPPER
  // ══════════════════════════════════════════════════════════════
  Widget _buildTableCard({
    required String title,
    required String link,
    required VoidCallback onLinkTap,
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
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: adminUi(size: 14, weight: FontWeight.w700)),
                GestureDetector(
                  onTap: onLinkTap,
                  child: Text(link,
                      style: adminUi(size: 12, weight: FontWeight.w700,
                          color: AC.ocean)),
                ),
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
  // POI ROW (static)
  // ══════════════════════════════════════════════════════════════
  Widget _buildPoiRow(_PoiRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AC.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(width: 16,
              child: Text(row.rank,
                  style: adminMono(size: 12, color: AC.text3),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 10),
          Container(width: 8, height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: row.dot)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name,
                    style: adminUi(size: 13, weight: FontWeight.w700)),
                Text(row.cat, style: adminUi(size: 10, color: AC.text3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(row.views, style: adminMono(size: 13)),
              const SizedBox(height: 3),
              Container(
                width: 60 * row.barFraction, height: 3,
                decoration: BoxDecoration(
                  color: row.dot.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // RECENT ACTIVITY — live from Firestore activityLogs collection
  // ══════════════════════════════════════════════════════════════
  Widget _buildRecentActivitySection() {
    if (!_activityLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
              color: AC.ocean, strokeWidth: 2.5),
        ),
      );
    }

    if (_recentActivity.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        child: Center(
          child: Text(
            'No activity logged yet',
            style: adminUi(size: 13, color: AC.text3),
          ),
        ),
      );
    }

    return Column(
      children: _recentActivity.map(_buildLiveActivityRow).toList(),
    );
  }

  Widget _buildLiveActivityRow(_LiveActivityRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AC.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: row.iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(row.icon, size: 15, color: row.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.title,
                    style: adminUi(size: 12, weight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(row.sub,
                    style: adminUi(size: 11, color: AC.text2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(row.timeLabel,
              style: adminMono(size: 10, color: AC.text3)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WEEKLY CHART PAINTER (unchanged)
// ══════════════════════════════════════════════════════════════
class _WeeklyChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = AC.borderLight
      ..strokeWidth = 1;
    for (final y in [20.0, 40.0, 60.0]) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final xs = [0, 51, 102, 153, 204, 255, 306, 358]
        .map((x) => x / 358 * w).toList();
    final ys = [65.0, 55, 45, 42, 35, 20, 10, 5]
        .map((y) => y / 80 * h).toList();

    Path linePath() {
      final p = Path()..moveTo(xs[0], ys[0]);
      for (int i = 1; i < xs.length; i++) {
        final cx = (xs[i - 1] + xs[i]) / 2;
        p.cubicTo(cx, ys[i - 1], cx, ys[i], xs[i], ys[i]);
      }
      return p;
    }

    final areaPath = linePath()
      ..lineTo(xs.last, h)
      ..lineTo(xs.first, h)
      ..close();
    final areaRect = Rect.fromLTWH(0, 0, w, h);
    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AC.ocean, Colors.transparent],
      ).createShader(areaRect)
      ..style = PaintingStyle.fill;
    canvas.saveLayer(areaRect, Paint()..color = Colors.white.withOpacity(0.15));
    canvas.drawPath(areaPath, areaPaint);
    canvas.restore();

    canvas.drawPath(linePath(), Paint()
      ..color = AC.ocean
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke);

    final dotPaint = Paint()..color = AC.ocean;
    for (final i in [1, 2, 3, 4, 6, 7]) {
      canvas.drawCircle(Offset(xs[i], ys[i]), 3.5, dotPaint);
    }
    canvas.drawCircle(Offset(xs[5], ys[5]), 4,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(xs[5], ys[5]), 4,
        Paint()..color = AC.gold..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(xs[5], ys[5]), 2.5,
        Paint()..color = AC.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}