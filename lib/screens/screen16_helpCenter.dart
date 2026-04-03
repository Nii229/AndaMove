// ============================================================
// AndaMove — Help Center Screen
// File: lib/screens/screen16_helpCenter.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color oceanDeep   = Color(0xFF0A7FAB);
  static const Color oceanMid    = Color(0xFF1AAECF);
  static const Color oceanTint   = Color(0xFFEAF8FD);
  static const Color gold        = Color(0xFFC8912E);
  static const Color goldTint    = Color(0xFFFDF5E7);
  static const Color coral       = Color(0xFFE8634C);
  static const Color coralTint   = Color(0xFFFDF0EE);
  static const Color green       = Color(0xFF16A34A);
  static const Color greenTint   = Color(0xFFEEF5EE);
  static const Color purple      = Color(0xFF7C3AED);
  static const Color purpleTint  = Color(0xFFF3EFFE);
  static const Color bg          = Color(0xFFFBF8F3);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color surface2    = Color(0xFFF5F1EB);
  static const Color border      = Color(0xFFE6DDD1);
  static const Color borderLight = Color(0xFFF0EBE2);
  static const Color text1       = Color(0xFF0A1E28);
  static const Color text2       = Color(0xFF5A7A8A);
  static const Color text3       = Color(0xFF9AB0B8);
}

class AppRadius {
  static const double sm   = 8;
  static const double md   = 14;
  static const double lg   = 20;
  static const double xl   = 28;
  static const double full = 999;
}

List<BoxShadow> get shadowSm => [
  BoxShadow(color: const Color(0xFF0A1F28).withOpacity(0.06),
      blurRadius: 4, offset: const Offset(0, 1))
];
List<BoxShadow> get shadowOcean => [
  BoxShadow(color: AppColors.oceanDeep.withOpacity(0.25),
      blurRadius: 20, offset: const Offset(0, 8))
];

// ══════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════
class _FaqItem {
  final String question;
  final String answer;
  bool expanded;

  _FaqItem({
    required this.question,
    required this.answer,
    this.expanded = false,
  });
}

class _FaqCategory {
  final String       title;
  final IconData     icon;
  final Color        iconColor;
  final Color        iconBg;
  final List<_FaqItem> items;

  const _FaqCategory({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.items,
  });
}

class _ContactOption {
  final IconData icon;
  final Color    iconColor;
  final Color    iconBg;
  final String   title;
  final String   subtitle;
  final String   badge;
  final Color    badgeBg;
  final Color    badgeFg;

  const _ContactOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
  });
}

