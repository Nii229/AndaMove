// ============================================================
// AndaMove — Profile Screen
// File: lib/screens/screen12_profile.dart
//
// Changes (latest):
//   1. Stats strip now DYNAMIC from AppStore
//      → Trip count = 3 base + followedTrips
//      → Places count = savedPois.length
//      → Covered & Avg Rating = placeholder (TODO: real data)
//      → Whole strip tappable → navigates to screen11_trips
//   2. Saved Videos → already wired to screen14_explore ✓
//   3. Saved Places → already wired to screen6_POI ✓
//   4. "Coming Soon" badge + bottom sheet on tap for:
//      Family Sync, Share Live Location, Notifications,
//      Dark Mode, Language, Privacy & Security, Live Chat
//   5. Settings button removed from header
//   6. Full Name, Email, Phone, Country rows + Edit button
//      → navigate to screen15_editPersonalInfo
//   7. Help Center → screen16_helpCenter
//      About AndaMove → screen17_aboutAndaMove
//   8. Sign Out → screen2_login (pushAndRemoveUntil)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_store.dart';
import 'screen14_explore.dart';
import 'screen6_POI.dart';
import 'screen15_editPersonalInfo.dart';
import 'screen16_helpCenter.dart';
import 'screen17_aboutAndaMove.dart';
import 'screen2_login.dart';
import 'screen5_home.dart';
import 'screen7_generateItinerary.dart' show GenerateItineraryScreen;
import 'screen11_trips.dart' show TripsScreen;

// ══════════════════════════════════════════════════════════════
// COLOR TOKENS
// ══════════════════════════════════════════════════════════════
class AppColors {
  static const Color oceanDeep = Color(0xFF0A7FAB);
  static const Color oceanMid = Color(0xFF1AAECF);
  static const Color oceanTint = Color(0xFFEAF8FD);
  static const Color gold = Color(0xFFC8912E);
  static const Color goldLight = Color(0xFFF0C060);
  static const Color goldTint = Color(0xFFFDF5E7);
  static const Color coral = Color(0xFFE8634C);
  static const Color coralTint = Color(0xFFFDF0EE);
  static const Color green = Color(0xFF16A34A);
  static const Color greenTint = Color(0xFFEEF5EE);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleTint = Color(0xFFF3EFFE);
  static const Color bg = Color(0xFFFBF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF5F1EB);
  static const Color border = Color(0xFFE6DDD1);
  static const Color borderLight = Color(0xFFF0EBE2);
  static const Color text1 = Color(0xFF0A1E28);
  static const Color text2 = Color(0xFF5A7A8A);
  static const Color text3 = Color(0xFF9AB0B8);
}

class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;
}

List<BoxShadow> get shadowSm => [
  BoxShadow(
    color: const Color(0xFF0A1F28).withOpacity(0.06),
    blurRadius: 4,
    offset: const Offset(0, 1),
  ),
];
List<BoxShadow> get shadowLg => [
  BoxShadow(
    color: const Color(0xFF0A1F28).withOpacity(0.10),
    blurRadius: 32,
    offset: const Offset(0, 12),
  ),
];
List<BoxShadow> get shadowOcean => [
  BoxShadow(
    color: AppColors.oceanDeep.withOpacity(0.25),
    blurRadius: 20,
    offset: const Offset(0, 8),
  ),
];

// ── Internal data models ─────────────────────────────────────
class _FamilyAvatar {
  final String? initial;
  final Color bg;
  const _FamilyAvatar(this.initial, this.bg);
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;

  // Country code to display name mapping
  static const _countryNames = {
    'MY': 'Malaysia 🇲🇾',
    'TH': 'Thailand 🇹🇭',
    'US': 'United States 🇺🇸',
    'UK': 'United Kingdom 🇬🇧',
    'AU': 'Australia 🇦🇺',
    'SG': 'Singapore 🇸🇬',
  };

