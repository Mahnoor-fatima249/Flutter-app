import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../models/user_profile.dart';

class LocalAIService extends ChangeNotifier {
  final Random _random = Random();

  Future<Map<String, dynamic>> analyzeClothingImage(dynamic imageSource) async {
    try {
      Uint8List bytes;
      if (imageSource is File) {
        bytes = await imageSource.readAsBytes();
      } else if (imageSource is Uint8List) {
        bytes = imageSource;
      } else {
        throw Exception('Invalid image source type');
      }

      final image = img.decodeImage(bytes);
      if (image == null) {
        return _getDefaultResult();
      }

      final resized = img.copyResize(image, width: 100, height: 100);
      final avgColor = _getAverageColor(resized);
      final brightness = _getBrightness(avgColor);
      final colorVariance = _getColorVariance(resized);

      final colorName = _getColorName(avgColor);
      final allColors = _extractDominantColors(resized);
      final category = _guessCategory(avgColor, brightness, colorVariance);
      final material = _guessMaterial(category, brightness);
      final seasons = _guessSeasons(category, colorName, brightness);
      final occasions = _guessOccasions(category, material, brightness);
      final styleLevel = _guessStyleLevel(category, material, colorName);
      final name = _generateName(category, colorName, material);

      return {
        'category': category,
        'primaryColor': colorName,
        'colors': allColors,
        'material': material,
        'styleLevel': styleLevel,
        'seasons': seasons,
        'occasions': occasions,
        'name': name,
        'confidence': _calculateConfidence(colorVariance, brightness),
      };
    } catch (e) {
      return _getDefaultResult();
    }
  }

