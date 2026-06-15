// ============================================================
// AndaMove — Itinerary Scheduler
// File: lib/services/itinerary_scheduler.dart
//
// PURPOSE
//   Pure scheduling logic. Takes the ALREADY-OPTIMIZED POI order
//   from screen7 (nearest-neighbour) plus a start date/time and
//   transport, and produces a realistic, day-split plan:
//
//     • Fix #1 — respects each POI's real opening hours
//     • Fix #2 — auto-inserts lunch (~12:00) and dinner (~19:00)
//     • Fix #3 — splits into Day 1, Day 2, … when a day overflows
//     • Fix #4 — each day ends by a category-aware cutoff; the
//                rest rolls to the next day instead of running
//                all night
//
//   This file has NO Flutter UI and NO Firestore code, so it can
//   be unit-tested and reused anywhere.
//
// HOW IT FITS
//   screen7  → optimises ORDER, fetches real travel minutes
//   THIS     → turns that order into a timed, multi-day schedule
//   screen8  → renders List<ItineraryDay>
//
// INPUT CONTRACT
//   Each ScheduleStop carries:
//     • stayMinutes        (from screen7 chips / suggested)
//     • travelMinutesToHere(real Distance Matrix value; 0 for first)
//     • openHours          (raw POI string, parsed here)
//     • category           (drives cutoff + meal/nightlife rules)
// ============================================================

import 'opening_hours.dart';

// ══════════════════════════════════════════════════════════════
// TUNABLES — all real-world assumptions live here, one place.
// Backed by research (see Bangla Road note below).
// ══════════════════════════════════════════════════════════════
class SchedulerConfig {
  /// Latest a NORMAL (non-nightlife) activity may *start*.
  /// After this, sightseeing winds down.
  static const int dayWindDownHour = 18; // 6:00 PM

  /// Hard cutoff for a normal day's last activity to *end*.
  /// Anything that would end later rolls to the next day.
  static const int dayHardEndHour = 22; // 10:00 PM

  /// Nightlife is special. Research (Bangla Road, Illuzion, etc.):
  /// pedestrianised ~6pm, busy 9pm–2/3am, peak 11pm–2am.
  /// So nightlife may start late and run past the normal cutoff.
  static const int nightlifeEarliestStartHour = 18; // 6:00 PM
  static const int nightlifeHardEndHour = 26; // 2:00 AM (24 + 2)

  /// Meal windows. Fixed 1h blocks, per the chosen design.
  static const int lunchHour = 12;
  static const int lunchDurationMin = 60;
  static const int dinnerHour = 19; // 7:00 PM
  static const int dinnerDurationMin = 60;

  /// A meal is only auto-inserted if the day actually spans that
  /// window AND no Food POI is already sitting close to it.
  /// "Close" = within this many minutes of the meal hour.
  static const int mealNearbyToleranceMin = 75;

  /// Fallback travel time when screen7 couldn't supply a real one
  /// (no coords / API failure). Matches the old flat buffer.
  static const int fallbackTravelMin = 15;

  /// Safety valve so a pathological input can't loop forever.
  static const int maxDays = 14;
}

// ══════════════════════════════════════════════════════════════
// INPUT MODEL
// One per POI the user selected, in OPTIMISED order.
// ══════════════════════════════════════════════════════════════
class ScheduleStop {
  final String name;
  final String category;
  final String imagePath;
  final double rating;
  final double latitude;
  final double longitude;

  /// Minutes the user wants to stay (from screen7).
  final int stayMinutes;

  /// REAL travel minutes from the PREVIOUS stop to this one,
  /// parsed from screen7's Distance Matrix result. 0 for the
  /// first stop of the whole trip.
  final int travelMinutesToHere;

  /// Raw opening-hours string straight off the POI
  /// (e.g. "8:00 AM - 7:30 PM", "Open 24 hours", "6:00 PM - Late").
  final String openHours;

  /// Human label of the original travel text ("12 mins", "2.4 km")
  /// — kept only so screen8 can show what screen7 showed.
  final String travelLabel;

