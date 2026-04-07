import 'package:cloud_firestore/cloud_firestore.dart';

class UpdatePoiCoordinates {
  static final _coordinates = {
    'kata_beach': (7.8206, 98.2985),
    'patong_beach': (7.8965, 98.2961),
    'freedom_beach': (7.8782, 98.2756),
    'surin_beach': (7.9756, 98.2780),
    'nai_harn_beach': (7.7679, 98.3046),
    'the_big_buddha': (7.8275, 98.3133),
    'wat_chalong': (7.8424, 98.3383),
    'phuket_elephant_sanctuary': (8.0157, 98.3887),
    'sirinat_national_park': (8.0931, 98.3070),
    'koh_sirey': (7.8698, 98.4186),
    'old_phuket_town': (7.8847, 98.3882),
    'phuket_fantasea': (7.9572, 98.2776),
    'rawai_seafood_market': (7.7716, 98.3283),
    'phuket_town_walking_street': (7.8843, 98.3863),
    'blue_elephant_restaurant': (7.8831, 98.3882),
    'tiger_kingdom': (7.9267, 98.3326),
    'atv_and_zipline': (7.9355, 98.3405),
    'phi_phi_islands_day_trip': (7.8562, 98.3917),
    'bangla_road': (7.8933, 98.2984),
    'illuzion_club': (7.8923, 98.2978),
    'thalang_national_museum': (8.0217, 98.3258),
    'promthep_cape': (7.7580, 98.3053),
    'karon_viewpoint': (7.8138, 98.2990),
    'phuket_aquarium': (7.8100, 98.3994),
    'jungceylon': (7.8928, 98.2997),
    'central_festival_phuket': (7.8768, 98.3802),
  };

  static Future<void> run() async {
    for (final entry in _coordinates.entries) {
      final docId = entry.key;
      final (lat, lng) = entry.value;
      await FirebaseFirestore.instance.collection('pois').doc(docId).update({
        'latitude': lat,
        'longitude': lng,
      });
    }
  }
}
