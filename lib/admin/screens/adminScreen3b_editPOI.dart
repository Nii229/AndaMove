// ============================================================
// AndaMove Admin — Screen 3b: Edit POI
// File: lib/admin/screens/adminScreen3b_editPOI.dart
//
// Pre-filled edit form that mirrors adminScreen3_createPOI.dart
// exactly in layout, section cards, and field helpers.
//
// Behaviour:
//   • If firestoreDocId != null  → update() existing Firestore doc
//   • If firestoreDocId == null  → set() new doc (promotes mock POI)
//   • On success → pops back to Manage POIs and triggers a refresh
//   • Transport tags parsed from existing 'transportAccess' field
//     (falls back to Scooter + Car selected if field is absent)
//   • Hours string parsed from "Mon-Fri HH:MM-HH:MM · Sat-Sun …"
//     format written by Create POI; falls back to defaults if
//     the string doesn't match (e.g. "Open 24 hours")
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin_theme.dart';

// ── Transport tag model ───────────────────────────────────────
class _TransportTag {
  final IconData icon;
  final String label;
  bool selected;
  _TransportTag(this.icon, this.label, {this.selected = false});
}

// ── Category options ──────────────────────────────────────────
const _categoryOptions = [
  'Beach', 'Temple', 'Nature', 'Culture', 'Food',
  'Adventure', 'Nightlife', 'Heritage', 'Viewpoint',
  'Attraction', 'Shopping',
];

// ── Category → gradient + icon ────────────────────────────────
(List<Color>, IconData) _catVisuals(String cat) =>
    switch (cat.toLowerCase()) {
      'beach'      => (const [Color(0xFF0A7FAB), Color(0xFF38BDF8), Color(0xFF93C5FD)], Icons.beach_access_rounded),
      'temple'     => (const [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFFDE68A)], Icons.temple_buddhist_rounded),
      'nature'     => (const [Color(0xFF16A34A), Color(0xFF22C55E), Color(0xFF86EFAC)], Icons.forest_rounded),
      'culture'    => (const [Color(0xFF7C3AED), Color(0xFFA855F7), Color(0xFFE9D5FF)], Icons.account_balance_rounded),
      'food'       => (const [Color(0xFFE8634C), Color(0xFFF97316), Color(0xFFFED7AA)], Icons.restaurant_rounded),
      'adventure'  => (const [Color(0xFF166534), Color(0xFF16A34A), Color(0xFF86EFAC)], Icons.surfing_rounded),
      'nightlife'  => (const [Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFFF472B6)], Icons.nightlife_rounded),
      'heritage'   => (const [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFFDE68A)], Icons.museum_rounded),
      'viewpoint'  => (const [Color(0xFFF59E0B), Color(0xFFF97316), Color(0xFFFB7185)], Icons.landscape_rounded),
      'attraction' => (const [Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF67E8F9)], Icons.attractions_rounded),
      'shopping'   => (const [Color(0xFF475569), Color(0xFF64748B), Color(0xFFCBD5E1)], Icons.shopping_bag_rounded),
      _            => (const [Color(0xFF0A7FAB), Color(0xFF1AAECF), Color(0xFF7DD8EF)], Icons.place_rounded),
    };