  const ScheduleStop({
    required this.name,
    required this.category,
    required this.imagePath,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.stayMinutes,
    required this.travelMinutesToHere,
    required this.openHours,
    required this.travelLabel,
  });

  bool get isNightlife => category.toLowerCase() == 'nightlife';
  bool get isFood => category.toLowerCase() == 'food';
}

// ══════════════════════════════════════════════════════════════
// OUTPUT MODELS
// ══════════════════════════════════════════════════════════════

/// What kind of timeline entry this is.
enum ItineraryEntryKind { poi, meal }

/// A single timed row in a day's schedule. Either a POI visit or
/// an inserted meal break. Times are absolute minutes-from-midnight
/// on that day (0–1439), except an entry that runs past midnight
/// keeps a >1439 [endMinutes] so the UI can show "1:30 AM".
class ItineraryEntry {
  final ItineraryEntryKind kind;

  /// Present only when kind == poi.
  final ScheduleStop? stop;

  /// Present only when kind == meal ("Lunch" / "Dinner").
  final String? mealLabel;

  /// Travel minutes spent getting to this entry (0 if none / meal).
  final int travelMinutes;

  /// Absolute clock, minutes from midnight of this day.
  final int startMinutes;
  final int endMinutes;

  /// True when this POI had to be reordered/placed to satisfy
  /// opening hours (so the UI can show a subtle "adjusted" hint).
  final bool wasAdjustedForHours;

  const ItineraryEntry({
    required this.kind,
    this.stop,
    this.mealLabel,
    required this.travelMinutes,
    required this.startMinutes,
    required this.endMinutes,
    this.wasAdjustedForHours = false,
  });

  bool get isMeal => kind == ItineraryEntryKind.meal;
  bool get isPoi => kind == ItineraryEntryKind.poi;
  int get durationMinutes => endMinutes - startMinutes;
}

/// One day of the trip. dayIndex is 0-based; dayNumber is 1-based
/// for display. [date] is the calendar date for this day.
class ItineraryDay {
  final int dayIndex;
  final DateTime date;
  final List<ItineraryEntry> entries;

  const ItineraryDay({
    required this.dayIndex,
    required this.date,
    required this.entries,
  });

  int get dayNumber => dayIndex + 1;

  Iterable<ItineraryEntry> get poiEntries =>
      entries.where((e) => e.isPoi);

  int get poiCount => poiEntries.length;

  /// First start and last end of the day (minutes from midnight).
  int get firstStart =>
      entries.isEmpty ? 0 : entries.first.startMinutes;
  int get lastEnd =>
      entries.isEmpty ? 0 : entries.last.endMinutes;

  /// Total POI stay minutes (excludes meals & travel).
  int get totalStayMinutes => poiEntries.fold<int>(
      0, (a, e) => a + (e.stop?.stayMinutes ?? 0));

  /// Total travel minutes across the day.
  int get totalTravelMinutes =>
      entries.fold<int>(0, (a, e) => a + e.travelMinutes);
}

/// Full result: every day, plus anything that couldn't be placed
/// (e.g. a POI that's closed every day in the date range — rare,
/// but we surface it instead of silently dropping it).
class ItinerarySchedule {
  final List<ItineraryDay> days;
  final List<ScheduleStop> unplaced;

  const ItinerarySchedule({
    required this.days,
    required this.unplaced,
  });

  int get totalDays => days.length;
  int get totalStops =>
      days.fold<int>(0, (a, d) => a + d.poiCount);
}

