// ============================================================
// AndaMove Admin — Screen 1: Analytics Dashboard
// File: lib/admin/screens/adminScreen1_analyticsDashboard.dart
//
// UPDATED:
//   • Bigger title with AndaMove logo in top nav
//   • Removed notification bell + pill tab bar (Overview/Traffic…)
//   • "View all →" on Top POIs → navigates to AdminPoiScreen
//   • "All logs →" on Recent Activity → navigates to AdminLogsScreen
//   • "Mar 2026" pill → shows month picker dialog
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin_theme.dart';
import 'adminScreen2_managePOI.dart';
import 'adminScreen6_activityLogs.dart';

// ── Data models ───────────────────────────────────────────────
class _KpiCard {
  final IconData icon;
  final Color    iconColor;
  final String   value;
  final String   valueSuffix;
  final String   label;
  final bool     trendUp;
  final String   trendText;
  final List<double> sparks;
  final Color    sparkColor;
  const _KpiCard({
    required this.icon, required this.iconColor,
    required this.value, this.valueSuffix = '',
    required this.label, required this.trendUp,
    required this.trendText, required this.sparks,
    required this.sparkColor,
  });
}

class _PoiRow {
  final String rank;
  final Color  dot;
  final String name;
  final String cat;
  final String views;
  final double barFraction;
  const _PoiRow(this.rank, this.dot, this.name,
      this.cat, this.views, this.barFraction);
}

class _ActivityRow {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   sub;
  final String   time;
  const _ActivityRow(this.icon, this.iconColor,
      this.title, this.sub, this.time);
}