// ── Category → tag colours ────────────────────────────────────
(Color, Color) _catTagColors(String cat) => switch (cat.toLowerCase()) {
  'beach'      => (const Color(0xFFEAF8FD), const Color(0xFF0A7FAB)),
  'temple'     => (const Color(0xFFFDF5E7), const Color(0xFFC8912E)),
  'nature'     => (const Color(0xFFEEF5EE), const Color(0xFF16A34A)),
  'culture'    => (const Color(0xFFFDF5E7), const Color(0xFFC8912E)),
  'food'       => (const Color(0xFFFDF0EE), const Color(0xFFE8634C)),
  'adventure'  => (const Color(0xFFFDF0EE), const Color(0xFFE8634C)),
  'nightlife'  => (const Color(0xFFFDF0EE), const Color(0xFFE8634C)),
  'heritage'   => (const Color(0xFFFDF5E7), const Color(0xFFC8912E)),
  'viewpoint'  => (const Color(0xFFEAF8FD), const Color(0xFF0A7FAB)),
  'attraction' => (const Color(0xFFEAF8FD), const Color(0xFF0A7FAB)),
  'shopping'   => (const Color(0xFFFDF0EE), const Color(0xFFE8634C)),
  _            => (const Color(0xFFEAF8FD), const Color(0xFF0A7FAB)),
};

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class AdminEditPoiScreen extends StatefulWidget {
  /// Firestore document ID. Null for hardcoded mock POIs —
  /// in that case we auto-generate one on save.
  final String? firestoreDocId;

  // Current field values passed in from Manage POIs
  final String initialName;
  final String initialDescription;
  final String initialLongDescription;
  final String initialCategory;
  final String initialLocation;
  final String initialPriceRange;
  final String initialEstimatedTime;
  final String initialOpenHours;   // raw string from Firestore
  final double initialLatitude;
  final double initialLongitude;
  final List<String> initialTransportAccess; // e.g. ['Scooter', 'Car']
  final String initialImagePath;

  const AdminEditPoiScreen({
    super.key,
    this.firestoreDocId,
    required this.initialName,
    required this.initialDescription,
    required this.initialLongDescription,
    required this.initialCategory,
    required this.initialLocation,
    required this.initialPriceRange,
    required this.initialEstimatedTime,
    required this.initialOpenHours,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.initialTransportAccess,
    this.initialImagePath = '',
  });

  @override
  State<AdminEditPoiScreen> createState() => _AdminEditPoiScreenState();
}

class _AdminEditPoiScreenState extends State<AdminEditPoiScreen> {
  // ── Form controllers ─────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _longDescCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _weekdayFromCtrl;
  late final TextEditingController _weekdayToCtrl;
  late final TextEditingController _weekendFromCtrl;
  late final TextEditingController _weekendToCtrl;

  late String _selectedCategory;
  late String _selectedPrice;
  late String _estimatedTime;
  bool _isSaving = false;

  File?   _selectedImage;
  String? _uploadedImageUrl;
  bool    _uploadingImage = false;

  // Transport tags — selection state seeded from initialTransportAccess
  late final List<_TransportTag> _transportTags;

  @override
  void initState() {
    super.initState();

    _nameCtrl        = TextEditingController(text: widget.initialName);
    _descCtrl        = TextEditingController(text: widget.initialDescription);
    _longDescCtrl    = TextEditingController(text: widget.initialLongDescription);
    _addressCtrl     = TextEditingController(text: widget.initialLocation);
    _latCtrl         = TextEditingController(
        text: widget.initialLatitude != 0.0
            ? widget.initialLatitude.toString()
            : '');
    _lngCtrl         = TextEditingController(
        text: widget.initialLongitude != 0.0
            ? widget.initialLongitude.toString()
            : '');

    // Normalise category — fall back to 'Beach' if not in list
    _selectedCategory = _categoryOptions.contains(widget.initialCategory)
        ? widget.initialCategory
        : 'Beach';

    // Normalise price
    _selectedPrice = ['Free', '฿', '฿฿', '฿฿฿'].contains(widget.initialPriceRange)
        ? widget.initialPriceRange
        : 'Free';

    // Normalise estimated time
    const validTimes = [
      '30 - 45 mins', '45 mins - 1 hour',
      '1 - 2 hours', '2 - 3 hours',
      '2 - 4 hours', '3 - 4 hours', 'Full Day',
    ];
    _estimatedTime = validTimes.contains(widget.initialEstimatedTime)
        ? widget.initialEstimatedTime
        : '1 - 2 hours';

    // Parse hours string written by Create POI:
    // "Mon-Fri HH:MM-HH:MM · Sat-Sun HH:MM-HH:MM"
    final parsed = _parseHours(widget.initialOpenHours);
    _weekdayFromCtrl = TextEditingController(text: parsed[0]);
    _weekdayToCtrl   = TextEditingController(text: parsed[1]);
    _weekendFromCtrl = TextEditingController(text: parsed[2]);
    _weekendToCtrl   = TextEditingController(text: parsed[3]);

    // Transport tags — pre-select based on initialTransportAccess
    final sel = widget.initialTransportAccess.map((s) => s.toLowerCase()).toSet();
    final fallback = sel.isEmpty; // if no data, default to Scooter + Car
    _transportTags = [
      _TransportTag(Icons.electric_scooter_rounded, 'Scooter',
          selected: fallback || sel.contains('scooter')),
      _TransportTag(Icons.directions_car_rounded, 'Car',
          selected: fallback || sel.contains('car')),
      _TransportTag(Icons.directions_walk_rounded, 'Walk',
          selected: sel.contains('walk')),
      _TransportTag(Icons.airport_shuttle_rounded, 'Tuk-tuk',
          selected: sel.contains('tuk-tuk')),
      _TransportTag(Icons.directions_boat_rounded, 'Boat',
          selected: sel.contains('boat')),
    ];
  }