// ══════════════════════════════════════════════════════════════
// THE SCHEDULER
// ══════════════════════════════════════════════════════════════
class ItineraryScheduler {
  /// Build a realistic multi-day schedule.
  ///
  /// [stops]      POIs in OPTIMISED order (screen7 output).
  /// [startDate]  Calendar date of Day 1.
  /// [startHour]/[startMinute]  When Day 1 begins.
  static ItinerarySchedule build({
    required List<ScheduleStop> stops,
    required DateTime startDate,
    required int startHour,
    required int startMinute,
  }) {
    if (stops.isEmpty) {
      return const ItinerarySchedule(days: [], unplaced: []);
    }

    // Separate nightlife from the rest. Nightlife is always placed
    // LAST within whatever day it lands on, and is allowed to run
    // late. Everything else keeps screen7's optimised order.
    final daytime = stops.where((s) => !s.isNightlife).toList();
    final nightlife = stops.where((s) => s.isNightlife).toList();

    final days = <ItineraryDay>[];
    final unplaced = <ScheduleStop>[];

    // Queue of daytime stops still to place, in order.
    final queue = List<ScheduleStop>.from(daytime);

    int dayIndex = 0;
    final firstDayStart = startHour * 60 + startMinute;

    while (queue.isNotEmpty && dayIndex < SchedulerConfig.maxDays) {
      final dayDate = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      ).add(Duration(days: dayIndex));

      // Day 1 honours the user's start time; later days start at
      // a normal morning hour.
      final dayStartMin =
          dayIndex == 0 ? firstDayStart : _defaultDayStartMin(startDate);

      final built = _buildOneDay(
        date: dayDate,
        dayIndex: dayIndex,
        dayStartMinutes: dayStartMin,
        queue: queue, // mutated: placed stops are removed
      );

      // Guard: if a day placed nothing (e.g. the next stop simply
      // can't fit any normal day), bump it to unplaced to avoid an
      // infinite loop, and move on.
      if (built.entries.where((e) => e.isPoi).isEmpty &&
          queue.isNotEmpty) {
        unplaced.add(queue.removeAt(0));
        continue;
      }

      days.add(built);
      dayIndex++;
    }

    // Anything still queued after maxDays is unplaced.
    unplaced.addAll(queue);

    // Place nightlife: attach each nightlife POI to the END of an
    // existing day (prefer the last day that still has room before
    // the nightlife hard-end). If none, it spills to a new evening.
    if (nightlife.isNotEmpty) {
      _placeNightlife(days, nightlife, startDate, unplaced);
    }

