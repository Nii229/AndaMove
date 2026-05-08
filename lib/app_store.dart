// ============================================================
// AndaMove — App Store
// File: lib/app_store.dart
//
// Simple static singleton — no external packages needed.
// Works alongside local setState by letting each screen
// register a VoidCallback listener. When any screen mutates
// store data it calls _notify(), which triggers setState on
// every registered listener.
//
// Screens that need to react to store changes:
//   initState  → AppStore.addListener(_onStoreUpdate)
//   dispose    → AppStore.removeListener(_onStoreUpdate)
//   _onStoreUpdate() → setState(() {})
//
// UPDATED: Added adminCreatedPois list + publishPoi() so
//   POIs created in the admin panel appear in screen5_home.
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════
// SAVED VLOG SUMMARY
// ══════════════════════════════════════════════════════════════
class SavedVlogSummary {
  final String id;
  final String title;
  final String location;
  final String creatorName;
  final String creatorInitials;
  final Color creatorAvatarColor;
  final String totalDuration;
  final int stopCount;
  final List<String> tags;
  final List<Color> thumbColors;
  final int storyIndex;

  const SavedVlogSummary({
    required this.id,
    required this.title,
    required this.location,
    required this.creatorName,
    required this.creatorInitials,
    required this.creatorAvatarColor,
    required this.totalDuration,
    required this.stopCount,
    required this.tags,
    required this.thumbColors,
    required this.storyIndex,
  });
}

// ══════════════════════════════════════════════════════════════
// SAVED POI SUMMARY
// ══════════════════════════════════════════════════════════════
class SavedPoiSummary {
  final String name;
  final String location;
  final String category;
  final double rating;
  final String description;
  final String openHours;
  final String estimatedTime;
  final String priceRange;
  final List<Color> gradientColors;
  final IconData icon;
  final String tagLabel;
  final Color tagBg;
  final Color tagFg;
  final String imagePath;
  final String longDescription;

  const SavedPoiSummary({
    required this.name,
    required this.location,
    required this.category,
    required this.rating,
    required this.description,
    required this.openHours,
    required this.estimatedTime,
    required this.priceRange,
    required this.gradientColors,
    required this.icon,
    required this.tagLabel,
    required this.tagBg,
    required this.tagFg,
    this.imagePath = '',
    this.longDescription = '',
  });
}

// ══════════════════════════════════════════════════════════════
// STORED TRIP STOP
// ══════════════════════════════════════════════════════════════
class StoredTripStop {
  final String name;
  final String type;
  final String duration;
  final String distance;

  const StoredTripStop({
    required this.name,
    required this.type,
    required this.duration,
    required this.distance,
  });
}

// ══════════════════════════════════════════════════════════════
// STORED TRIP
// ══════════════════════════════════════════════════════════════
class StoredTrip {
  final String id;
  final String name;
  final String totalDuration;
  final List<StoredTripStop> stops;

  /// ID of the source StoryVlog, used to avoid duplicate follows.
  final String sourceVlogId;

  /// The date the user chose on screen7. Used by screen11 to
  /// determine trip status: today → inProgress, future → upcoming,
  /// past → completed. Null for trips added from Explore (drafts).
  final DateTime? tripDate;

  /// Transport label chosen on screen7 (e.g. 'Scooter', 'Car').
  final String transport;

  /// Start time chosen on screen7.
  final int startHour;
  final int startMinute;

  /// Index of the stop the user last navigated to (persisted via AppStore.setTripProgress).
  final int currentStopIndex;

  const StoredTrip({
    required this.id,
    required this.name,
    required this.totalDuration,
    required this.stops,
    required this.sourceVlogId,
    this.tripDate,
    this.transport = 'Walk',
    this.startHour = 9,
    this.startMinute = 0,
    this.currentStopIndex = 0,
  });
}

// ══════════════════════════════════════════════════════════════
// APP STORE — static singleton
// ══════════════════════════════════════════════════════════════
class AppStore {
  AppStore._(); // prevent instantiation

  // ── Trip status tracking ───────────────────────────────────
  /// IDs of trips that have been completed (inProgress → completed).
  static final Set<String> completedTripIds = {};

