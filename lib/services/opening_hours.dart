// ============================================================
// AndaMove — Opening Hours Parser
// File: lib/services/opening_hours.dart
//
// Turns the raw POI `openHours` strings used across AndaMove into
// a structured open/close window expressed in minutes-from-midnight,
// so the scheduler can enforce "don't visit a beach at 2 AM".
//
// FORMATS SEEN IN THE REAL DATA (screen5_home.dart):
//   "Open 24 hours"
//   "8:00 AM - 7:30 PM"
//   "7:00 AM - 5:00 PM"
//   "9:00 AM - 5:00 PM"
//   "11:30 AM - 10:00 PM"
//   "5:30 PM - 11:30 PM"
//   "6:00 PM - Late"           ← nightlife, open-ended
//   "9:00 PM - Late"           ← nightlife, open-ended
//   "Sun 4:00 PM - 10:00 PM"   ← day-prefixed (weekly market)
//   "10:30 AM - 10:00 PM"
//   ""                          ← missing → treated as always-open
//
// DESIGN CHOICES
//   • "Late" / open-ended → close set to 2:00 AM (1560 min) so
//     nightlife can legitimately run past midnight. The scheduler's
//     nightlife branch governs the rest.
//   • A leading weekday token ("Sun", "Mon", …) is stripped; we
//     schedule by time-of-day, not weekday (the app's trips are
//     single dates and the data only ever prefixes one day).
//   • Unparseable / empty → isAlwaysOpen = true (fail open, never
//     silently drop a POI).
//   • Close earlier than open (e.g. 5:30 PM - 1:00 AM) → close is
//     treated as next-day and returned as >1440.
// ============================================================

class OpeningHours {
  /// True when the place is effectively open all day (24h, or we
  /// couldn't parse a window and chose to fail open).
  final bool isAlwaysOpen;

  /// Minutes from midnight. Null when [isAlwaysOpen] is true or no
  /// window could be derived.
  final int? openMinutes;

  /// Minutes from midnight. May exceed 1440 when the venue closes
  /// after midnight (e.g. 2:00 AM → 1560).
  final int? closeMinutes;

  const OpeningHours._({
    required this.isAlwaysOpen,
    this.openMinutes,
    this.closeMinutes,
  });

  /// Always-open sentinel.
  static const OpeningHours alwaysOpen =
      OpeningHours._(isAlwaysOpen: true);

  /// True when we have a concrete open AND close.
  bool get hasWindow =>
      !isAlwaysOpen && openMinutes != null && closeMinutes != null;

  // Open-ended ("Late") venues get this synthetic close: 2:00 AM.
  static const int _lateCloseMinutes = 26 * 60; // 1560

  /// Parse a raw openHours string into a window.
  static OpeningHours parse(String? raw) {
    if (raw == null) return alwaysOpen;
    var s = raw.trim();
    if (s.isEmpty) return alwaysOpen;

    final lower = s.toLowerCase();

    // 24-hour places.
    if (lower.contains('24 hour') ||
        lower.contains('24 hours') ||
        lower.contains('24/7') ||
        lower == 'open') {
      return alwaysOpen;
    }

    // Strip a leading weekday token if present ("Sun 4:00 PM - …").
    s = _stripLeadingWeekday(s);

    // Split on the dash that separates open and close. Accept a few
    // dash variants and the word "to".
    final parts = _splitRange(s);
    if (parts == null) {
      // Couldn't find two halves → fail open rather than drop POI.
      return alwaysOpen;
    }

    final openStr = parts.$1.trim();
    final closeStr = parts.$2.trim();

    final open = _parseClock(openStr);

    // Open-ended close ("Late", "till late", "onwards", "—").
    final closeLower = closeStr.toLowerCase();
    final isLate = closeLower.contains('late') ||
        closeLower.contains('onward') ||
        closeLower.isEmpty;

    if (open == null) return alwaysOpen;

    int? close;
    if (isLate) {
      close = _lateCloseMinutes;
    } else {
      close = _parseClock(closeStr);
      if (close == null) return alwaysOpen;
      // Close before/equal open → it's a post-midnight close.
      if (close <= open) close += 24 * 60;
    }

    return OpeningHours._(
      isAlwaysOpen: false,
      openMinutes: open,
      closeMinutes: close,
    );
  }

  // ── Strip a leading weekday like "Sun", "Mon ", "Tuesday" ─────
  static String _stripLeadingWeekday(String s) {
    final m = RegExp(
      r'^\s*(mon|tue|wed|thu|fri|sat|sun)[a-z]*\.?\s+',
      caseSensitive: false,
    ).firstMatch(s);
    if (m != null) return s.substring(m.end);
    return s;
  }

  // ── Split "A - B" into (A, B). Handles -, –, —, "to". ─────────
  static (String, String)? _splitRange(String s) {
    // Normalise unicode dashes to a plain hyphen.
    final norm = s.replaceAll('–', '-').replaceAll('—', '-');

    // Prefer an explicit hyphen with surrounding spaces.
    int idx = norm.indexOf(' - ');
    if (idx != -1) {
      return (norm.substring(0, idx), norm.substring(idx + 3));
    }

    // " to " separator.
    final toIdx = norm.toLowerCase().indexOf(' to ');
    if (toIdx != -1) {
      return (norm.substring(0, toIdx), norm.substring(toIdx + 4));
    }

    // Bare hyphen anywhere (last resort; avoids splitting a time
    // like "9:00" because there's no hyphen there).
    idx = norm.indexOf('-');
    if (idx != -1) {
      return (norm.substring(0, idx), norm.substring(idx + 1));
    }

    return null;
  }

  // ── Parse a single clock token to minutes-from-midnight ───────
  // Accepts: "8:00 AM", "7 PM", "11:30 PM", "10:00 pm", "0:30 AM".
  static int? _parseClock(String token) {
    final t = token.trim().toLowerCase();
    if (t.isEmpty) return null;

    final m = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?')
        .firstMatch(t);
    if (m == null) return null;

    int hour = int.parse(m.group(1)!);
    final min = m.group(2) != null ? int.parse(m.group(2)!) : 0;
    final period = m.group(3); // am / pm / null

    if (hour < 0 || hour > 23) return null;
    if (min < 0 || min > 59) return null;

    if (period == 'am') {
      if (hour == 12) hour = 0; // 12 AM = midnight
    } else if (period == 'pm') {
      if (hour != 12) hour += 12; // 12 PM stays noon
    }
    // No period → assume the number is already 24h-ish; leave as is.

    return hour * 60 + min;
  }
}