  PersonalInfo get _personalInfo {
    final user = _auth.currentUser;
    final name = _userData?['name'] ?? user?.displayName ?? 'Explorer';
    final email = user?.email ?? 'Not set';
    final phone = _userData?['phone'] ?? 'Not set';
    final countryCode = _userData?['country'] ?? '';
    final country = _countryNames[countryCode] ?? countryCode;
    return PersonalInfo(
      fullName: name,
      email: email,
      phone: phone,
      country: country.isEmpty ? 'Not set' : country,
    );
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() => _userData = doc.data());
        }
      } catch (_) {}
    }
  }

  late final AnimationController _sheenCtrl;
  late final Animation<double> _sheenAnim;

  void _onStoreUpdate() => setState(() {});

  static final _familyAvatars = [
    const _FamilyAvatar('S', AppColors.oceanDeep),
    const _FamilyAvatar('M', AppColors.coral),
    const _FamilyAvatar('L', AppColors.green),
    const _FamilyAvatar(null, AppColors.surface2),
  ];

  @override
  void initState() {
    super.initState();
    _sheenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _sheenAnim = Tween<double>(
      begin: -1.5,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _sheenCtrl, curve: Curves.easeInOut));
    AppStore.addListener(_onStoreUpdate);
    _loadUserData();
  }

  @override
  void dispose() {
    AppStore.removeListener(_onStoreUpdate);
    _sheenCtrl.dispose();
    super.dispose();
  }

  // ── Navigate to EditPersonalInfoScreen ────────────────────
  void _openEditProfile() async {
    final result = await Navigator.push<PersonalInfo>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPersonalInfoScreen(initialInfo: _personalInfo),
      ),
    );
    if (result != null) {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': result.fullName,
          'phone': result.phone,
        });
        await user.updateDisplayName(result.fullName);
      }
      _loadUserData(); // refresh
    }
  }

  // ── Sign out ─────────────────────────────────────────────
  void _onSignOut() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SignOutSheet(
        onConfirm: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.pop(context); // close sheet
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  // ── "Coming Soon" bottom sheet ────────────────────────────
  void _showComingSoonSheet(String featureName, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ComingSoonSheet(featureName: featureName, icon: icon, color: color),
    );
  }

  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildProfileHero(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  _buildSavedSection(),
                  _buildPersonalInfoGroup(),
                  _buildFamilyGroup(),
                  _buildSettingsGroup(),
                  _buildPartnerCard(),
                  _buildSupportGroup(),
                  _buildSignOutRow(),
                  _buildVersionFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ══════════════════════════════════════════════════════════
  // HERO
  // ══════════════════════════════════════════════════════════
  Widget _buildProfileHero() {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            bottom: 0,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.2, -1),
              end: Alignment(0.2, 1),
              stops: [0.0, 0.45, 0.90, 1.0],
              colors: [
                Color(0xFF061018),
                Color(0xFF0A2D45),
                Color(0xFF0A6A95),
                Color(0xFF0A7FAB),
              ],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _ProfileStarsPainter()),
              ),
              Positioned(
                top: -10,
                right: -20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.14),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.65],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'My Profile',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildAvatarRow(),
                  const SizedBox(height: 16),
                  _buildStatsStripInline(),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.elliptical(999, 28),
                topRight: Radius.elliptical(999, 28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarRow() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _userData?['name'] ?? user?.displayName ?? 'Explorer';
    final email = user?.email ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar with verified badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.oceanDeep, AppColors.oceanMid],
                ),
                border: Border.all(color: AppColors.gold, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.person_rounded, size: 36, color: Colors.white),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  border: Border.all(color: const Color(0xFF061018), width: 2),
                ),
                child: const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        // Name, email, badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.50),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.gold.withOpacity(0.30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.military_tech_rounded, size: 13, color: AppColors.goldLight),
                        const SizedBox(width: 4),
                        Text(
                          'Gold Explorer',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Edit button
        GestureDetector(
          onTap: _openEditProfile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Edit',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsStripInline() {
    final tripCount = 3 + AppStore.followedTrips.length;
    final placesCount = AppStore.savedPois.length;
    const covered = '86 km';
    const avgRating = '4.9';

    final stats = [
      (tripCount.toString(), 'Trips'),
      (placesCount.toString(), 'Places'),
      (covered, 'Covered'),
      (avgRating, 'Avg Rating'),
    ];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TripsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stats[i].$1,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: i == 3 ? AppColors.goldLight : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stats[i].$2.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Colors.white.withOpacity(0.45),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (i < stats.length - 1)
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: Colors.white.withOpacity(0.12),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SAVED SECTION (videos → Explore, places → POI Detail)
  // ══════════════════════════════════════════════════════════
  Widget _buildSavedSection() {
    final vlogs = AppStore.savedVlogs;
    final pois = AppStore.savedPois;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _groupLabel('SAVED CONTENT'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _savedRow(
                  icon: Icons.play_circle_rounded,
                  iconBg: AppColors.oceanTint,
                  iconColor: AppColors.oceanDeep,
                  title: 'Saved Videos',
                  countLabel: vlogs.isEmpty
                      ? 'Bookmark vlogs from Explore'
                      : '${vlogs.length} saved',
                  child: vlogs.isEmpty
                      ? _emptyHint('No saved videos yet')
                      : SizedBox(
                          height: 84,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                            itemCount: vlogs.length,
                            itemBuilder: (_, i) => _vlogThumb(vlogs[i]),
                          ),
                        ),
                ),
                Container(height: 1, color: AppColors.borderLight),
                _savedRow(
                  icon: Icons.favorite_rounded,
                  iconBg: AppColors.goldTint,
                  iconColor: AppColors.gold,
                  title: 'Saved Places',
                  countLabel: pois.isEmpty
                      ? 'Favourite POIs from home screen'
                      : '${pois.length} saved',
                  child: pois.isEmpty
                      ? _emptyHint('No saved places yet')
                      : SizedBox(
                          height: 84,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                            itemCount: pois.length,
                            itemBuilder: (_, i) => _poiThumb(pois[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String countLabel,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                        ),
                      ),
                      Text(
                        countLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _emptyHint(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.text3),
          ),
        ),
      ),
    );
  }

  Widget _vlogThumb(SavedVlogSummary vlog) {
    // Map vlog titles to their POI image paths for thumbnails
    final thumbImage = _vlogThumbnailPath(vlog.title);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ExploreScreen(initialPage: vlog.storyIndex))),
      child: Container(
        width: 76,
        height: 76,
        margin: const EdgeInsets.only(right: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Try real image, fall back to gradient
            if (thumbImage != null)
              Image.asset(
                thumbImage,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: vlog.thumbColors),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: vlog.thumbColors),
                ),
              ),
            // Play button overlay
            Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.40),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            // Creator avatar
            Positioned(
              bottom: 5,
              left: 5,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: vlog.creatorAvatarColor,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.60),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    vlog.creatorInitials.substring(0, 1),
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // Duration badge
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  vlog.totalDuration,
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
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

  /// Maps vlog titles to POI image paths for thumbnails
  String? _vlogThumbnailPath(String vlogTitle) {
    final lower = vlogTitle.toLowerCase();
    if (lower.contains('kata')) return 'assets/images/cover_kata.jpg';
    if (lower.contains('buddha')) return 'assets/images/cover_bigBuddha.jpg';
    if (lower.contains('jungle') || lower.contains('khao')) return 'assets/images/cover_jungle.jpg';
    if (lower.contains('promthep') || lower.contains('sunset')) return 'assets/images/cover_promthep.jpg';
    if (lower.contains('old town') || lower.contains('phuket town')) return 'assets/images/cover_oldTown.jpg';
    return null;
  }

  Widget _poiThumb(SavedPoiSummary poi) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PoiDetailScreen(
            poi: PoiModel(
              name: poi.name,
              location: poi.location,
              category: poi.category,
              rating: poi.rating,
              description: poi.description,
              longDescription: poi.longDescription,
              openHours: poi.openHours,
              estimatedTime: poi.estimatedTime,
              imagePath: poi.imagePath,
              gradientColors: poi.gradientColors,
              icon: poi.icon,
              priceRange: poi.priceRange,
              isFavourited: true,
              tags: [PoiTag(poi.tagLabel, poi.tagBg, poi.tagFg)],
            ),
          ),
        ),
      ),
      child: Container(
        width: 76,
        height: 76,
        margin: const EdgeInsets.only(right: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Stack(
          children: [
            // Real image with gradient fallback
            Positioned.fill(
              child: poi.imagePath.isNotEmpty
                  ? Image.asset(
                      poi.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: poi.gradientColors),
                        ),
                        child: Center(
                          child: Icon(
                            poi.icon,
                            size: 28,
                            color: Colors.white.withOpacity(0.28),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: poi.gradientColors),
                      ),
                      child: Center(
                        child: Icon(
                          poi.icon,
                          size: 28,
                          color: Colors.white.withOpacity(0.28),
                        ),
                      ),
                    ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  poi.tagLabel.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 8,
                      color: Color(0xFFF0C060),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      poi.rating.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PERSONAL INFO GROUP
  // ══════════════════════════════════════════════════════════
  Widget _buildPersonalInfoGroup() {
    final rows = [
      (
        Icons.person_rounded,
        AppColors.oceanTint,
        AppColors.oceanDeep,
        'Full Name',
        _personalInfo.fullName,
      ),
      (
        Icons.mail_rounded,
        AppColors.goldTint,
        AppColors.gold,
        'Email',
        _personalInfo.email,
      ),
      (
        Icons.phone_rounded,
        AppColors.greenTint,
        AppColors.green,
        'Phone Number',
        _personalInfo.phone,
      ),
      (
        Icons.language_rounded,
        AppColors.purpleTint,
        AppColors.purple,
        'Home Country',
        _personalInfo.country,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _groupLabel('PERSONAL INFO'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: rows.asMap().entries.map((e) {
                final i = e.key;
                final row = e.value;
                final isLast = i == rows.length - 1;
                return _tappableRow(
                  icon: row.$1,
                  iconBg: row.$2,
                  iconColor: row.$3,
                  title: row.$4,
                  sub: row.$5,
                  isLast: isLast,
                  onTap: _openEditProfile,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tappableRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String sub,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : const BorderSide(color: AppColors.borderLight),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      sub,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.text3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FAMILY GROUP — "Coming Soon" for Family Sync & Share Location
  // ══════════════════════════════════════════════════════════
  Widget _buildFamilyGroup() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _groupLabel('FAMILY & GROUP'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // ── Family Sync → Coming Soon ─────────────────
                _comingSoonRow(
                  icon: Icons.group_rounded,
                  iconBg: AppColors.coralTint,
                  iconColor: AppColors.coral,
                  title: 'Family Sync',
                  sub: '3 members connected',
                  featureName: 'Family Sync',
                  isLast: false,
                  trailing: _comingSoonBadge(),
                ),
                // Avatars row (greyed out slightly)
                Opacity(
                  opacity: 0.50,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      children: [
                        _buildOverlappingAvatars(),
                        const SizedBox(width: 8),
                        Text(
                          'Invite more',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Share Live Location → Coming Soon ─────────
                _comingSoonRow(
                  icon: Icons.share_location_rounded,
                  iconBg: AppColors.oceanTint,
                  iconColor: AppColors.oceanDeep,
                  title: 'Share Live Location',
                  sub: 'Visible to family members',
                  featureName: 'Share Live Location',
                  isLast: true,
                  trailing: _comingSoonTogglePlaceholder(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlappingAvatars() {
    const avatarSize = 32.0;
    const overlap = 8.0;
    final n = _familyAvatars.length;
    final totalWidth = avatarSize + (n - 1) * (avatarSize - overlap);
    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        children: _familyAvatars.asMap().entries.map((e) {
          final i = e.key;
          final avatar = e.value;
          return Positioned(
            left: i * (avatarSize - overlap),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatar.bg,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: avatar.initial != null
                  ? Center(
                      child: Text(
                        avatar.initial!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: AppColors.text3,
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SETTINGS GROUP — "Coming Soon" for all items
  // ══════════════════════════════════════════════════════════
  Widget _buildSettingsGroup() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _groupLabel('SETTINGS'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _comingSoonRow(
                  icon: Icons.notifications_rounded,
                  iconBg: AppColors.oceanTint,
                  iconColor: AppColors.oceanDeep,
                  title: 'Notifications',
                  sub: 'Trip reminders, updates',
                  featureName: 'Notifications',
                  isLast: false,
                  trailing: _comingSoonTogglePlaceholder(),
                ),
                _comingSoonRow(
                  icon: Icons.dark_mode_rounded,
                  iconBg: AppColors.surface2,
                  iconColor: AppColors.text2,
                  title: 'Dark Mode',
                  sub: 'Light mode active',
                  featureName: 'Dark Mode',
                  isLast: false,
                  trailing: _comingSoonTogglePlaceholder(),
                ),
                _comingSoonRow(
                  icon: Icons.translate_rounded,
                  iconBg: AppColors.purpleTint,
                  iconColor: AppColors.purple,
                  title: 'Language',
                  sub: 'English',
                  featureName: 'Language',
                  isLast: false,
                  trailing: _comingSoonBadge(),
                ),
                _comingSoonRow(
                  icon: Icons.lock_rounded,
                  iconBg: AppColors.goldTint,
                  iconColor: AppColors.gold,
                  title: 'Privacy & Security',
                  sub: 'Password, data controls',
                  featureName: 'Privacy & Security',
                  isLast: true,
                  trailing: _comingSoonBadge(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SUPPORT GROUP — Help Center + About (live), Live Chat (coming soon)
  // ══════════════════════════════════════════════════════════
  Widget _buildSupportGroup() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _groupLabel('SUPPORT'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Help Center → screen16 (LIVE)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpCenterScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.oceanTint,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              Icons.help_rounded,
                              size: 20,
                              color: AppColors.oceanDeep,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Help Center',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'FAQs, guides, tutorials',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.text2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.text3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Live Chat Support → Coming Soon ───────────
                _comingSoonRow(
                  icon: Icons.chat_rounded,
                  iconBg: AppColors.greenTint,
                  iconColor: AppColors.green,
                  title: 'Live Chat Support',
                  sub: 'Available 8AM – 10PM',
                  featureName: 'Live Chat Support',
                  isLast: false,
                  trailing: _comingSoonBadge(),
                ),
                // About AndaMove → screen17 (LIVE)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutAndaMoveScreen(),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              Icons.info_rounded,
                              size: 20,
                              color: AppColors.text2,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About AndaMove',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Terms, Privacy, Licenses',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.text2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.text3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // "COMING SOON" SHARED WIDGETS
  // ══════════════════════════════════════════════════════════

  /// A full row that is visually dimmed and opens a Coming Soon sheet on tap.
  Widget _comingSoonRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String sub,
    required String featureName,
    required bool isLast,
    required Widget trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showComingSoonSheet(featureName, icon, iconColor),
        child: Opacity(
          opacity: 0.55,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _soonPill(),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        sub,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Small "Soon" pill badge — sits next to the title.
  Widget _soonPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.gold.withOpacity(0.25)),
      ),
      child: Text(
        'Soon',
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppColors.gold,
        ),
      ),
    );
  }

  /// The "Coming Soon" badge used as trailing widget on chevron rows.
  Widget _comingSoonBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AppColors.text3,
        ),
      ],
    );
  }

  /// Disabled toggle placeholder for toggle-style rows.
  Widget _comingSoonTogglePlaceholder() {
    return Container(
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PARTNER CARD
  // ══════════════════════════════════════════════════════════
  Widget _buildPartnerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
          colors: [Color(0xFF061018), Color(0xFF0A3D5C), Color(0xFF0A7FAB)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.65],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    color: AppColors.gold.withOpacity(0.15),
                    border: Border.all(color: AppColors.gold.withOpacity(0.30)),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 22,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FOR BUSINESSES',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: Colors.white.withOpacity(0.50),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Be Our Partner',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'List your attraction, hotel or restaurant',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: Colors.white.withOpacity(0.10),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
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
  // SIGN OUT
  // ══════════════════════════════════════════════════════════
  Widget _buildSignOutRow() {
    return GestureDetector(
      onTap: _onSignOut,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.coralTint,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppColors.coral.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 19, color: AppColors.coral),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.text3),
            children: [
              const TextSpan(text: 'AndaMove v1.0.0 · Built by '),
              TextSpan(
                text: 'Fatini',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.oceanMid,
                ),
              ),
              const TextSpan(text: ' · FYP 2026'),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BOTTOM NAV
  // ══════════════════════════════════════════════════════════
  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded, 'Home', false),
      (Icons.explore_rounded, 'Explore', false),
      (Icons.map_rounded, 'Trips', false),
      (Icons.person_rounded, 'Profile', true),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [0.70, 1.0],
          colors: [AppColors.surface, Colors.transparent],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: shadowLg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _navItem(
              items[0],
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              ),
            ),
            _navItem(
              items[1],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExploreScreen()),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GenerateItineraryScreen(),
                          ),
                        ),
                        child: AnimatedBuilder(
                          animation: _sheenAnim,
                          builder: (_, __) => Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.oceanDeep,
                                  AppColors.oceanMid,
                                ],
                              ),
                              boxShadow: shadowOcean,
                            ),
                            child: ClipOval(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _SheenPainter(
                                        position: _sheenAnim.value,
                                      ),
                                    ),
                                  ),
                                  const Center(
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'PLAN',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.oceanDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _navItem(
              items[2],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TripsScreen()),
              ),
            ),
            _navItem(items[3], onTap: () {}), // already on Profile
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    (IconData, String, bool) item, {
    required VoidCallback onTap,
  }) {
    final (icon, label, isActive) = item;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.oceanTint : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.oceanDeep : AppColors.text3,
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isActive ? AppColors.oceanDeep : AppColors.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: AppColors.text3,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// "COMING SOON" BOTTOM SHEET
// ══════════════════════════════════════════════════════════════
class _ComingSoonSheet extends StatelessWidget {
  final String featureName;
  final IconData icon;
  final Color color;
  const _ComingSoonSheet({
    required this.featureName,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Icon circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.20), width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 18),
          // Title
          Text(
            'Coming Soon',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
            ),
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            '$featureName is currently under development and will be available in a future update of AndaMove.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.text2,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stay tuned! 🚀',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.text3),
          ),
          const SizedBox(height: 28),
          // Got It button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              child: Text(
                'Got It',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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
// SIGN OUT CONFIRMATION SHEET
// ══════════════════════════════════════════════════════════════
class _SignOutSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _SignOutSheet({required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.coralTint,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.coral.withOpacity(0.30),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.coral,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sign Out?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will be returned to the login screen.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.text2,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              child: Text(
                'Yes, Sign Out',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text1,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              child: Text(
                'Stay',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text1,
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
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════
class _ProfileStarsPainter extends CustomPainter {
  const _ProfileStarsPainter();
  static const _dots = [
    (60.0, 50.0, 0.75, 0.50),
    (250.0, 30.0, 0.50, 0.40),
    (330.0, 70.0, 0.50, 0.30),
    (100.0, 160.0, 0.50, 0.20),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    for (final d in _dots) {
      canvas.drawCircle(
        Offset(d.$1, d.$2),
        d.$3,
        Paint()..color = Colors.white.withOpacity(d.$4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _SheenPainter extends CustomPainter {
  final double position;
  const _SheenPainter({required this.position});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(position * size.width, 0, size.width * 0.30, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.position != position;
}