  /// Called by screen8/screen10 when user ends a trip.
  static void completeTrip(String tripId) {
    if (tripId.isEmpty) return;
    completedTripIds.add(tripId);
    inProgressTripIds.remove(tripId);
    _notify();
  }

  /// IDs of trips that have been started (upcoming → inProgress).
  static final Set<String> inProgressTripIds = {};

  /// Called by screen8 when user taps "Start Trip" on an upcoming trip.
  static void startTrip(String id) {
    if (id.isEmpty) return;
    inProgressTripIds.add(id);
    completedTripIds.remove(id);
    _notify();
  }

  // ── Trip progress (stop index per trip) ───────────────────
  static final Map<String, int> tripProgress = {};

  static void setTripProgress(String tripId, int stopIndex) {
    tripProgress[tripId] = stopIndex;
    _notify();
  }

  static int getTripProgress(String tripId) => tripProgress[tripId] ?? 0;

  // ── Mutable lists ──────────────────────────────────────────
  static final List<SavedVlogSummary> savedVlogs = [];
  static final List<SavedPoiSummary> savedPois = [];
  static final List<StoredTrip> followedTrips = [];

  // ══════════════════════════════════════════════════════════
  // ADMIN-CREATED POIs
  // POIs published from the admin Create POI screen.
  // screen5_home merges these with the hardcoded 25-POI list
  // so they appear instantly in the tourist app.
  //
  // NOTE: Admin-created POIs also write to Firestore via
  //   adminScreen3_createPOI._handlePublish(). This list
  //   provides immediate local visibility before Firestore
  //   refresh — both sources are correct.
  // ══════════════════════════════════════════════════════════
  static final List<SavedPoiSummary> adminCreatedPois = [];

  /// Called by adminScreen3_createPOI when admin taps Publish.
  static void publishPoi(SavedPoiSummary poi) {
    // Prevent duplicates by name
    if (adminCreatedPois.any((p) => p.name == poi.name)) return;
    adminCreatedPois.add(poi);
    _notify();
  }

  /// Check if a POI name exists in the admin-created list.
  static bool isAdminPoi(String name) =>
      adminCreatedPois.any((p) => p.name == name);

  // ══════════════════════════════════════════════════════════
  // ADMIN POI MANAGEMENT
  // Real-time hide / show / delete / approve for all POIs.
  // Works with both the hardcoded 25 + admin-created POIs.
  //
  // screen5_home should filter: skip hidden & deleted POIs.
  // adminScreen2_managePOI reads these to show correct status.
  //
  // NOTE: Firestore status updates are performed directly in
  //   adminScreen2_managePOI._actions() alongside these
  //   in-memory updates for immediate UI feedback.
  // ══════════════════════════════════════════════════════════

  /// Names of POIs currently hidden from tourists.
  static final Set<String> hiddenPois = {};

  /// Names of POIs that have been deleted by admin.
  static final Set<String> deletedPois = {};

  /// Names of POIs pending review (starts with some defaults,
  /// admin can approve to remove from this set).
  static final Set<String> reviewPois = {};

  /// Hide a POI — tourists won't see it, admin sees "Hidden" status.
  static void hidePoi(String name) {
    hiddenPois.add(name);
    _notify();
  }

  /// Show (unhide) a POI — makes it visible to tourists again.
  static void showPoi(String name) {
    hiddenPois.remove(name);
    _notify();
  }

  /// Delete a POI — removes from both admin and tourist views.
  static void deletePoi(String name) {
    deletedPois.add(name);
    hiddenPois.remove(name);
    reviewPois.remove(name);
    // Also remove from admin-created list if it was created by admin
    adminCreatedPois.removeWhere((p) => p.name == name);
    _notify();
  }

  /// Mark a POI as needing review.
  static void flagForReview(String name) {
    reviewPois.add(name);
    _notify();
  }

  /// Approve a POI — removes from review, makes fully active.
  static void approvePoi(String name) {
    reviewPois.remove(name);
    hiddenPois.remove(name);
    _notify();
  }