  List<int> _getAverageColor(img.Image image) {
    int r = 0, g = 0, b = 0;
    final totalPixels = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        r += pixel.r.toInt();
        g += pixel.g.toInt();
        b += pixel.b.toInt();
      }
    }

    return [r ~/ totalPixels, g ~/ totalPixels, b ~/ totalPixels];
  }

  double _getBrightness(List<int> rgb) {
    return (rgb[0] * 0.299 + rgb[1] * 0.587 + rgb[2] * 0.114) / 255;
  }

  double _getColorVariance(img.Image image) {
    final avgColor = _getAverageColor(image);
    double variance = 0;
    final totalPixels = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        variance += pow(pixel.r.toInt() - avgColor[0], 2);
        variance += pow(pixel.g.toInt() - avgColor[1], 2);
        variance += pow(pixel.b.toInt() - avgColor[2], 2);
      }
    }

    return variance / (totalPixels * 3);
  }

  String _getColorName(List<int> rgb) {
    final r = rgb[0];
    final g = rgb[1];
    final b = rgb[2];

    if (r > 220 && g > 220 && b > 220) return 'white';
    if (r < 40 && g < 40 && b < 40) return 'black';
    if (r > 180 && g < 80 && b < 80) return 'red';
    if (r < 80 && g < 80 && b > 180) return 'blue';
    if (r > 180 && g > 180 && b < 80) return 'yellow';
    if (r > 180 && g < 80 && b > 130) return 'purple';
    if (r < 80 && g > 180 && b < 80) return 'green';
    if (r > 220 && g > 160 && b < 80) return 'orange';
    if (r > 180 && g > 120 && b < 80) return 'brown';
    if (r > 160 && g > 160 && b > 160) return 'grey';
    if (r > 200 && g > 150 && b > 170) return 'pink';
    if (r > 100 && g > 60 && b < 50) return 'maroon';
    if (r < 50 && g < 50 && b > 100) return 'navy';
    if (r > 150 && g > 200 && b > 150) return 'mint';
    if (r > 200 && g > 180 && b > 150) return 'beige';
    if (r > 150 && g > 100 && b > 80) return 'rust';
    if (r > 100 && g > 150 && b > 180) return 'sky blue';
    if (r > 180 && g > 150 && b > 180) return 'lavender';
    if (r > 150 && g > 180 && b > 150) return 'sage';
    if (r > 180 && g > 150 && b > 120) return 'tan';
    if (r > 120 && g > 80 && b > 60) return 'chocolate';

    return 'beige';
  }

  List<String> _extractDominantColors(img.Image image) {
    final colorBuckets = <String, int>{};
    final step = max(1, image.width ~/ 20);

    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final colorName = _getColorName([
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt()
        ]);
        colorBuckets[colorName] = (colorBuckets[colorName] ?? 0) + 1;
      }
    }

    final sorted = colorBuckets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = <String>[];
    for (final entry in sorted) {
      if (!colors.contains(entry.key)) {
        colors.add(entry.key);
      }
      if (colors.length >= 4) break;
    }

    return colors.isEmpty ? ['beige'] : colors;
  }

  String _guessCategory(List<int> avgColor, double brightness, double variance) {
    final r = avgColor[0];
    final g = avgColor[1];
    final b = avgColor[2];

    if (brightness > 0.85) {
      return _random.nextBool() ? 'accessories' : 'tops';
    }
    if (brightness < 0.2) {
      return _random.nextBool() ? 'bottoms' : 'outerwear';
    }
    if (variance < 500) {
      return 'tops';
    }
    if (variance > 2000) {
      return _random.nextBool() ? 'dresses' : 'outerwear';
    }
    if (b > r && b > g) {
      return 'bottoms';
    }
    if (g > r && g > b) {
      return _random.nextBool() ? 'outerwear' : 'activewear';
    }
    if (r > 150 && g > 100 && b < 80) {
      return _random.nextBool() ? 'footwear' : 'accessories';
    }

    return 'tops';
  }

  String _guessMaterial(String category, double brightness) {
    final materials = {
      'tops': ['cotton', 'polyester', 'linen', 'silk', 'jersey'],
      'bottoms': ['denim', 'cotton', 'chino', 'polyester', 'wool'],
      'outerwear': ['nylon', 'leather', 'wool', 'cotton', 'fleece'],
      'dresses': ['silk', 'cotton', 'chiffon', 'lace', 'satin'],
      'footwear': ['leather', 'canvas', 'rubber', 'suede', 'mesh'],
      'accessories': ['leather', 'metal', 'fabric', 'plastic', 'wool'],
      'activewear': ['polyester', 'nylon', 'spandex', 'mesh', 'microfiber'],
      'formal': ['silk', 'wool', 'cotton', 'satin', 'tweed'],
    };

    final categoryMaterials = materials[category] ?? ['cotton'];
    return categoryMaterials[_random.nextInt(categoryMaterials.length)];
  }

  List<ClothingSeason> _guessSeasons(String category, String color, double brightness) {
    final seasons = <ClothingSeason>[];

    if (brightness > 0.7) {
      seasons.add(ClothingSeason.summer);
    }
    if (brightness < 0.4) {
      seasons.add(ClothingSeason.winter);
    }
    if (category == 'outerwear') {
      seasons.add(ClothingSeason.winter);
      seasons.add(ClothingSeason.autumn);
    }
    if (category == 'activewear') {
      seasons.addAll(ClothingSeason.values);
    }
    if (color == 'white' || color == 'mint' || color == 'sky blue') {
      seasons.add(ClothingSeason.spring);
    }
    if (color == 'brown' || color == 'rust' || color == 'maroon') {
      seasons.add(ClothingSeason.autumn);
    }

    if (seasons.isEmpty) {
      seasons.addAll([ClothingSeason.spring, ClothingSeason.summer]);
    }

    return seasons.toSet().toList();
  }

  List<OccasionType> _guessOccasions(String category, String material, double brightness) {
    final occasions = <OccasionType>[];

    occasions.add(OccasionType.casual);

    if (material == 'silk' || material == 'satin' || material == 'lace') {
      occasions.add(OccasionType.formal);
      occasions.add(OccasionType.party);
    }
    if (category == 'activewear') {
      occasions.add(OccasionType.sporty);
      occasions.add(OccasionType.outdoor);
    }
    if (category == 'formal') {
      occasions.add(OccasionType.formal);
      occasions.add(OccasionType.work);
    }
    if (brightness > 0.6 && brightness < 0.8) {
      occasions.add(OccasionType.date);
    }
    if (category == 'outerwear') {
      occasions.add(OccasionType.outdoor);
    }

    return occasions.toSet().toList();
  }

  String _guessStyleLevel(String category, String material, String color) {
    if (material == 'silk' || material == 'satin' || material == 'leather') {
      return 'formal';
    }
    if (category == 'activewear') {
      return 'sporty';
    }
    if (color == 'black' || color == 'navy' || color == 'grey') {
      return 'semi-formal';
    }
    return 'casual';
  }

  String _generateName(String category, String color, String material) {
    final prefixes = ['Classic', 'Modern', 'Essential', 'Premium', 'Casual'];
    final prefix = prefixes[_random.nextInt(prefixes.length)];
    return '$prefix ${color.capitalize} ${material.capitalize} ${category.capitalize}';
  }

  double _calculateConfidence(double variance, double brightness) {
    double confidence = 0.7;
    if (variance > 500 && variance < 3000) confidence += 0.1;
    if (brightness > 0.2 && brightness < 0.9) confidence += 0.05;
    confidence += _random.nextDouble() * 0.1;
    return confidence.clamp(0.5, 0.95);
  }

  Map<String, dynamic> _getDefaultResult() {
    return {
      'category': 'tops',
      'primaryColor': 'beige',
      'colors': ['beige'],
      'material': 'cotton',
      'styleLevel': 'casual',
      'seasons': ['spring', 'summer'],
      'occasions': ['casual'],
      'name': 'Casual Cotton Top',
      'confidence': 0.6,
    };
  }

  Future<List<Outfit>> suggestOutfits({
    required List<ClothingItem> wardrobe,
    required WeatherData weather,
    required OccasionType occasion,
    int count = 5,
    UserProfile? profile,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (wardrobe.isEmpty) return [];

    final outfits = <Outfit>[];
    final tops = wardrobe.where((i) => i.category == ClothingCategory.tops).toList();
    final bottoms = wardrobe.where((i) => i.category == ClothingCategory.bottoms).toList();
    final outerwear = wardrobe.where((i) => i.category == ClothingCategory.outerwear).toList();
    final dresses = wardrobe.where((i) => i.category == ClothingCategory.dresses).toList();
    final footwear = wardrobe.where((i) => i.category == ClothingCategory.footwear).toList();
    final accessories = wardrobe.where((i) => i.category == ClothingCategory.accessories).toList();

    if (tops.isNotEmpty && bottoms.isNotEmpty) {
      for (int i = 0; i < min(count, tops.length); i++) {
        final top = tops[_random.nextInt(tops.length)];
        final bottom = bottoms[_random.nextInt(bottoms.length)];
        final items = [top, bottom];

        if (outerwear.isNotEmpty && weather.isCold) {
          items.add(outerwear[_random.nextInt(outerwear.length)]);
        }
        if (footwear.isNotEmpty) {
          items.add(footwear[_random.nextInt(footwear.length)]);
        }
        if (accessories.isNotEmpty && _random.nextBool()) {
          items.add(accessories[_random.nextInt(accessories.length)]);
        }

        final outfitName = _generateOutfitName(occasion, weather);
        final reason = _generateOutfitReason(items, weather, occasion);
        final score = _calculateOutfitScore(items, occasion, weather);

        outfits.add(Outfit(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: outfitName,
          items: items,
          occasion: occasion,
          season: weather.season,
          aiScore: score,
          aiReason: reason,
        ));
      }
    }

    if (outfits.isEmpty && dresses.isNotEmpty) {
      for (int i = 0; i < min(count, dresses.length); i++) {
        final dress = dresses[_random.nextInt(dresses.length)];
        final items = [dress];

        if (outerwear.isNotEmpty && weather.isCold) {
          items.add(outerwear[_random.nextInt(outerwear.length)]);
        }
        if (footwear.isNotEmpty) {
          items.add(footwear[_random.nextInt(footwear.length)]);
        }

        final dressScore = _calculateOutfitScore(items, occasion, weather);

        outfits.add(Outfit(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: _generateOutfitName(occasion, weather),
          items: items,
          occasion: occasion,
          season: weather.season,
          aiScore: dressScore,
          aiReason: _generateOutfitReason(items, weather, occasion),
        ));
      }
    }

    outfits.shuffle(_random);
    return outfits.take(count).toList();
  }

  double _calculateOutfitScore(List<ClothingItem> items, OccasionType occasion, WeatherData weather) {
    double score = 0.5;

    final colors = items.map((i) => i.primaryColor.toLowerCase()).toSet().toList();
    if (colors.length >= 2) {
      int pairMatches = 0;
      int totalPairs = 0;
      for (int i = 0; i < colors.length; i++) {
        for (int j = i + 1; j < colors.length; j++) {
          totalPairs++;
          final s = _getColorMatchScore(colors[i], colors[j]);
          if (s >= 75) pairMatches += 2;
          else if (s >= 55) pairMatches += 1;
        }
      }
      if (totalPairs > 0) {
        score += (pairMatches / (totalPairs * 2)) * 0.25;
      }
    } else if (colors.length == 1) {
      score += 0.1;
    }

    int occasionMatches = 0;
    for (final item in items) {
      if (item.occasions.contains(occasion)) occasionMatches++;
    }
    score += (occasionMatches / items.length) * 0.15;

    int seasonMatches = 0;
    for (final item in items) {
      if (item.seasons.contains(weather.season) || item.seasons.contains(ClothingSeason.allSeason)) {
        seasonMatches++;
      }
    }
    score += (seasonMatches / items.length) * 0.1;

    final uniqueCategories = items.map((i) => i.category).toSet();
    if (uniqueCategories.length >= 2) {
      score += 0.05;
    }

    return score.clamp(0.5, 0.95);
  }

  int _getColorMatchScore(String color1, String color2) {
    final perfectMatches = {
      'black': ['white', 'red', 'gold', 'silver'],
      'white': ['black', 'navy', 'red'],
      'navy': ['white', 'cream', 'pink', 'beige'],
      'beige': ['navy', 'brown', 'black'],
      'brown': ['cream', 'beige', 'white'],
      'grey': ['pink', 'white', 'black'],
      'grey': ['pink', 'white', 'black'],
      'mint': ['navy', 'white', 'brown'],
      'rust': ['navy', 'cream', 'grey'],
    };

    final goodMatches = {
      'black': ['grey', 'beige', 'maroon', 'pink', 'purple'],
      'white': ['grey', 'beige', 'blush'],
      'navy': ['grey', 'tan', 'rust'],
      'blue': ['white', 'grey', 'tan', 'coral'],
      'red': ['grey', 'black', 'white', 'navy'],
      'green': ['white', 'cream', 'tan', 'brown'],
      'grey': ['white', 'black', 'blue', 'red', 'pink'],
      'brown': ['white', 'beige', 'blue', 'green'],
      'beige': ['black', 'white', 'brown', 'red'],
      'pink': ['grey', 'navy', 'white', 'black'],
      'purple': ['white', 'grey', 'beige'],
      'maroon': ['white', 'grey', 'beige', 'cream'],
    };

    final c1 = color1.toLowerCase();
    final c2 = color2.toLowerCase();

    if (c1 == c2) return 30;
    if (perfectMatches[c1]?.contains(c2) == true) return 95;
    if (perfectMatches[c2]?.contains(c1) == true) return 95;
    if (goodMatches[c1]?.contains(c2) == true) return 75;
    if (goodMatches[c2]?.contains(c1) == true) return 75;

    final neutrals = ['black', 'white', 'grey', 'beige', 'cream', 'navy'];
    if (neutrals.contains(c1) && neutrals.contains(c2)) return 65;
    if (neutrals.contains(c1) || neutrals.contains(c2)) return 55;

    return 35;
  }

  String _generateOutfitName(OccasionType occasion, WeatherData weather) {
    final weatherAdj = weather.isCold ? 'Cozy' : weather.isSunny ? 'Bright' : 'Perfect';
    final occasionNames = {
      OccasionType.casual: 'Casual',
      OccasionType.formal: 'Professional',
      OccasionType.sporty: 'Active',
      OccasionType.party: 'Party-Ready',
      OccasionType.work: 'Work-Ready',
      OccasionType.date: 'Date Night',
      OccasionType.outdoor: 'Outdoor',
    };
    return '$weatherAdj ${occasionNames[occasion] ?? 'Stylish'} Look';
  }

  String _generateOutfitReason(List<ClothingItem> items, WeatherData weather, OccasionType occasion) {
    final reasons = <String>[];

    if (weather.isCold) {
      reasons.add('Perfect for cold weather at ${weather.temperature.round()}°C');
    } else if (weather.isSunny) {
      reasons.add('Great for sunny weather at ${weather.temperature.round()}°C');
    } else {
      reasons.add('Comfortable for ${weather.temperature.round()}°C weather');
    }

    final colors = items.map((i) => i.primaryColor).toSet().toList();
    if (colors.length == 1) {
      reasons.add('Monochromatic ${colors.first} look');
    } else if (colors.length <= 3) {
      reasons.add('Well-coordinated color palette');
    }

    if (occasion == OccasionType.formal || occasion == OccasionType.work) {
      reasons.add('Professional and polished appearance');
    } else if (occasion == OccasionType.casual) {
      reasons.add('Relaxed yet put-together style');
    }

    return reasons.join('. ');
  }

  Future<Map<String, dynamic>> generateStyleDNA(List<ClothingItem> wardrobe) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (wardrobe.isEmpty) {
      return _getDefaultStyleDNA();
    }

    final colorCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    final occasionCounts = <String, int>{};
    final seasonCounts = <String, int>{};

    for (final item in wardrobe) {
      colorCounts[item.primaryColor] = (colorCounts[item.primaryColor] ?? 0) + 1;
      categoryCounts[item.category.name] = (categoryCounts[item.category.name] ?? 0) + 1;
      for (final occasion in item.occasions) {
        occasionCounts[occasion.name] = (occasionCounts[occasion.name] ?? 0) + 1;
      }
      for (final season in item.seasons) {
        seasonCounts[season.name] = (seasonCounts[season.name] ?? 0) + 1;
      }
    }

    final sortedColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topColors = sortedColors.take(5).map((e) => e.key).toList();

    final totalItems = wardrobe.length;
    final occasionPercentages = <String, int>{};
    for (final entry in occasionCounts.entries) {
      occasionPercentages[entry.key] = ((entry.value / totalItems) * 100).round();
    }

    final seasonPercentages = <String, int>{};
    for (final entry in seasonCounts.entries) {
      seasonPercentages[entry.key] = ((entry.value / totalItems) * 100).round();
    }

    final traits = _calculatePersonalityTraits(wardrobe);
    final stylePersonality = _determineStylePersonality(traits);
    final strengths = _identifyStrengths(wardrobe, colorCounts, categoryCounts);
    final improvements = _identifyImprovements(wardrobe, colorCounts, categoryCounts);
    final recommendedStyles = _getRecommendedStyles(traits, occasionPercentages);

    return {
      'colorPalette': topColors,
      'stylePersonality': stylePersonality,
      'personalityTraits': traits,
      'occasions': occasionPercentages,
      'seasons': seasonPercentages,
      'strengths': strengths,
      'improvements': improvements,
      'recommendedStyles': recommendedStyles,
    };
  }

  Map<String, double> _calculatePersonalityTraits(List<ClothingItem> wardrobe) {
    int formalCount = 0;
    int casualCount = 0;
    int sportyCount = 0;
    int trendyCount = 0;
    int classicCount = 0;
    int bohemianCount = 0;

    for (final item in wardrobe) {
      for (final occasion in item.occasions) {
        if (occasion == OccasionType.formal || occasion == OccasionType.work) {
          formalCount++;
          classicCount++;
        }
        if (occasion == OccasionType.casual) casualCount++;
        if (occasion == OccasionType.sporty) sportyCount++;
        if (occasion == OccasionType.party) trendyCount++;
        if (occasion == OccasionType.date) {
          bohemianCount++;
          trendyCount++;
        }
      }
    }

    final total = (formalCount + casualCount + sportyCount + trendyCount + classicCount + bohemianCount).toDouble();
    if (total == 0) {
      return {
        'classic': 0.5,
        'minimalist': 0.5,
        'bohemian': 0.3,
        'trendy': 0.4,
        'sporty': 0.3,
        'formal': 0.5,
      };
    }

    return {
      'classic': (classicCount / total).clamp(0.0, 1.0),
      'minimalist': (1.0 - (trendyCount / total)).clamp(0.0, 1.0),
      'bohemian': (bohemianCount / total).clamp(0.0, 1.0),
      'trendy': (trendyCount / total).clamp(0.0, 1.0),
      'sporty': (sportyCount / total).clamp(0.0, 1.0),
      'formal': (formalCount / total).clamp(0.0, 1.0),
    };
  }

  String _determineStylePersonality(Map<String, double> traits) {
    final sorted = traits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.first.key;
    final styles = {
      'classic': 'Classic Sophisticate',
      'minimalist': 'Minimalist Maven',
      'bohemian': 'Free Spirit',
      'trendy': 'Trendsetter',
      'sporty': 'Athletic Enthusiast',
      'formal': 'Polished Professional',
    };

    return styles[top] ?? 'Versatile Stylist';
  }

  List<String> _identifyStrengths(
    List<ClothingItem> wardrobe,
    Map<String, int> colorCounts,
    Map<String, int> categoryCounts,
  ) {
    final strengths = <String>[];

    if (colorCounts.length >= 5) {
      strengths.add('Excellent color variety in wardrobe');
    }
    if (categoryCounts.length >= 4) {
      strengths.add('Well-rounded wardrobe categories');
    }
    if (wardrobe.length >= 20) {
      strengths.add('Strong wardrobe foundation');
    }
    if (wardrobe.any((i) => i.isFavorite)) {
      strengths.add('Clear favorites for go-to looks');
    }

    final formalCount = categoryCounts['formal'] ?? 0;
    if (formalCount >= 3) {
      strengths.add('Good formal wear collection');
    }

    if (strengths.isEmpty) {
      strengths.add('Building a diverse wardrobe');
    }

    return strengths;
  }

  List<String> _identifyImprovements(
    List<ClothingItem> wardrobe,
    Map<String, int> colorCounts,
    Map<String, int> categoryCounts,
  ) {
    final improvements = <String>[];

    if (colorCounts.length < 3) {
      improvements.add('Add more color variety');
    }
    if (categoryCounts.length < 3) {
      improvements.add('Expand wardrobe categories');
    }
    if ((categoryCounts['accessories'] ?? 0) < 2) {
      improvements.add('Add more accessories');
    }
    if ((categoryCounts['outerwear'] ?? 0) < 2) {
      improvements.add('Consider more outerwear options');
    }
    if (wardrobe.length < 15) {
      improvements.add('Build a larger wardrobe collection');
    }

    if (improvements.isEmpty) {
      improvements.add('Your wardrobe is well-balanced!');
    }

    return improvements;
  }

  List<String> _getRecommendedStyles(
    Map<String, double> traits,
    Map<String, int> occasions,
  ) {
    final styles = <String>[];

    if ((traits['formal'] ?? 0) > 0.5) {
      styles.add('Business Casual');
    }
    if ((traits['casual'] ?? 0) > 0.3) {
      styles.add('Smart Casual');
    }
    if ((traits['sporty'] ?? 0) > 0.3) {
      styles.add('Athleisure');
    }
    if ((traits['trendy'] ?? 0) > 0.3) {
      styles.add('Street Style');
    }
    if ((traits['classic'] ?? 0) > 0.5) {
      styles.add('Timeless Elegance');
    }

    if (styles.isEmpty) {
      styles.addAll(['Smart Casual', 'Versatile Mix']);
    }

    return styles;
  }

  Map<String, dynamic> _getDefaultStyleDNA() {
    return {
      'colorPalette': ['black', 'white', 'navy', 'grey', 'beige'],
      'stylePersonality': 'Versatile Stylist',
      'personalityTraits': {
        'classic': 0.5,
        'minimalist': 0.6,
        'bohemian': 0.3,
        'trendy': 0.4,
        'sporty': 0.3,
        'formal': 0.5,
      },
      'occasions': {'casual': 40, 'formal': 25, 'sporty': 15, 'party': 10, 'work': 10},
      'seasons': {'summer': 30, 'winter': 25, 'spring': 25, 'autumn': 20},
      'strengths': ['Building a diverse wardrobe', 'Good neutral base'],
      'improvements': ['Add more accessories', 'Expand color palette', 'Add more outerwear'],
      'recommendedStyles': ['Smart Casual', 'Business Casual'],
    };
  }

  Future<Map<String, dynamic>> getCareInstructions(String itemName, String material) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final materialLower = material.toLowerCase();

    final careDatabase = {
      'cotton': {
        'washing': 'Machine wash cold with like colors. Use gentle cycle.',
        'drying': 'Tumble dry low or hang to dry. Remove promptly.',
        'ironing': 'Iron on medium to high heat while slightly damp.',
        'storage': 'Fold neatly or hang on padded hangers.',
        'tips': [
          'Pre-treat stains before washing',
          'Wash inside out to preserve color',
          'Avoid bleach on colored items',
          'Use fabric softener for softness',
        ],
        'frequency': 'Wash after every 2-3 wears',
      },
      'denim': {
        'washing': 'Machine wash cold inside out. Wash with like colors.',
        'drying': 'Hang to dry or tumble dry low.',
        'ironing': 'Iron on medium heat if needed.',
        'storage': 'Fold or hang by the waistband.',
        'tips': [
          'Wash less frequently to preserve color',
          'Turn inside out before washing',
          'Use cold water to prevent shrinking',
          'Spot clean when possible',
        ],
        'frequency': 'Wash after 5-10 wears',
      },
      'silk': {
        'washing': 'Hand wash in cold water or dry clean only.',
        'drying': 'Lay flat on towel to dry. Avoid direct sunlight.',
        'ironing': 'Iron on low heat inside out. Use pressing cloth.',
        'storage': 'Hang on padded hangers in cool, dry place.',
        'tips': [
          'Avoid perfume and deodorant contact',
          'Treat stains immediately',
          'Use silk-specific detergent',
          'Never wring or twist',
        ],
        'frequency': 'Dry clean after 3-5 wears',
      },
      'wool': {
        'washing': 'Hand wash in cold water or dry clean.',
        'drying': 'Lay flat to dry. Reshape while damp.',
        'ironing': 'Steam instead of ironing. Use low heat if needed.',
        'storage': 'Fold and store flat. Use cedar blocks.',
        'tips': [
          'Use wool-specific detergent',
          'Avoid hanging to prevent stretching',
          'Store with moth repellent',
          'Brush regularly to remove lint',
        ],
        'frequency': 'Wash after 5-10 wears',
      },
      'polyester': {
        'washing': 'Machine wash warm with like colors.',
        'drying': 'Tumble dry low. Quick dry fabric.',
        'ironing': 'Low heat iron or steamer. Wrinkle-resistant.',
        'storage': 'Fold or hang. Takes minimal care.',
        'tips': [
          'Avoid high heat to prevent melting',
          'Use fabric softener to reduce static',
          'Wash with similar fabrics',
          'Remove from dryer promptly',
        ],
        'frequency': 'Wash after 3-5 wears',
      },
      'nylon': {
        'washing': 'Machine wash cold or warm.',
        'drying': 'Hang to dry or tumble dry low.',
        'ironing': 'Low heat iron if needed. Often wrinkle-free.',
        'storage': 'Fold or hang. Very low maintenance.',
        'tips': [
          'Avoid high heat',
          'Use mesh laundry bag for delicate items',
          'Store away from direct sunlight',
          'Clean stains promptly',
        ],
        'frequency': 'Wash after 3-5 wears',
      },
      'leather': {
        'washing': 'Wipe with damp cloth. Professional cleaning recommended.',
        'drying': 'Air dry at room temperature away from heat.',
        'ironing': 'Never iron. Use leather conditioner instead.',
        'storage': 'Hang on broad hangers in cool, dry place.',
        'tips': [
          'Apply leather conditioner regularly',
          'Protect from rain and moisture',
          'Store in breathable garment bag',
          'Use leather protector spray',
        ],
        'frequency': 'Clean as needed. Condition monthly.',
      },
      'linen': {
        'washing': 'Machine wash cold or warm. Gentle cycle.',
        'drying': 'Hang to dry or tumble dry low.',
        'ironing': 'Iron on high heat while damp for best results.',
        'storage': 'Fold neatly or hang on padded hangers.',
        'tips': [
          'Embrace natural wrinkles for casual look',
          'Wash before first wear to soften',
          'Use starch for crisp appearance',
          'Store in dry place to prevent mildew',
        ],
        'frequency': 'Wash after every 2-3 wears',
      },
      'spandex': {
        'washing': 'Machine wash cold. Use gentle cycle.',
        'drying': 'Hang to dry. Avoid tumble dryer.',
        'ironing': 'Never iron. Use low heat steamer if needed.',
        'storage': 'Fold and store flat. Avoid hanging.',
        'tips': [
          'Avoid bleach and fabric softener',
          'Wash with like colors',
          'Avoid sitting on rough surfaces',
          'Rotate with other garments',
        ],
        'frequency': 'Wash after each wear',
      },
    };

    final careInfo = careDatabase[materialLower];

    if (careInfo != null) {
      return careInfo;
    }

    return {
      'washing': 'Follow care label instructions. When in doubt, hand wash cold.',
      'drying': 'Air dry or tumble dry on low heat.',
      'ironing': 'Iron on medium heat. Test on hidden area first.',
      'storage': 'Store in cool, dry place. Fold or hang as appropriate.',
      'tips': [
        'Always check care label first',
        'Test cleaning products on hidden area',
        'Store in breathable garment bags',
        'Address stains promptly',
      ],
      'frequency': 'Wash as needed based on wear',
    };
  }
}

extension StringCapitalize on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
