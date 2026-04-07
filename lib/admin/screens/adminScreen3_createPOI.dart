// ============================================================
// AndaMove Admin — Screen 3: Create POI
// File: lib/admin/screens/adminScreen3_createPOI.dart
//
// UPDATED:
//   • Single scrollable form — no step progress indicator
//   • All fields visible in section cards
//   • Form resets every time screen opens (fresh state)
//   • Publish → AppStore.publishPoi() → appears in tourist app
//   • Category dropdown with predefined options
//   • Transport access tag toggles
//   • Mini map preview (CustomPainter)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin_theme.dart';
import '../../app_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Transport tag model ───────────────────────────────────────
class _TransportTag {
  final IconData icon;
  final String   label;
  bool selected;
  _TransportTag(this.icon, this.label, {this.selected = false});
}

// ── Category options ──────────────────────────────────────────
const _categoryOptions = [
  'Beach', 'Temple', 'Nature', 'Culture', 'Food',
  'Adventure', 'Nightlife', 'Heritage', 'Viewpoint',
  'Attraction', 'Shopping',
];

// ── Category → gradient + icon mapping ────────────────────────
(List<Color>, IconData) _catVisuals(String cat) => switch (cat.toLowerCase()) {
  'beach'      => ([Color(0xFF0A7FAB), Color(0xFF38BDF8), Color(0xFF93C5FD)], Icons.beach_access_rounded),
  'temple'     => ([Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFFDE68A)], Icons.temple_buddhist_rounded),
  'nature'     => ([Color(0xFF16A34A), Color(0xFF22C55E), Color(0xFF86EFAC)], Icons.forest_rounded),
  'culture'    => ([Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFFE9D5FF)], Icons.account_balance_rounded),
  'food'       => ([Color(0xFFE8634C), Color(0xFFF97316), Color(0xFFFED7AA)], Icons.restaurant_rounded),
  'adventure'  => ([Color(0xFF166534), Color(0xFF16A34A), Color(0xFF86EFAC)], Icons.surfing_rounded),
  'nightlife'  => ([Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFF472B6)], Icons.nightlife_rounded),
  'heritage'   => ([Color(0xFF92400E), Color(0xFFB45309), Color(0xFFFDE68A)], Icons.museum_rounded),
  'viewpoint'  => ([Color(0xFFF59E0B), Color(0xFFF97316), Color(0xFFFB7185)], Icons.landscape_rounded),
  'attraction' => ([Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF67E8F9)], Icons.attractions_rounded),
  'shopping'   => ([Color(0xFF475569), Color(0xFF64748B), Color(0xFFCBD5E1)], Icons.shopping_bag_rounded),
  _            => ([Color(0xFF0A7FAB), Color(0xFF1AAECF), Color(0xFF7DD8EF)], Icons.place_rounded),
};