  /// Reject a POI — deletes it.
  static void rejectPoi(String name) {
    deletePoi(name);
  }

  /// Check if a POI is visible to tourists (not hidden, not deleted).
  static bool isPoiVisible(String name) =>
      !hiddenPois.contains(name) && !deletedPois.contains(name);

  // ── Listener registry ──────────────────────────────────────
  static final List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback cb) {
    if (!_listeners.contains(cb)) _listeners.add(cb);
  }

  static void removeListener(VoidCallback cb) => _listeners.remove(cb);

  static void _notify() {
    for (final cb in List<VoidCallback>.from(_listeners)) {
      cb();
    }
  }

  // ══════════════════════════════════════════════════════════
  // VLOGS
  // ══════════════════════════════════════════════════════════
  static bool isVlogSaved(String id) => savedVlogs.any((v) => v.id == id);

  static void toggleVlog(SavedVlogSummary vlog) {
    if (isVlogSaved(vlog.id)) {
      savedVlogs.removeWhere((v) => v.id == vlog.id);
    } else {
      savedVlogs.add(vlog);
    }
    _notify();
    _syncVlogToFirestore(vlog.id, isVlogSaved(vlog.id));
  }

  static void _syncVlogToFirestore(String vlogId, bool isSaved) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedVlogs')
          .doc(vlogId);
      if (isSaved) {
        ref.set({'savedAt': FieldValue.serverTimestamp()});
      } else {
        ref.delete();
      }
    } catch (_) {}
  }

  static void _syncPoiToFirestore(String poiName, bool isSaved) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final docId = poiName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedPois')
          .doc(docId);
      if (isSaved) {
        ref.set({'name': poiName, 'savedAt': FieldValue.serverTimestamp()});
      } else {
        ref.delete();
      }
    } catch (_) {}
  }

  static Future<void> loadSavedVlogsFromFirestore(
      List<SavedVlogSummary> allVlogs) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedVlogs')
          .get();
      final savedIds = snap.docs.map((d) => d.id).toSet();
      final existing = savedVlogs.where((v) => !savedIds.contains(v.id)).toList();
      final fromFirestore = allVlogs.where((v) => savedIds.contains(v.id)).toList();
      savedVlogs
        ..clear()
        ..addAll([...fromFirestore, ...existing]);
      _notify();
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════
  // ACTIVITY LOG
  // ══════════════════════════════════════════════════════════
  /// Writes a single entry to the activityLogs Firestore collection.
  /// Fire-and-forget — never throws, never blocks UI.
  static void logActivity({
    required String category,
    required String title,
    required String sub,
  }) {
    try {
      FirebaseFirestore.instance.collection('activityLogs').add({
        'category': category,
        'title': title,
        'sub': sub,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════
  // POIS
  // ══════════════════════════════════════════════════════════
  static bool isPoiSaved(String name) => savedPois.any((p) => p.name == name);

  static void togglePoi(SavedPoiSummary poi) {
    if (isPoiSaved(poi.name)) {
      savedPois.removeWhere((p) => p.name == poi.name);
    } else {
      savedPois.add(poi);
    }
    _notify();
    _syncPoiToFirestore(poi.name, isPoiSaved(poi.name));
  }

  // ══════════════════════════════════════════════════════════
  // FOLLOWED TRIPS
  // ══════════════════════════════════════════════════════════
  static bool isTripFollowed(String vlogId) =>
      followedTrips.any((t) => t.sourceVlogId == vlogId);

  static void followTrip(StoredTrip trip) {
    if (!isTripFollowed(trip.sourceVlogId)) {
      followedTrips.add(trip);
      _notify();
    }
  }

  // ── Added POIs per trip (from screen6 "Add to Existing") ────
  static final Map<String, List<String>> _addedPoisByTrip = {};

  static void addPoiToTrip(String tripId, String poiName) {
    _addedPoisByTrip.putIfAbsent(tripId, () => []).add(poiName);
    _notify();
  }

  static List<String> getAddedPoisForTrip(String tripId) {
    return List.unmodifiable(_addedPoisByTrip[tripId] ?? []);
  }
}
