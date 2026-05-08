// ============================================================
// AndaMove Admin — Screen 6: Activity Logs
// File: lib/admin/screens/adminScreen6_activityLogs.dart
//
// UPDATED — Firestore-wired:
//   • Reads live from activityLogs collection (written by
//     AppStore.logActivity() whenever admin takes an action)
//   • Filter chips (All / Users / POIs / Trips / System)
//     query Firestore with a category filter
//   • Pull-to-refresh reloads the list
//   • Pagination: "Load more" loads next 20 entries
//   • Empty state and loading state handled cleanly
//   • UI identical to original — same card layout, same chips
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_theme.dart';

// ══════════════════════════════════════════════════════════════
// DATA MODEL — wraps a Firestore activityLogs doc
// ══════════════════════════════════════════════════════════════
class _LogEntry {
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String sub;
  final String category;
  final DateTime? timestamp;

  const _LogEntry({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.sub,
    required this.category,
    this.timestamp,
  });

  String get timeLabel {
    if (timestamp == null) return '—';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1)   return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)    return '${diff.inHours}h ago';
    if (diff.inDays < 30)   return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 30}mo ago';
  }

  /// "Today", "Yesterday", "12 May 2026", etc.
  String get dateGroupLabel {
    if (timestamp == null) return 'Unknown';
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ts    = DateTime(
        timestamp!.year, timestamp!.month, timestamp!.day);
    final diff  = today.difference(ts).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${timestamp!.day} ${months[timestamp!.month - 1]}'
        ' ${timestamp!.year}';
  }

  static IconData _iconFor(String cat) {
    switch (cat) {
      case 'user':   return Icons.person_rounded;
      case 'poi':    return Icons.location_on_rounded;
      case 'trip':   return Icons.map_rounded;
      default:       return Icons.settings_rounded;
    }
  }

  static Color _colorFor(String cat) {
    switch (cat) {
      case 'user':   return AC.green;
      case 'poi':    return AC.gold;
      case 'trip':   return AC.ocean;
      default:       return AC.purple;
    }
  }

  factory _LogEntry.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d   = doc.data();
    final cat = (d['category'] as String?)?.toLowerCase() ?? 'system';
    return _LogEntry(
      id:        doc.id,
      icon:      _iconFor(cat),
      iconColor: _colorFor(cat),
      title:     d['title'] as String? ?? '—',
      sub:       d['sub']   as String? ?? '',
      category:  cat,
      timestamp: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});
  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {

  static const int _pageSize = 20;

  final _filters   = ['All', 'Users', 'POIs', 'Trips', 'System'];
  int _filterIndex = 0;

  List<_LogEntry> _logs          = [];
  bool _loading                  = true;
  bool _loadingMore              = false;
  bool _hasMore                  = true;
  DocumentSnapshot? _lastDoc;

  // ── category key for Firestore queries ───────────────────────
  String? get _activeCatKey {
    if (_filterIndex == 0) return null; // All
    final label = _filters[_filterIndex].toLowerCase();
    return switch (label) {
      'users'  => 'user',
      'pois'   => 'poi',
      'trips'  => 'trip',
      'system' => 'system',
      _        => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadLogs(reset: true);
  }

  // ══════════════════════════════════════════════════════════════
  // FIRESTORE READS
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadLogs({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading  = true;
        _logs     = [];
        _lastDoc  = null;
        _hasMore  = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('activityLogs')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      // Apply category filter if not "All"
      if (_activeCatKey != null) {
        query = query.where('category', isEqualTo: _activeCatKey);
      }

      // Paginate from last doc
      if (!reset && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snap = await query.get();
      final newEntries = snap.docs.map(_LogEntry.fromDoc).toList();

      if (mounted) {
        setState(() {
          if (reset) {
            _logs = newEntries;
          } else {
            _logs.addAll(newEntries);
          }
          _lastDoc     = snap.docs.isNotEmpty ? snap.docs.last : _lastDoc;
          _hasMore     = newEntries.length == _pageSize;
          _loading     = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading     = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _onFilterChanged(int index) {
    if (index == _filterIndex) return;
    setState(() => _filterIndex = index);
    _loadLogs(reset: true);
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          AdminTopNavPage(title: 'Activity Logs'),
          _buildFilterChips(),
          _buildCountStrip(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────
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
            onTap: () => _onFilterChanged(i),
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

  // ── Count strip ───────────────────────────────────────────────
  Widget _buildCountStrip() {
    final label = _loading
        ? 'Loading…'
        : '${_logs.length}${_hasMore ? '+' : ''} log entries';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AC.surface,
        border: Border(bottom: BorderSide(color: AC.borderLight)),
      ),
      child: Text(
        label,
        style: adminUi(size: 12, weight: FontWeight.w600,
            color: AC.text3),
      ),
    );
  }

  // ── Main body ─────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: AC.ocean, strokeWidth: 2.5),
      );
    }

    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 36, color: AC.text3),
            const SizedBox(height: 10),
            Text(
              'No logs yet',
              style: adminUi(size: 14, weight: FontWeight.w600,
                  color: AC.text2),
            ),
            const SizedBox(height: 4),
            Text(
              'Admin actions will appear here',
              style: adminUi(size: 12, color: AC.text3),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AC.ocean,
      onRefresh: () => _loadLogs(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _logs.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          // Load-more button at the bottom
          if (i == _logs.length) {
            return _buildLoadMore();
          }

          final entry = _logs[i];

          // Date group divider — show when date changes
          final showDivider = i == 0 ||
              _logs[i].dateGroupLabel != _logs[i - 1].dateGroupLabel;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDivider) _buildDateDivider(entry.dateGroupLabel),
              _buildLogCard(entry),
            ],
          );
        },
      ),
    );
  }

  // ── Date group divider ────────────────────────────────────────
  Widget _buildDateDivider(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AC.surface2,
              borderRadius: BorderRadius.circular(AR.full),
              border: Border.all(color: AC.borderLight),
            ),
            child: Text(
              label,
              style: adminUi(
                size: 11,
                weight: FontWeight.w700,
                color: AC.text2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 1, color: AC.borderLight),
          ),
        ],
      ),
    );
  }

  // ── Log card ──────────────────────────────────────────────────
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
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: log.iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AR.md),
            ),
            child: Icon(log.icon, size: 16, color: log.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.title,
                    style: adminUi(
                        size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(log.sub,
                    style: adminUi(size: 11, color: AC.text2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(log.timeLabel,
              style: adminMono(size: 10, color: AC.text3)),
        ],
      ),
    );
  }

  // ── Load more button ──────────────────────────────────────────
  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: GestureDetector(
        onTap: () => _loadLogs(reset: false),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AC.surface,
            borderRadius: BorderRadius.circular(AR.card),
            border: Border.all(color: AC.borderLight),
          ),
          child: Center(
            child: _loadingMore
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AC.ocean),
                  )
                : Text(
                    'Load more',
                    style: adminUi(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AC.ocean,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}