    return ItinerarySchedule(days: days, unplaced: unplaced);
  }

  // ────────────────────────────────────────────────────────────
  // Build a single day by greedily pulling stops off [queue] until
  // the next one won't fit before the hard end. Inserts meals.
  // ────────────────────────────────────────────────────────────
  static ItineraryDay _buildOneDay({
    required DateTime date,
    required int dayIndex,
    required int dayStartMinutes,
    required List<ScheduleStop> queue,
  }) {
    final entries = <ItineraryEntry>[];
    int clock = dayStartMinutes; // minutes from midnight
    bool lunchInserted = false;
    bool dinnerInserted = false;
    bool isFirstStopOfDay = true;

    final hardEnd = SchedulerConfig.dayHardEndHour * 60;
    final windDown = SchedulerConfig.dayWindDownHour * 60;

    while (queue.isNotEmpty) {
      final stop = queue.first;

      // Travel to this stop. First stop of the WHOLE trip has 0;
      // first stop of a LATER day uses its stored travel (or
      // fallback) — we still show travel because you're moving from
      // wherever you slept.
      final travel = isFirstStopOfDay && dayIndex == 0
          ? 0
          : (stop.travelMinutesToHere > 0
              ? stop.travelMinutesToHere
              : SchedulerConfig.fallbackTravelMin);

      // ── Maybe insert LUNCH before this stop ──────────────────
      final lunchAt = SchedulerConfig.lunchHour * 60;
      if (!lunchInserted &&
          _daySpansMeal(dayStartMinutes, clock, lunchAt) &&
          clock + travel >= lunchAt - SchedulerConfig.mealNearbyToleranceMin) {
        final alreadyEatingNearby = _foodNear(entries, lunchAt);
        if (!alreadyEatingNearby) {
          final mealStart = clock < lunchAt ? lunchAt : clock;
          final mealEnd = mealStart + SchedulerConfig.lunchDurationMin;
          entries.add(ItineraryEntry(
            kind: ItineraryEntryKind.meal,
            mealLabel: 'Lunch',
            travelMinutes: 0,
            startMinutes: mealStart,
            endMinutes: mealEnd,
          ));
          clock = mealEnd;
        }
        lunchInserted = true;
      }

      // ── Maybe insert DINNER before this stop ─────────────────
      final dinnerAt = SchedulerConfig.dinnerHour * 60;
      if (!dinnerInserted &&
          _daySpansMeal(dayStartMinutes, clock, dinnerAt) &&
          clock + travel >= dinnerAt - SchedulerConfig.mealNearbyToleranceMin) {
        final alreadyEatingNearby = _foodNear(entries, dinnerAt);
        if (!alreadyEatingNearby) {
          final mealStart = clock < dinnerAt ? dinnerAt : clock;
          final mealEnd = mealStart + SchedulerConfig.dinnerDurationMin;
          // Only insert dinner if it doesn't itself blow past the
          // hard end — otherwise the day is over anyway.
          if (mealStart < hardEnd) {
            entries.add(ItineraryEntry(
              kind: ItineraryEntryKind.meal,
              mealLabel: 'Dinner',
              travelMinutes: 0,
              startMinutes: mealStart,
              endMinutes: mealEnd,
            ));
            clock = mealEnd;
          }
          dinnerInserted = true;
        } else {
          dinnerInserted = true;
        }
      }

      // ── Compute this stop's window with opening hours ────────
      final arrival = clock + travel;
      final window = OpeningHours.parse(stop.openHours);

      // Resolve the actual start given opening hours:
      //  • if closed-all-day → can't place today
      //  • if arrive before opening → wait until it opens
      //  • if arrive after last-entry (close - stay) → too late today
      final placement = _resolveStart(
        arrivalMinutes: arrival,
        stayMinutes: stop.stayMinutes,
        window: window,
        windDownMinutes: windDown,
        hardEndMinutes: hardEnd,
      );

      if (placement == null) {
        // Doesn't fit today. Stop filling this day; leave [stop]
        // (and the rest) in the queue for the next day.
        break;
      }

      final start = placement.start;
      final end = start + stop.stayMinutes;

      entries.add(ItineraryEntry(
        kind: ItineraryEntryKind.poi,
        stop: stop,
        travelMinutes: travel,
        startMinutes: start,
        endMinutes: end,
        wasAdjustedForHours: placement.adjusted,
      ));

      clock = end;
      queue.removeAt(0);
      isFirstStopOfDay = false;
    }

    return ItineraryDay(dayIndex: dayIndex, date: date, entries: entries);
  }

  // ────────────────────────────────────────────────────────────
  // Decide when a stop can start, honouring opening hours and the
  // day's wind-down / hard-end. Returns null if it can't fit today.
  // ────────────────────────────────────────────────────────────
  static _Placement? _resolveStart({
    required int arrivalMinutes,
    required int stayMinutes,
    required OpeningHours window,
    required int windDownMinutes,
    required int hardEndMinutes,
  }) {
    // 24h places: only constrained by the day's own end.
    if (window.isAlwaysOpen) {
      if (arrivalMinutes > windDownMinutes) {
        // Past wind-down for a normal POI → leave for tomorrow
        // unless it still ends before hard end and we simply have
        // nothing else; we choose to roll it for a saner day.
        if (arrivalMinutes + stayMinutes > hardEndMinutes) return null;
      }
      if (arrivalMinutes + stayMinutes > hardEndMinutes) return null;
      return _Placement(arrivalMinutes, false);
    }

    // Closed entirely (couldn't parse a sane window) → not today.
    if (!window.hasWindow) return null;

    final open = window.openMinutes!;
    final close = window.closeMinutes!;

    // Latest you can START and still finish your stay before close.
    final lastStart = close - stayMinutes;

    // If the stay can't even fit between open and close, it never
    // fits on a normal day → unplaced (caller will surface it).
    if (lastStart < open) return null;

    int start = arrivalMinutes;
    bool adjusted = false;

    if (start < open) {
      // Arrived early — wait for opening.
      start = open;
      adjusted = true;
    }

    if (start > lastStart) {
      // Arrived too late to finish before close → not today.
      return null;
    }

    // Respect the day's hard end too.
    if (start + stayMinutes > hardEndMinutes) return null;

    return _Placement(start, adjusted);
  }

  // ────────────────────────────────────────────────────────────
  // Nightlife placement. Each nightlife POI goes at the END of a
  // day, allowed to run to the nightlife hard-end (2 AM). Prefer
  // attaching to the LAST built day; if that day's last activity
  // already ends after the nightlife window, open a fresh evening.
  // ────────────────────────────────────────────────────────────
  static void _placeNightlife(
    List<ItineraryDay> days,
    List<ScheduleStop> nightlife,
    DateTime startDate,
    List<ScheduleStop> unplaced,
  ) {
    final earliest = SchedulerConfig.nightlifeEarliestStartHour * 60;
    final nightEnd = SchedulerConfig.nightlifeHardEndHour * 60;

    for (final club in nightlife) {
      final window = OpeningHours.parse(club.openHours);

      // Effective opening for nightlife: max(parsed open, 6pm).
      int openMin = earliest;
      if (window.hasWindow && window.openMinutes != null) {
        openMin = window.openMinutes! > earliest
            ? window.openMinutes!
            : earliest;
      }

      bool placed = false;

      // Try to append to an existing day (latest first).
      for (int i = days.length - 1; i >= 0; i--) {
        final day = days[i];
        final dayLastEnd = day.entries.isEmpty ? 0 : day.lastEnd;

        // Travel from the day's last stop (or fallback).
        final travel = club.travelMinutesToHere > 0
            ? club.travelMinutesToHere
            : SchedulerConfig.fallbackTravelMin;

        int start = dayLastEnd + travel;
        if (start < openMin) start = openMin;

        final end = start + club.stayMinutes;
        if (end <= nightEnd) {
          final updated = List<ItineraryEntry>.from(day.entries)
            ..add(ItineraryEntry(
              kind: ItineraryEntryKind.poi,
              stop: club,
              travelMinutes: travel,
              startMinutes: start,
              endMinutes: end,
              wasAdjustedForHours: start == openMin && dayLastEnd + travel < openMin,
            ));
          days[i] = ItineraryDay(
            dayIndex: day.dayIndex,
            date: day.date,
            entries: updated,
          );
          placed = true;
          break;
        }
      }

      // Couldn't attach → new evening-only day after the last one.
      if (!placed) {
        final newIndex = days.isEmpty ? 0 : days.last.dayIndex + 1;
        if (newIndex >= SchedulerConfig.maxDays) {
          unplaced.add(club);
          continue;
        }
        final date = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        ).add(Duration(days: newIndex));

        final start = openMin;
        final end = start + club.stayMinutes;
        days.add(ItineraryDay(
          dayIndex: newIndex,
          date: date,
          entries: [
            ItineraryEntry(
              kind: ItineraryEntryKind.poi,
              stop: club,
              travelMinutes: 0,
              startMinutes: start,
              endMinutes: end,
            ),
          ],
        ));
      }
    }
  }

  // ── Small helpers ────────────────────────────────────────────

  /// Default morning start for Day 2+ (9:00 AM).
  static int _defaultDayStartMin(DateTime _) => 9 * 60;

  /// Does this day plausibly cover [mealAt]? True if the day starts
  /// before the meal window and we've reached/passed near it.
  static bool _daySpansMeal(int dayStart, int clock, int mealAt) {
    return dayStart <= mealAt + SchedulerConfig.mealNearbyToleranceMin;
  }

  /// Is there already a Food POI entry within tolerance of [mealAt]?
  static bool _foodNear(List<ItineraryEntry> entries, int mealAt) {
    for (final e in entries) {
      if (e.isPoi && (e.stop?.isFood ?? false)) {
        final mid = (e.startMinutes + e.endMinutes) ~/ 2;
        if ((mid - mealAt).abs() <= SchedulerConfig.mealNearbyToleranceMin) {
          return true;
        }
      }
    }
    return false;
  }
}

/// Internal: resolved start + whether opening hours forced a shift.
class _Placement {
  final int start;
  final bool adjusted;
  const _Placement(this.start, this.adjusted);
}