  // ── Parse "Mon-Fri 08:00-19:00 · Sat-Sun 07:00-20:00" ────────
  // Returns [wdFrom, wdTo, weFrom, weTo] — falls back to defaults.
  List<String> _parseHours(String raw) {
    try {
      // Split on " · "
      final parts = raw.split(' · ');
      if (parts.length >= 2) {
        // Each part looks like "Mon-Fri 08:00-19:00"
        final wdTimes = parts[0].split(' ').last.split('-');
        final weTimes = parts[1].split(' ').last.split('-');
        if (wdTimes.length == 2 && weTimes.length == 2) {
          return [wdTimes[0], wdTimes[1], weTimes[0], weTimes[1]];
        }
      }
    } catch (_) {}
    return ['08:00', '19:00', '07:00', '20:00'];
  }

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

  // ── Pick & upload POI image ───────────────────────────────
  Future<void> _pickPoiImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _selectedImage  = File(picked.path);
      _uploadingImage = true;
    });
    try {
      final ext = picked.path.split('.').last;
      final docId = (widget.firestoreDocId ??
              widget.initialName.toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                  .replaceAll(RegExp(r'^_+|_+$'), ''));
      final ref = FirebaseStorage.instance
          .ref()
          .child('poi_images/${docId}_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putFile(_selectedImage!);
      final url = await ref.getDownloadURL();
      if (mounted) setState(() { _uploadedImageUrl = url; _uploadingImage = false; });
    } catch (_) {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  // ══════════════════════════════════════════════════════════
  // SAVE HANDLER
  // ══════════════════════════════════════════════════════════
  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.isEmpty) { _showError('POI name is required'); return; }
    if (desc.isEmpty) { _showError('Short description is required'); return; }

    setState(() => _isSaving = true);

    try {
      final hours =
          'Mon-Fri ${_weekdayFromCtrl.text}-${_weekdayToCtrl.text}'
          ' · Sat-Sun ${_weekendFromCtrl.text}-${_weekendToCtrl.text}';

      final transport = _transportTags
          .where((t) => t.selected)
          .map((t) => t.label)
          .toList();

      final (gradColors, _) = _catVisuals(_selectedCategory);
      final (tagBg, tagFg)  = _catTagColors(_selectedCategory);

      final data = {
        'name': name,
        'location': _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : 'Phuket, Thailand',
        'category': _selectedCategory,
        'description': desc,
        'longDescription': _longDescCtrl.text.trim(),
        'openHours': hours,
        'estimatedTime': _estimatedTime,
        'priceRange': _selectedPrice,
        'imagePath': _uploadedImageUrl ?? widget.initialImagePath,
        'tags': [_selectedCategory],
        'transportAccess': transport,
        'latitude': double.tryParse(_latCtrl.text.trim()) ?? 0.0,
        'longitude': double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docId = widget.firestoreDocId ??
          name
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
              .replaceAll(RegExp(r'^_+|_+$'), '');

      final ref = FirebaseFirestore.instance.collection('pois').doc(docId);

      if (widget.firestoreDocId != null) {
        await ref.update(data);
      } else {
        await ref.set({
          ...data,
          'rating': 0.0,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'admin',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AC.navy,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            content: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4ADE80), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '"$name" saved successfully',
                  style: adminUi(size: 13, color: Colors.white),
                ),
              ),
            ]),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // true = refresh Manage POIs
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to save. Please try again.');
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AC.coral,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(msg, style: adminUi(size: 13, color: Colors.white)),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          AdminTopNavPage(
            title: 'Edit POI',
            action: widget.firestoreDocId == null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AC.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AR.full),
                      border: Border.all(
                          color: AC.amber.withOpacity(0.40)),
                    ),
                    child: Text(
                      'NEW TO FIRESTORE',
                      style: adminUi(
                        size: 9,
                        weight: FontWeight.w800,
                        color: AC.amber,
                      ).copyWith(letterSpacing: 0.8),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 14),
                  _buildPhotosSection(),
                  const SizedBox(height: 14),
                  _buildLocationSection(),
                  const SizedBox(height: 14),
                  _buildHoursSection(),
                  const SizedBox(height: 14),
                  _buildTransportSection(),
                ],
              ),
            ),
          ),
          _buildBottomCta(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION CARD WRAPPER — identical to Create POI
  // ══════════════════════════════════════════════════════════
  Widget _section({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget body,
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
                Text(title, style: adminUi(size: 14, weight: FontWeight.w700)),
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

  // ── Field helpers — identical to Create POI ───────────────
  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: text,
            style: adminUi(
                size: 11, weight: FontWeight.w700, color: AC.text2),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: adminUi(
                  size: 11, weight: FontWeight.w700, color: AC.coral),
            ),
        ]),
      ),
    );
  }

  Widget _input(
    TextEditingController ctrl, {
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

  Widget _dropdown({
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
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION 1 — BASIC INFORMATION
  // ══════════════════════════════════════════════════════════
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
          _textarea(_descCtrl, hint: 'Brief description…'),
          const SizedBox(height: 12),

          _label('Long Description'),
          _textarea(_longDescCtrl, hint: 'Detailed description…'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Category', required: true),
                    _dropdown(
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
                    _dropdown(
                      value: _selectedPrice,
                      items: const ['Free', '฿', '฿฿', '฿฿฿'],
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
          _dropdown(
            value: _estimatedTime,
            items: const [
              '30 - 45 mins', '45 mins - 1 hour',
              '1 - 2 hours', '2 - 3 hours',
              '2 - 4 hours', '3 - 4 hours', 'Full Day',
            ],
            onChanged: (v) => setState(() => _estimatedTime = v!),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION 2 — LOCATION & COORDINATES
  // ══════════════════════════════════════════════════════════
  Widget _buildLocationSection() {
    return _section(
      icon: Icons.location_on_rounded,
      iconColor: AC.coral,
      title: 'Location & Coordinates',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Address / Location'),
          _input(_addressCtrl,
              hint: 'e.g. Karon Hill, Mueang Phuket 83100'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Latitude'),
                    _input(_latCtrl,
                        hint: '7.8404',
                        mono: true,
                        height: 40,
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
                        mono: true,
                        height: 40,
                        keyboardType: TextInputType.number),
                  ],
                ),
              ),
            ],
          ),

          if (widget.initialLatitude != 0.0 &&
              widget.initialLongitude != 0.0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AC.greenTint,
                borderRadius: BorderRadius.circular(AR.md),
                border: Border.all(
                    color: AC.green.withOpacity(0.20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 13, color: AC.green),
                  const SizedBox(width: 6),
                  Text(
                    'GPS coordinates on file'
                    ' (${widget.initialLatitude.toStringAsFixed(4)},'
                    ' ${widget.initialLongitude.toStringAsFixed(4)})',
                    style: adminUi(size: 11, color: AC.green),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION 3 — OPERATING HOURS
  // ══════════════════════════════════════════════════════════
  Widget _buildHoursSection() {
    return _section(
      icon: Icons.schedule_rounded,
      iconColor: AC.purple,
      title: 'Operating Hours',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hoursRow('Mon–Fri', _weekdayFromCtrl, _weekdayToCtrl),
          const SizedBox(height: 8),
          _hoursRow('Sat–Sun', _weekendFromCtrl, _weekendToCtrl),
        ],
      ),
    );
  }

  Widget _hoursRow(
    String day,
    TextEditingController from,
    TextEditingController to,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(day,
              style: adminUi(
                  size: 11, weight: FontWeight.w600, color: AC.text2)),
        ),
        const SizedBox(width: 8),
        Expanded(child: _input(from, mono: true, height: 36)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('–', style: adminUi(size: 13, color: AC.text3)),
        ),
        Expanded(child: _input(to, mono: true, height: 36)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION 4 — TRANSPORT ACCESS
  // ══════════════════════════════════════════════════════════
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
                  Icon(tag.icon,
                      size: 14,
                      color: tag.selected ? AC.ocean : AC.text2),
                  const SizedBox(width: 5),
                  Text(
                    tag.label,
                    style: adminUi(
                      size: 12,
                      weight: FontWeight.w700,
                      color: tag.selected ? AC.ocean : AC.text2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION — PHOTOS
  // ══════════════════════════════════════════════════════════
  Widget _buildPhotosSection() {
    return _section(
      icon: Icons.photo_library_rounded,
      iconColor: AC.gold,
      title: 'Photos',
      body: GestureDetector(
        onTap: _uploadingImage ? null : _pickPoiImage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: (_selectedImage != null ||
                    widget.initialImagePath.isNotEmpty)
                ? AC.oceanTint
                : AC.surface2,
            borderRadius: BorderRadius.circular(AR.md),
            border: Border.all(
              color: (_selectedImage != null ||
                      widget.initialImagePath.isNotEmpty)
                  ? AC.ocean.withValues(alpha: 0.40)
                  : AC.border,
              width: 1.5,
            ),
          ),
          child: _uploadingImage
              ? const Center(
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AC.ocean),
                  ),
                )
              : _selectedImage != null
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AR.sm),
                          child: Image.file(
                            _selectedImage!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 14, color: AC.ocean),
                            const SizedBox(width: 5),
                            Text(
                              _uploadedImageUrl != null
                                  ? 'Uploaded · tap to change'
                                  : 'Selected · tap to change',
                              style: adminUi(size: 12, color: AC.ocean),
                            ),
                          ],
                        ),
                      ],
                    )
                  : widget.initialImagePath.isNotEmpty
                      ? Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AR.sm),
                              child: Image.network(
                                widget.initialImagePath,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                    Icons.broken_image_rounded,
                                    size: 40, color: AC.text3),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Current photo · tap to replace',
                                style: adminUi(size: 12, color: AC.ocean)),
                          ],
                        )
                      : Column(
                          children: [
                            const Icon(Icons.cloud_upload_rounded,
                                size: 28, color: AC.text3),
                            const SizedBox(height: 8),
                            Text('Tap to upload photo',
                                style: adminUi(size: 13, color: AC.text2)),
                            const SizedBox(height: 3),
                            Text('JPG, PNG · Max 5MB',
                                style: adminUi(size: 11, color: AC.text3)),
                          ],
                        ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BOTTOM CTA
  // ══════════════════════════════════════════════════════════
  Widget _buildBottomCta() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AC.surface,
        border: Border(top: BorderSide(color: AC.borderLight)),
      ),
      child: Row(
        children: [
          // Discard button
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
                  Text(
                    'Discard',
                    style: adminUi(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AC.text1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Save Changes button
          Expanded(
            child: GestureDetector(
              onTap: _isSaving ? null : _handleSave,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AC.ocean, AC.oceanMid]),
                  borderRadius: BorderRadius.circular(AR.full),
                  boxShadow: [
                    BoxShadow(
                      color: AC.ocean.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSaving)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                    else
                      const Icon(Icons.save_rounded,
                          size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _isSaving ? 'Saving…' : 'Save Changes',
                      style: adminUi(
                          size: 14,
                          weight: FontWeight.w700,
                          color: Colors.white),
                    ),
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
