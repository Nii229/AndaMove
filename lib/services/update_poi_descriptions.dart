import 'package:cloud_firestore/cloud_firestore.dart';

class UpdatePoiDescriptions {
  static Future<void> run() async {
    final db = FirebaseFirestore.instance;
    final descriptions = {
      'kata_beach': 'Kata Beach is giving soft-life paradise energy from the very first step. The sea glows in shades of blue that look almost unreal. Waves roll in with that perfect chill rhythm, making it a dreamy spot for swimming, sunbathing, surfing, or just staring dramatically into the horizon. By sunset, the whole beach turns golden and romantic.',
      'patong_beach': 'Patong Beach is the loud, iconic, extra queen of Phuket. This is where beach life meets full-on energy, with jet skis slicing across the water, music floating through the air, and crowds vibing from morning until night. The sand is warm, the sea is sparkling, and there is always something happening.',
      'freedom_beach': 'Freedom Beach feels like a secret whispered by the island itself. Hidden away from the louder parts of Phuket, this beach is pure paradise energy. The water is insanely clear, the sand is soft like powdered sugar, and the whole place feels untouched in the best possible way.',
      'surin_beach': 'Surin Beach is classy, calm, and effortlessly pretty. The shoreline curves beautifully, the sand feels silky, and the sea shines with an elegant blue. It is less chaotic than the busier beaches, which makes everything feel more refined and more cinematic.',
      'nai_harn_beach': 'Nai Harn Beach feels like a peaceful little dream wrapped between green hills and glowing blue water. It has that perfect balance of beauty and calm. Unlike crowded party beaches, Nai Harn gives soft, serene vibes. Families, swimmers, and sunset lovers all fit here naturally.',
      'the_big_buddha': 'The Big Buddha is not just a landmark — it is a whole moment. Sitting high above Phuket, this giant white statue feels calm, majestic, and almost otherworldly. The marble shines beautifully under the sun, and the view from the hilltop is honestly insane — ocean, hills, coastline, sky, everything all at once.',
      'wat_chalong': 'Wat Chalong is like stepping into a golden dream where every detail glows with meaning. The temple is stunning — elegant roofs, intricate patterns, and rich colors that shimmer under the Phuket sun. Walking through the grounds feels calm, respectful, and quietly magical.',
      'phuket_elephant_sanctuary': 'Phuket Elephant Sanctuary is pure soft-heart energy. This is where elephants are allowed to simply be elephants — walking freely, bathing, playing, and living peacefully. Watching them move so gently through nature feels emotional in the best way.',
      'sirinat_national_park': 'Sirinat National Park feels like Phuket\'s wild, untouched side showing off. It is a dreamy mix of beach, forest, mangroves, and open sky, all blending into one giant natural mood board. The air feels fresher here, the crowds disappear, and everything slows down.',
      'koh_sirey': 'Koh Sirey is one of those underrated little gems that quietly steals your heart. This small island near Phuket Town has sleepy coastal vibes, local life, peaceful sea views, and a soft beauty that feels deeply authentic.',
      'old_phuket_town': 'Old Phuket Town is a full-on aesthetic. Colorful Sino-Portuguese buildings line the streets like the island decided to serve architecture, culture, and charm all at once. Every corner feels photogenic, every café looks like it belongs on your mood board.',
      'phuket_fantasea': 'Phuket FantaSea is absolutely extra — in the best way possible. It is bright, theatrical, oversized, and fully committed to giving fantasy kingdom energy. The show is dramatic, colorful, and packed with wow moments.',
      'rawai_seafood_market': 'Rawai Seafood Market is a paradise for food lovers. The whole place buzzes with salty air, sizzling flavors, and the delicious chaos of fresh catches being picked out right in front of you. Giant prawns, crabs, shellfish, and fish all seem to say, choose me!',
      'phuket_town_walking_street': 'Phuket Town Walking Street is giving full weekend fever dream energy. As the sun goes down, the street transforms into a glowing maze of food stalls, lights, music, art, handmade goodies, and people everywhere just vibing.',
      'blue_elephant_restaurant': 'Blue Elephant Restaurant is elegant drama in culinary form. Housed in a beautiful heritage mansion, the place already feels iconic before the food even arrives. Every bite feels rich with Thai tradition, presented with style and grace.',
      'tiger_kingdom': 'Tiger Kingdom is one of Phuket\'s most talked-about spots. Seeing these huge, powerful animals up close feels surreal. Their beauty is intense — striped, majestic, and lowkey intimidating in a very real way.',
      'atv_and_zipline': 'An ATV and zipline tour is basically Phuket saying, okay, now let\'s add chaos. One minute you are roaring through muddy jungle trails, and the next you are flying over treetops with your heart somewhere between your chest and the clouds.',
      'phi_phi_islands_day_trip': 'Phi Phi Island is unfairly beautiful. The cliffs rise dramatically out of the sea, the water glows in impossible shades of turquoise, and every angle looks like it belongs on the cover of a luxury travel magazine.',
      'bangla_road': 'Bangla Road is absolute nightlife chaos — neon, noise, music, lights, crowds, and zero intention of going to bed early. The street comes alive after dark like someone flipped a switch and activated party mode for the entire city.',
      'illuzion_club': 'Illuzion Club is where the night goes full superstar mode. Massive lights, giant stage energy, booming music, and a crowd that came to have an actual moment. The atmosphere is sleek and intense.',
      'thalang_national_museum': 'Thalang National Museum feels like opening a hidden chapter of Phuket\'s soul. Inside, stories of the island\'s past unfold through old artifacts, cultural displays, and historical pieces that give everything deeper meaning.',
      'promthep_cape': 'Promthep Cape is sunset royalty. Perched at the southern tip of Phuket, the cape opens up to endless sea views, dramatic cliffs, and a sky that slowly melts into shades of gold, orange, pink, and fire.',
      'karon_viewpoint': 'Karon Viewpoint is the definition of "this view ate." From up high, you get this stunning sweep of coastline where the beaches curve like ribbons of gold beside glowing blue water.',
      'phuket_aquarium': 'Phuket Aquarium is a soft, underwater little world where the ocean gets to show its quieter magic. Glowing tanks and drifting sea creatures create this calm, dreamy atmosphere.',
      'jungceylon': 'Jungceylon is where beach holiday meets shopping spree. This mall is lively, modern, and packed with everything from fashion and beauty to snacks, souvenirs, and entertainment.',
      'central_festival_phuket': 'Central Festival Phuket feels polished, spacious, and a little bit dangerous for your wallet. It is sleek, stylish, and packed with modern mall energy where everything looks clean, tempting, and slightly luxurious.',
    };

    for (final entry in descriptions.entries) {
      await db.collection('pois').doc(entry.key).update({
        'longDescription': entry.value,
      });
    }
  }
}