// ── Main screen ───────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {

  // ── Selected month/year for the date filter pill ──
  int _selectedMonth = 3;   // March
  int _selectedYear  = 2026;

  static final _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static final _kpis = [
    _KpiCard(
      icon: Icons.group_rounded, iconColor: AC.ocean,
      value: '3,841', label: 'Total Users',
      trendUp: true, trendText: '+12%',
      sparks: [0.40, 0.55, 0.45, 0.70, 0.60, 0.85, 1.0],
      sparkColor: AC.ocean,
    ),
    _KpiCard(
      icon: Icons.map_rounded, iconColor: AC.gold,
      value: '1,247', label: 'Trips Generated',
      trendUp: true, trendText: '+8%',
      sparks: [0.50, 0.35, 0.65, 0.55, 0.75, 0.90, 1.0],
      sparkColor: AC.gold,
    ),
    _KpiCard(
      icon: Icons.location_on_rounded, iconColor: AC.coral,
      value: '142', label: 'Active POIs',
      trendUp: true, trendText: '+3',
      sparks: [0.60, 0.60, 0.70, 0.75, 0.80, 0.90, 1.0],
      sparkColor: AC.coral,
    ),
    _KpiCard(
      icon: Icons.schedule_rounded, iconColor: AC.purple,
      value: '4.2', valueSuffix: 'km',
      label: 'Avg Trip Dist.',
      trendUp: false, trendText: '-2%',
      sparks: [0.80, 0.70, 0.90, 0.60, 0.75, 0.85, 0.65],
      sparkColor: AC.purple,
    ),
  ];

  static final _pois = [
    _PoiRow('01', AC.ocean,  'The Big Buddha',   'Culture · Karon', '2,841', 1.00),
    _PoiRow('02', AC.gold,   'Old Phuket Town',  'Heritage · City', '2,103', 0.74),
    _PoiRow('03', AC.coral,  'Kata Beach',       'Beach · Kata',    '1,956', 0.68),
    _PoiRow('04', AC.green,  'Wat Chalong',      'Temple · Chalong','1,488', 0.52),
  ];

  static final _activity = [
    _ActivityRow(Icons.person_add_rounded, AC.green,
        'New user registered', 'tourist@email.com · Tourist', '2m ago'),
    _ActivityRow(Icons.map_rounded, AC.ocean,
        'Trip generated', 'Phi Phi Escape · 5 stops · Boat', '14m ago'),
    _ActivityRow(Icons.location_on_rounded, AC.gold,
        'New POI submitted', 'Surin Beach Resort · Pending review', '1h ago'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          // ── Top nav: logo + brand + admin badge (no tabs) ──
          _buildTopNav(context),

          // ── Scrollable body ──
          Expanded(
            child: SingleChildScrollView(
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
                      children: _pois
                          .map((p) => _buildPoiRow(p))
                          .toList(),
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
                    child: Column(
                      children: _activity
                          .map((a) => _buildActivityRow(a))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom nav ──
          AdminBottomNav(activeIndex: 0),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TOP NAV — Logo + Brand + Admin badge (tabs removed)
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
          // ── App logo (small, white tinted) ──
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1.0,
              child: Image.asset(
                'assets/images/andamove_logo.png',
                width: 80,
                height: 80,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Brand name (bigger) ──
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Anda',
                style: adminDisplay(
                    size: 22, color: Colors.white),
              ),
              TextSpan(
                text: 'Move',
                style: adminDisplay(
                    size: 22, color: AC.gold),
              ),
            ]),
          ),
          const SizedBox(width: 10),

          // ── Admin badge pill ──
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
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // DATE HEADER — Title + month picker pill
  // ══════════════════════════════════════════════════════════════
  Widget _buildDateHeader() {
    final monthLabel = '${_months[_selectedMonth - 1]} $_selectedYear';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Dashboard', style: adminDisplay(size: 20)),
        GestureDetector(
          onTap: () => _showMonthPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AC.surface,
              borderRadius: BorderRadius.circular(AR.full),
              border: Border.all(color: AC.border),
              boxShadow: aShadowSm,
            ),
            child: Row(
              children: [
                Text(monthLabel,
                    style: adminUi(size: 12,
                        weight: FontWeight.w700, color: AC.text2)),
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

  // ── Month picker bottom sheet ─────────────────────────────────
  void _showMonthPicker() {
    int tempMonth = _selectedMonth;
    int tempYear  = _selectedYear;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AC.surface,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AR.xl)),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20,
                  MediaQuery.of(ctx).padding.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AC.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text('Select Month',
                      style: adminDisplay(size: 18)),
                  const SizedBox(height: 16),

                  // Year selector row
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setModalState(
                            () => tempYear--),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AC.surface2,
                            borderRadius:
                                BorderRadius.circular(AR.md),
                            border: Border.all(
                                color: AC.borderLight),
                          ),
                          child: const Icon(
                              Icons.chevron_left_rounded,
                              size: 20, color: AC.text2),
                        ),
                      ),
                      Text('$tempYear',
                          style: adminMono(
                              size: 20,
                              weight: FontWeight.w500)),
                      GestureDetector(
                        onTap: () => setModalState(
                            () => tempYear++),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AC.surface2,
                            borderRadius:
                                BorderRadius.circular(AR.md),
                            border: Border.all(
                                color: AC.borderLight),
                          ),
                          child: const Icon(
                              Icons.chevron_right_rounded,
                              size: 20, color: AC.text2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Month grid (4 × 3)
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
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
                      final isSelected = m == tempMonth;
                      return GestureDetector(
                        onTap: () => setModalState(
                            () => tempMonth = m),
                        child: AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AC.ocean
                                : AC.surface2,
                            borderRadius:
                                BorderRadius.circular(AR.md),
                            border: Border.all(
                              color: isSelected
                                  ? AC.ocean
                                  : AC.borderLight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _months[i],
                              style: adminUi(
                                size: 13,
                                weight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AC.text2,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Apply button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMonth = tempMonth;
                        _selectedYear  = tempYear;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AC.ocean, AC.oceanMid]),
                        borderRadius:
                            BorderRadius.circular(AR.full),
                        boxShadow: [
                          BoxShadow(
                            color: AC.ocean.withOpacity(0.30),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Apply',
                          style: adminUi(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  // KPI GRID
  // ══════════════════════════════════════════════════════════════
  Widget _buildKpiGrid() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _buildKpiCard(_kpis[0])),
          const SizedBox(width: 10),
          Expanded(child: _buildKpiCard(_kpis[1])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _buildKpiCard(_kpis[2])),
          const SizedBox(width: 10),
          Expanded(child: _buildKpiCard(_kpis[3])),
        ]),
      ],
    );
  }

  Widget _buildKpiCard(_KpiCard k) {
    final tintColor = k.iconColor.withOpacity(0.08);

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
                  color: tintColor,
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
                    Text(
                      k.trendText,
                      style: adminUi(
                        size: 10,
                        weight: FontWeight.w800,
                        color: k.trendUp ? AC.green : AC.coral,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: k.value,
                style: adminMono(size: 24),
              ),
              if (k.valueSuffix.isNotEmpty)
                TextSpan(
                  text: k.valueSuffix,
                  style: adminMono(size: 14, color: AC.text3),
                ),
            ]),
          ),
          Text(
            k.label.toUpperCase(),
            style: adminUi(
              size: 11, weight: FontWeight.w600,
              color: AC.text3,
            ).copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: k.sparks.asMap().entries.map((e) {
                final i    = e.key;
                final h    = e.value;
                final opacity = 0.20 + h * 0.50;
                final isLast  = i == k.sparks.length - 1;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        left: i == 0 ? 0 : 2),
                    height: (h * 28).clamp(4.0, 28.0),
                    decoration: BoxDecoration(
                      color: isLast
                          ? k.sparkColor
                          : k.sparkColor.withOpacity(opacity),
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
  // WEEKLY CHART CARD
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
              Text('Weekly Active Users',
                  style: adminUi(size: 14,
                      weight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AC.greenTint,
                  borderRadius: BorderRadius.circular(AR.full),
                ),
                child: Text('↑ 18% vs last week',
                    style: adminUi(
                        size: 10, weight: FontWeight.w700,
                        color: AC.green)),
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
            children: ['Mon', 'Tue', 'Wed', 'Thu',
                       'Fri', 'Sat', 'Sun']
                .map((d) => Text(
                      d,
                      style: adminMono(
                        size: 10,
                        color: d == 'Fri' ? AC.gold : AC.text3,
                        weight: d == 'Fri'
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TABLE CARD WRAPPER — now with onLinkTap callback
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
                    style: adminUi(
                        size: 14, weight: FontWeight.w700)),
                GestureDetector(
                  onTap: onLinkTap,
                  child: Text(link,
                      style: adminUi(
                          size: 12, weight: FontWeight.w700,
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
  // POI ROW
  // ══════════════════════════════════════════════════════════════
  Widget _buildPoiRow(_PoiRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AC.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(row.rank,
                style: adminMono(size: 12, color: AC.text3),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 10),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: row.dot),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name,
                    style: adminUi(
                        size: 13, weight: FontWeight.w700)),
                Text(row.cat,
                    style: adminUi(
                        size: 10, color: AC.text3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          LayoutBuilder(builder: (_, c) {
            final barW = 60.0 * row.barFraction;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(row.views, style: adminMono(size: 13)),
                const SizedBox(height: 3),
                Container(
                  width: barW, height: 3,
                  decoration: BoxDecoration(
                    color: row.dot.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ACTIVITY ROW
  // ══════════════════════════════════════════════════════════════
  Widget _buildActivityRow(_ActivityRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AC.borderLight)),
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
            child: Icon(row.icon, size: 15,
                color: row.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.title,
                    style: adminUi(
                        size: 12, weight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(row.sub,
                    style: adminUi(
                        size: 11, color: AC.text2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(row.time,
              style: adminMono(size: 10, color: AC.text3)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// WEEKLY CHART PAINTER
// ══════════════════════════════════════════════════════════════
class _WeeklyChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid lines
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

    // Area fill
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
    canvas.saveLayer(areaRect, Paint()..color =
        Colors.white.withOpacity(0.15));
    canvas.drawPath(areaPath, areaPaint);
    canvas.restore();

    // Line
    final linePaint = Paint()
      ..color = AC.ocean
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath(), linePaint);

    // Data dots
    final dotPaint = Paint()..color = AC.ocean;
    final dotIndices = [1, 2, 3, 4, 6, 7];
    for (final i in dotIndices) {
      canvas.drawCircle(Offset(xs[i], ys[i]), 3.5, dotPaint);
    }
    // Friday = index 5 — gold
    canvas.drawCircle(Offset(xs[5], ys[5]), 4,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(xs[5], ys[5]), 4,
        Paint()..color = AC.gold
          ..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(xs[5], ys[5]), 2.5,
        Paint()..color = AC.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}