// ══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int    _selectedCat = 0;

  // ── FAQ data ───────────────────────────────────────────────
  final List<_FaqCategory> _categories = [
    _FaqCategory(
      title:     'Getting Started',
      icon:      Icons.rocket_launch_rounded,
      iconColor: AppColors.oceanDeep,
      iconBg:    AppColors.oceanTint,
      items: [
        _FaqItem(
          question: 'How do I create an itinerary?',
          answer:
              'Tap the PLAN button (+ icon) in the bottom navigation bar. '
              'Select your transport mode, choose categories, pick your favourite '
              'POIs from the list, set a date and start time, then tap '
              '"Generate My Itinerary". AndaMove will build an optimised route for you.',
        ),
        _FaqItem(
          question: 'Can I edit my itinerary after generating it?',
          answer:
              'Yes! On the Itinerary Result screen, tap "Edit stops" at the top right '
              'to go back and change your POI selection. You can also rename your '
              'itinerary by tapping the pencil icon next to the title.',
        ),
        _FaqItem(
          question: 'How do I save a trip to My Trips?',
          answer:
              'From the Itinerary Result screen, tap the back arrow — this automatically '
              'saves your itinerary as a Draft to My Trips. You can also start navigation '
              'and end the trip to mark it as completed.',
        ),
      ],
    ),
    _FaqCategory(
      title:     'Navigation',
      icon:      Icons.navigation_rounded,
      iconColor: AppColors.green,
      iconBg:    AppColors.greenTint,
      items: [
        _FaqItem(
          question: 'How does the navigation feature work?',
          answer:
              'From the Itinerary Result screen, tap "Start Navigation". The Navigation '
              'screen shows a map view with your current position, step-by-step turn '
              'instructions, and an ETA strip. Tap "Next Stop" to advance through your '
              'route steps.',
        ),
        _FaqItem(
          question: 'What transport modes are supported?',
          answer:
              'AndaMove supports Scooter, Tuk-tuk, Car, and Walking. Select your '
              'preferred mode when generating an itinerary. Travel time estimates '
              'are calculated accordingly.',
        ),
        _FaqItem(
          question: 'How do I end a trip early?',
          answer:
              'On the Navigation screen, tap the coral "End Trip" button. A confirmation '
              'sheet will appear — tap "Yes, End Trip" to save your progress and return '
              'to My Trips.',
        ),
      ],
    ),
    _FaqCategory(
      title:     'My Trips',
      icon:      Icons.map_rounded,
      iconColor: AppColors.gold,
      iconBg:    AppColors.goldTint,
      items: [
        _FaqItem(
          question: 'What do the different trip statuses mean?',
          answer:
              '"In Progress" — a trip you are actively navigating. '
              '"Upcoming" — a scheduled future trip. '
              '"Completed" — a finished trip. '
              '"Draft" — an unscheduled itinerary you saved or imported.',
        ),
        _FaqItem(
          question: 'Can I duplicate a trip?',
          answer:
              'Yes. Tap the ⋮ kebab menu on any trip card, then select "Duplicate". '
              'A copy will be added to your list with "(Copy)" appended to the name.',
        ),
        _FaqItem(
          question: 'How do I rename a trip?',
          answer:
              'Tap the ⋮ kebab menu on the trip card and select "Rename". '
              'A dialog will appear where you can type a new name and tap "Save".',
        ),
      ],
    ),
    _FaqCategory(
      title:     'Account',
      icon:      Icons.person_rounded,
      iconColor: AppColors.purple,
      iconBg:    AppColors.purpleTint,
      items: [
        _FaqItem(
          question: 'How do I update my personal information?',
          answer:
              'Go to Profile → tap your name or the "Edit" button → Edit Profile. '
              'You can update your Full Name, Email, Phone Number, and Home Country. '
              'Tap "Save Changes" to apply.',
        ),
        _FaqItem(
          question: 'How do I turn off notifications?',
          answer:
              'Go to Profile → Settings → Notifications toggle. '
              'Tap the toggle to turn trip reminders on or off.',
        ),
        _FaqItem(
          question: 'Is my location data shared with anyone?',
          answer:
              'Your live location is only shared with family members you have connected '
              'via Family Sync, and only when the "Share Live Location" toggle is on. '
              'We never share your data with third parties. See our Privacy Policy for details.',
        ),
      ],
    ),
  ];

  static const _contactOptions = [
    _ContactOption(
      icon:      Icons.chat_bubble_rounded,
      iconColor: AppColors.green,
      iconBg:    AppColors.greenTint,
      title:     'Live Chat',
      subtitle:  'Average reply: 2 min',
      badge:     'Online',
      badgeBg:   AppColors.greenTint,
      badgeFg:   AppColors.green,
    ),
    _ContactOption(
      icon:      Icons.mail_rounded,
      iconColor: AppColors.oceanDeep,
      iconBg:    AppColors.oceanTint,
      title:     'Email Support',
      subtitle:  'support@andamove.app',
      badge:     '< 24 h',
      badgeBg:   AppColors.oceanTint,
      badgeFg:   AppColors.oceanDeep,
    ),
    _ContactOption(
      icon:      Icons.bug_report_rounded,
      iconColor: AppColors.coral,
      iconBg:    AppColors.coralTint,
      title:     'Report a Bug',
      subtitle:  'Help us improve',
      badge:     'GitHub',
      badgeBg:   AppColors.coralTint,
      badgeFg:   AppColors.coral,
    ),
  ];

  List<_FaqItem> get _searchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _categories
        .expand((c) => c.items)
        .where((i) =>
            i.question.toLowerCase().contains(q) ||
            i.answer.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  if (_searchQuery.isNotEmpty)
                    _buildSearchResults()
                  else ...[
                    _buildCategoryTabs(),
                    const SizedBox(height: 16),
                    _buildFaqList(),
                    const SizedBox(height: 28),
                    _buildContactSection(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 14),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 19, color: AppColors.text1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Help Center',
                        style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text1)),
                    Text('FAQs & Support',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: AppColors.text2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
          colors: [Color(0xFF061018), Color(0xFF0A3D5C), Color(0xFF0A7FAB)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
            ),
            child: const Icon(Icons.help_outline_rounded,
                size: 26, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How can we help?',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('Browse FAQs or reach our support team',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.60))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
          boxShadow: shadowSm,
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                size: 20, color: AppColors.oceanDeep),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.outfit(
                    fontSize: 14, color: AppColors.text1),
                decoration: InputDecoration(
                  hintText: 'Search FAQs…',
                  hintStyle: GoogleFonts.outfit(
                      fontSize: 14, color: AppColors.text3),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          splashRadius: 16,
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.text3),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat    = _categories[i];
          final active = i == _selectedCat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.oceanDeep : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                    color: active
                        ? AppColors.oceanDeep
                        : AppColors.border,
                    width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon,
                      size: 14,
                      color: active ? Colors.white : AppColors.text2),
                  const SizedBox(width: 5),
                  Text(cat.title,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : AppColors.text2)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFaqList() {
    final cat = _categories[_selectedCat];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: cat.iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(cat.icon, size: 16, color: cat.iconColor),
            ),
            const SizedBox(width: 10),
            Text(cat.title,
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1)),
            const Spacer(),
            Text('${cat.items.length} articles',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: AppColors.text3)),
          ]),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: cat.items.asMap().entries.map((e) {
                final i    = e.key;
                final item = e.value;
                final isLast = i == cat.items.length - 1;
                return _buildFaqTile(item, isLast: isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(_FaqItem item, {required bool isLast}) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => item.expanded = !item.expanded),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(item.question,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: item.expanded
                              ? AppColors.oceanDeep
                              : AppColors.text1,
                          height: 1.4)),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns:    item.expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: item.expanded
                        ? AppColors.oceanDeep
                        : AppColors.text3,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            color: AppColors.oceanTint,
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(item.answer,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.text2,
                    height: 1.6)),
          ),
          crossFadeState: item.expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (!isLast)
          const Divider(
              height: 1, color: AppColors.borderLight),
      ],
    );
  }

  Widget _buildSearchResults() {
    final results = _searchResults;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            results.isEmpty
                ? 'No results for "$_searchQuery"'
                : '${results.length} result${results.length == 1 ? '' : 's'} for "$_searchQuery"',
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text2),
          ),
          const SizedBox(height: 12),
          if (results.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 32, color: AppColors.text3),
                  const SizedBox(height: 10),
                  Text('No FAQs matched your search',
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text2)),
                  const SizedBox(height: 4),
                  Text('Try different keywords or contact support',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.text3)),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: shadowSm,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: results.asMap().entries.map((e) {
                  final isLast = e.key == results.length - 1;
                  return _buildFaqTile(e.value, isLast: isLast);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STILL NEED HELP?',
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.text3)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: shadowSm,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _contactOptions.asMap().entries.map((e) {
                final i    = e.key;
                final opt  = e.value;
                final isLast = i == _contactOptions.length - 1;
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                    color: opt.iconBg,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.md)),
                                child: Icon(opt.icon,
                                    size: 22, color: opt.iconColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(opt.title,
                                        style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.text1)),
                                    const SizedBox(height: 1),
                                    Text(opt.subtitle,
                                        style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: AppColors.text2)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: opt.badgeBg,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.full)),
                                child: Text(opt.badge,
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: opt.badgeFg)),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 18, color: AppColors.text3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                          height: 1, color: AppColors.borderLight),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