// ── Category → tag colour ─────────────────────────────────────
(Color, Color) _catTagColors(String cat) => switch (cat.toLowerCase()) {
  'beach'      => (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
  'temple'     => (Color(0xFFFDF5E7), Color(0xFFC8912E)),
  'nature'     => (Color(0xFFEEF5EE), Color(0xFF16A34A)),
  'culture'    => (Color(0xFFFDF5E7), Color(0xFFC8912E)),
  'food'       => (Color(0xFFFDF0EE), Color(0xFFE8634C)),
  'adventure'  => (Color(0xFFFDF0EE), Color(0xFFE8634C)),
  'nightlife'  => (Color(0xFFFDF0EE), Color(0xFFE8634C)),
  'heritage'   => (Color(0xFFFDF5E7), Color(0xFFC8912E)),
  'viewpoint'  => (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
  'attraction' => (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
  'shopping'   => (Color(0xFFFDF0EE), Color(0xFFE8634C)),
  _            => (Color(0xFFEAF8FD), Color(0xFF0A7FAB)),
};

// ── Main screen ───────────────────────────────────────────────
class AdminCreatePoiScreen extends StatefulWidget {
  const AdminCreatePoiScreen({super.key});
  @override
  State<AdminCreatePoiScreen> createState() =>
      _AdminCreatePoiScreenState();
}

class _AdminCreatePoiScreenState
    extends State<AdminCreatePoiScreen> {

  // ── Form controllers (fresh on each mount) ──
  final _nameCtrl        = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _longDescCtrl    = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _latCtrl         = TextEditingController();
  final _lngCtrl         = TextEditingController();
  final _weekdayFromCtrl = TextEditingController(text: '08:00');
  final _weekdayToCtrl   = TextEditingController(text: '19:00');
  final _weekendFromCtrl = TextEditingController(text: '07:00');
  final _weekendToCtrl   = TextEditingController(text: '20:00');

  String _selectedCategory = 'Beach';
  String _selectedPrice    = 'Free';
  String _estimatedTime    = '1 - 2 hours';
  bool _isPublishing       = false;

  final _transportTags = [
    _TransportTag(Icons.electric_scooter_rounded, 'Scooter', selected: true),
    _TransportTag(Icons.directions_car_rounded,   'Car',     selected: true),
    _TransportTag(Icons.directions_walk_rounded,   'Walk'),
    _TransportTag(Icons.airport_shuttle_rounded,   'Tuk-tuk'),
    _TransportTag(Icons.directions_boat_rounded,   'Boat'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _longDescCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _weekdayFromCtrl.dispose();
    _weekdayToCtrl.dispose();
    _weekendFromCtrl.dispose();
    _weekendToCtrl.dispose();
    super.dispose();
  }

  // ── Publish handler ───────────────────────────────────────
  Future<void> _handlePublish() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    // Basic validation
    if (name.isEmpty) {
      _showError('POI name is required');
      return;
    }
    if (desc.isEmpty) {
      _showError('Short description is required');
      return;
    }

    setState(() => _isPublishing = true);

    try {
      // Build opening hours string
      final hours = 'Mon-Fri ${_weekdayFromCtrl.text}-${_weekdayToCtrl.text}'
          ' · Sat-Sun ${_weekendFromCtrl.text}-${_weekendToCtrl.text}';

      // Create document ID from name (slugified)
      final docId = name.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');

      // Get selected transport tags
      final transportAccess = _transportTags
          .where((t) => t.selected)
          .map((t) => t.label)
          .toList();

      // Write to Firestore
      await FirebaseFirestore.instance.collection('pois').doc(docId).set({
        'name': name,
        'location': _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : 'Phuket, Thailand',
        'category': _selectedCategory,
        'rating': 0.0,
        'description': desc,
        'longDescription': _longDescCtrl.text.trim(),
        'openHours': hours,
        'estimatedTime': _estimatedTime,
        'priceRange': _selectedPrice,
        'imagePath': '',
        'tags': [_selectedCategory],
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'admin',
        'latitude': double.tryParse(_latCtrl.text.trim()) ?? 0.0,
        'longitude': double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
        'transportAccess': transportAccess,
      });

      // Also publish to AppStore for immediate local visibility
      final (gradColors, catIcon) = _catVisuals(_selectedCategory);
      final (tagBg, tagFg) = _catTagColors(_selectedCategory);

      AppStore.publishPoi(SavedPoiSummary(
        name: name,
        location: _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : 'Phuket, Thailand',
        category: _selectedCategory,
        rating: 0.0,
        description: desc,
        longDescription: _longDescCtrl.text.trim(),
        openHours: hours,
        estimatedTime: _estimatedTime,
        priceRange: _selectedPrice,
        gradientColors: gradColors,
        icon: catIcon,
        tagLabel: _selectedCategory,
        tagBg: tagBg,
        tagFg: tagFg,
        imagePath: '',
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AC.navy,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4ADE80), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '"$name" published to Firestore!',
                    style: adminUi(size: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to publish. Please try again.');
        setState(() => _isPublishing = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AC.coral,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(msg, style: adminUi(
                size: 13, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          // ── Top nav ──
          AdminTopNavPage(title: 'Create POI'),

          // ── Scrollable form ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 14),
                  _buildLocationSection(),
                  const SizedBox(height: 14),
                  _buildDetailsSection(),
                  const SizedBox(height: 14),
                  _buildHoursSection(),
                  const SizedBox(height: 14),
                  _buildTransportSection(),
                ],
              ),
            ),
          ),

          // ── Bottom CTA ──
          _buildBottomCta(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // REUSABLE SECTION CARD
  // ══════════════════════════════════════════════════════════════
  Widget _section({
    required IconData icon,
    required Color    iconColor,
    required String   title,
    required Widget   body,
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
                    style: adminUi(
                        size: 14, weight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1, color: AC.borderLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: body,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // FIELD HELPERS
  // ══════════════════════════════════════════════════════════════
  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: text,
              style: adminUi(size: 11, weight: FontWeight.w700,
                  color: AC.text2)),
          if (required)
            TextSpan(text: ' *',
                style: adminUi(size: 11, weight: FontWeight.w700,
                    color: AC.coral)),
        ]),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, {
    String? hint,
    bool mono = false,
    double height = 44,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AC.surface2,
        borderRadius: BorderRadius.circular(AR.md),
        border: Border.all(color: AC.border),
      ),
      child: Center(
        child: TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: mono ? adminMono(size: 13) : adminUi(size: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: adminUi(size: 13, color: AC.text3),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _textarea(TextEditingController ctrl, {String? hint}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: AC.surface2,
        borderRadius: BorderRadius.circular(AR.md),
        border: Border.all(color: AC.border),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: null,
        style: adminUi(size: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: adminUi(size: 13, color: AC.text3),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SECTION 1: BASIC INFORMATION
  // ══════════════════════════════════════════════════════════════
  Widget _buildBasicInfoSection() {
    return _section(
      icon: Icons.info_outline_rounded,
      iconColor: AC.ocean,
      title: 'Basic Information',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('POI Name', required: true),
          _input(_nameCtrl, hint: 'e.g. Karon Beach Viewpoint'),
          const SizedBox(height: 12),

          _label('Short Description', required: true),
          _textarea(_descCtrl,
              hint: 'Brief description (max 200 chars)…'),
          const SizedBox(height: 12),

          _label('Long Description'),
          _textarea(_longDescCtrl,
              hint: 'Detailed description for POI detail page…'),
          const SizedBox(height: 12),

          // Category + Price row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Category', required: true),
                    _buildDropdown(
                      value: _selectedCategory,
                      items: _categoryOptions,
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Price Range'),
                    _buildDropdown(
                      value: _selectedPrice,
                      items: ['Free', '฿', '฿฿', '฿฿฿'],
                      onChanged: (v) =>
                          setState(() => _selectedPrice = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _label('Estimated Visit Duration'),
          _buildDropdown(
            value: _estimatedTime,
            items: [
              '30 - 45 mins', '45 mins - 1 hour',
              '1 - 2 hours', '2 - 3 hours',
              '2 - 4 hours', '3 - 4 hours', 'Full Day',
            ],
            onChanged: (v) =>
                setState(() => _estimatedTime = v!),
          ),
        ],
      ),
    );
  }

  // ── Dropdown styled to match admin form ────────────────────
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AC.surface2,
        borderRadius: BorderRadius.circular(AR.md),
        border: Border.all(color: AC.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: AC.text3),
          style: adminUi(size: 13),
          dropdownColor: AC.surface,
          items: items.map((item) =>
            DropdownMenuItem(value: item, child: Text(item)),
          ).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SECTION 2: LOCATION
  // ══════════════════════════════════════════════════════════════
  Widget _buildLocationSection() {
    return _section(
      icon: Icons.location_on_rounded,
      iconColor: AC.coral,
      title: 'Location & Coordinates',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Address'),
          _input(_addressCtrl,
              hint: 'e.g. Karon Hill, Mueang Phuket 83100'),
          const SizedBox(height: 12),

          // Lat/Lng row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Latitude'),
                    _input(_latCtrl,
                        hint: '7.8404',
                        mono: true, height: 40,
                        keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Longitude'),
                    _input(_lngCtrl,
                        hint: '98.2966',
                        mono: true, height: 40,
                        keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini map preview
          ClipRRect(
            borderRadius: BorderRadius.circular(AR.md),
            child: SizedBox(
              height: 90,
              child: CustomPaint(
                painter: _MiniMapPainter(),
                size: const Size(double.infinity, 90),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Map preview — location will update with Google Maps API',
            style: adminUi(size: 10, color: AC.text3),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SECTION 3: PHOTOS
  // ══════════════════════════════════════════════════════════════
  Widget _buildDetailsSection() {
    return _section(
      icon: Icons.photo_library_rounded,
      iconColor: AC.gold,
      title: 'Photos',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload zone
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AC.surface2,
              borderRadius: BorderRadius.circular(AR.md),
              border: Border.all(color: AC.border, width: 1.5),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_rounded,
                    size: 28, color: AC.text3),
                const SizedBox(height: 8),
                Text('Tap to upload photos',
                    style: adminUi(size: 13, color: AC.text2)),
                const SizedBox(height: 3),
                Text('JPG, PNG · Max 5MB each',
                    style: adminUi(size: 11, color: AC.text3)),
                const SizedBox(height: 8),
                Text(
                  'Photo upload will be available with Firebase Storage',
                  style: adminUi(size: 10, color: AC.text3)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SECTION 4: OPERATING HOURS
  // ══════════════════════════════════════════════════════════════
  Widget _buildHoursSection() {
    return _section(
      icon: Icons.schedule_rounded,
      iconColor: AC.purple,
      title: 'Operating Hours',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHoursRow('Mon–Fri', _weekdayFromCtrl, _weekdayToCtrl),
          const SizedBox(height: 8),
          _buildHoursRow('Sat–Sun', _weekendFromCtrl, _weekendToCtrl),
        ],
      ),
    );
  }

  Widget _buildHoursRow(String day,
      TextEditingController fromCtrl,
      TextEditingController toCtrl) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(day,
              style: adminUi(size: 11, weight: FontWeight.w600,
                  color: AC.text2)),
        ),
        const SizedBox(width: 8),
        Expanded(child: _input(fromCtrl, mono: true, height: 36)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('–', style: adminUi(size: 13, color: AC.text3)),
        ),
        Expanded(child: _input(toCtrl, mono: true, height: 36)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SECTION 5: TRANSPORT ACCESS
  // ══════════════════════════════════════════════════════════════
  Widget _buildTransportSection() {
    return _section(
      icon: Icons.directions_rounded,
      iconColor: AC.green,
      title: 'Transport Access',
      body: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _transportTags.map((tag) {
          return GestureDetector(
            onTap: () =>
                setState(() => tag.selected = !tag.selected),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tag.selected ? AC.oceanTint : AC.surface2,
                borderRadius: BorderRadius.circular(AR.full),
                border: Border.all(
                  color: tag.selected
                      ? AC.ocean.withOpacity(0.40)
                      : AC.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tag.icon, size: 14,
                      color: tag.selected ? AC.ocean : AC.text2),
                  const SizedBox(width: 5),
                  Text(tag.label,
                      style: adminUi(
                        size: 12,
                        weight: FontWeight.w700,
                        color: tag.selected ? AC.ocean : AC.text2,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BOTTOM CTA
  // ══════════════════════════════════════════════════════════════
  Widget _buildBottomCta() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16,
          MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: AC.surface,
        border: Border(top: BorderSide(color: AC.borderLight)),
      ),
      child: Row(
        children: [
          // Cancel button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AC.surface,
                borderRadius: BorderRadius.circular(AR.full),
                border: Border.all(color: AC.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.close_rounded,
                      size: 18, color: AC.text2),
                  const SizedBox(width: 5),
                  Text('Cancel',
                      style: adminUi(
                          size: 13, weight: FontWeight.w700,
                          color: AC.text1)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Publish button
          Expanded(
            child: GestureDetector(
              onTap: _isPublishing ? null : _handlePublish,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AC.ocean, AC.oceanMid]),
                  borderRadius: BorderRadius.circular(AR.full),
                  boxShadow: [
                    BoxShadow(
                        color: AC.ocean.withOpacity(0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isPublishing)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.publish_rounded,
                          size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(_isPublishing ? 'Publishing…' : 'Publish POI',
                        style: adminUi(
                            size: 14, weight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MINI MAP PAINTER
// ══════════════════════════════════════════════════════════════
class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment(-0.2, -1),
          end: Alignment(0.2, 1),
          colors: [Color(0xFF071520), Color(0xFF0A3D5C)],
        ).createShader(
            Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = AC.oceanMid.withOpacity(0.06)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Centre pin
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Pulse ring
    canvas.drawCircle(
      Offset(cx, cy), 14,
      Paint()..color = AC.ocean.withOpacity(0.15),
    );
    // Pin dot
    canvas.drawCircle(
      Offset(cx, cy), 6,
      Paint()
        ..shader = const LinearGradient(
          colors: [AC.ocean, AC.oceanMid],
        ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: 6)),
    );

    // Coordinate label
    final tp = TextPainter(
      text: TextSpan(
        text: 'Tap to set coordinates',
        style: GoogleFonts.dmMono(
          fontSize: 9,
          color: Colors.white.withOpacity(0.50),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2,
          size.height - tp.height - 8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}