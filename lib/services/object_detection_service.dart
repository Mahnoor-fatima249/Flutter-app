import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ObjectDetectionService {
  static const platform = MethodChannel('com.stylist/object_detection');
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await platform.invokeMethod('initialize');
      _isInitialized = true;
    } catch (e) {
      print('Error initializing TFLite: $e');
      _isInitialized = false;
    }
  }

  Future<Map<String, dynamic>> detectClothing(File imageFile) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Could not decode image');
      }

      final resized = img.copyResize(image, width: 224, height: 224);
      final inputBytes = _imageToByteList(resized);

      final result = await platform.invokeMethod('detect', {
        'input': inputBytes,
        'width': 224,
        'height': 224,
      });

      return _parseDetectionResult(result);
    } catch (e) {
      return _fallbackDetection(imageFile);
    }
  }

  Future<Map<String, dynamic>> _fallbackDetection(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      return {
        'category': 'tops',
        'primaryColor': 'unknown',
        'colors': ['unknown'],
        'colorPalette': <Map<String, dynamic>>[],
        'confidence': 0.5,
        'isClothing': true,
      };
    }

    final avgColor = _getAverageColor(image);
    final colorName = _getColorName(avgColor);
    final colorPalette = _extractColorPalette(image);
    final brightness = _getBrightness(image);
    final edgeDensity = _getEdgeDensity(image);
    final saturation = _getSaturation(avgColor);
    final colorVariance = _getColorVariance(image);
    final category = _guessCategoryAdvanced(image, avgColor, brightness, edgeDensity, saturation, colorVariance);
    final fabric = _guessFabric(image, brightness, edgeDensity, saturation, colorVariance);
    final fit = _guessFit(category, brightness);
    final season = _guessSeason(colorName, brightness);
    final occasion = _guessOccasion(colorName, category, brightness);
    final styleTips = _getStyleTips(colorName, category, brightness, saturation);

    return {
      'category': category,
      'primaryColor': colorName,
      'colors': [colorName, ...colorPalette.skip(1).map((e) => e['color'])],
      'colorPalette': colorPalette,
      'confidence': 0.75,
      'isClothing': true,
      'fabric': fabric,
      'fit': fit,
      'season': season,
      'occasion': occasion,
      'brightness': brightness,
      'saturation': saturation,
      'styleTips': styleTips,
    };
  }

  double _getBrightness(img.Image image) {
    int totalBrightness = 0;
    final sampleStep = max(1, (image.width * image.height / 5000).ceil());
    int count = 0;
    for (int y = 0; y < image.height; y += sampleStep) {
      for (int x = 0; x < image.width; x += sampleStep) {
        final pixel = image.getPixel(x, y);
        totalBrightness += ((pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114)).toInt();
        count++;
      }
    }
    return (totalBrightness / count / 255 * 100).roundToDouble();
  }

  double _getSaturation(List<int> rgb) {
    final r = rgb[0] / 255;
    final g = rgb[1] / 255;
    final b = rgb[2] / 255;
    final maxVal = [r, g, b].reduce(max);
    final minVal = [r, g, b].reduce(min);
    if (maxVal == 0) return 0;
    return ((maxVal - minVal) / maxVal * 100).roundToDouble();
  }

  double _getEdgeDensity(img.Image image) {
    int edges = 0;
    final sampleStep = max(1, (image.width / 50).ceil());
    for (int y = sampleStep; y < image.height - sampleStep; y += sampleStep) {
      for (int x = sampleStep; x < image.width - sampleStep; x += sampleStep) {
        final p = image.getPixel(x, y);
        final pr = image.getPixel(x + sampleStep, y);
        final pb = image.getPixel(x, y + sampleStep);
        final gx = (p.r - pr.r).abs() + (p.g - pr.g).abs() + (p.b - pr.b).abs();
        final gy = (p.r - pb.r).abs() + (p.g - pb.g).abs() + (p.b - pb.b).abs();
        if (gx + gy > 80) edges++;
      }
    }
    final total = ((image.width / sampleStep) * (image.height / sampleStep)).toInt();
    return (edges / total * 100).roundToDouble();
  }

  double _getColorVariance(img.Image image) {
    int rSum = 0, gSum = 0, bSum = 0;
    final sampleStep = max(1, (image.width * image.height / 3000).ceil());
    final samples = <List<int>>[];
    for (int y = 0; y < image.height; y += sampleStep) {
      for (int x = 0; x < image.width; x += sampleStep) {
        final pixel = image.getPixel(x, y);
        samples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
      }
    }
    if (samples.isEmpty) return 0;
    for (final s in samples) { rSum += s[0]; gSum += s[1]; bSum += s[2]; }
    final rAvg = rSum / samples.length;
    final gAvg = gSum / samples.length;
    final bAvg = bSum / samples.length;
    double variance = 0;
    for (final s in samples) {
      variance += pow(s[0] - rAvg, 2) + pow(s[1] - gAvg, 2) + pow(s[2] - bAvg, 2);
    }
    return (sqrt(variance / samples.length) * 100 / 255).roundToDouble().clamp(0, 100);
  }

  String _guessCategoryAdvanced(img.Image image, List<int> avgColor, double brightness, double edgeDensity, double saturation, double colorVariance) {
    final r = avgColor[0];
    final g = avgColor[1];
    final b = avgColor[2];

    if (b > 100 && b > r && brightness < 50 && brightness > 20 && edgeDensity > 15) return 'bottoms';
    if (brightness > 65 && saturation < 25 && edgeDensity < 12) return 'tops';
    if (saturation > 25 && brightness > 35 && brightness < 75 && colorVariance < 30) return 'tops';
    if (brightness < 35 && edgeDensity > 20) return 'outerwear';
    if (brightness > 50 && saturation > 40 && edgeDensity < 15) return 'dress';
    if (brightness < 40) return 'bottoms';
    if (brightness > 85 || brightness < 10) return 'accessories';
    if (g > r && g > b) return 'outerwear';
    if (r > 180 && g < 100) return 'dress';
    if (colorVariance > 40) return 'outerwear';
    return 'tops';
  }

  String _guessFabric(img.Image image, double brightness, double edgeDensity, double saturation, double colorVariance) {
    if (brightness < 45 && edgeDensity > 18) return 'Denim';
    if (brightness > 65 && edgeDensity < 10 && saturation > 30) return 'Silk/Satin';
    if (brightness < 35 && edgeDensity > 15 && saturation < 20) return 'Leather';
    if (brightness > 40 && brightness < 70 && edgeDensity > 8 && edgeDensity < 25) return 'Cotton';
    if (brightness < 55 && edgeDensity > 20) return 'Wool';
    if (brightness > 60 && edgeDensity > 10 && edgeDensity < 20) return 'Linen';
    if (edgeDensity < 8) return 'Polyester';
    if (brightness < 30 && saturation < 15) return 'Velvet';
    if (brightness > 75 && edgeDensity < 5) return 'Chiffon';
    return 'Cotton';
  }

  String _guessFit(String category, double brightness) {
    if (category == 'dress') return brightness > 60 ? 'A-Line' : 'Bodycon';
    if (category == 'bottoms') return brightness < 40 ? 'Slim Fit' : 'Regular Fit';
    if (category == 'outerwear') return 'Regular Fit';
    if (category == 'tops') return brightness > 65 ? 'Slim Fit' : 'Regular Fit';
    return 'Regular Fit';
  }

  String _guessSeason(String color, double brightness) {
    final darkColors = ['black', 'navy', 'maroon', 'dark green', 'dark blue'];
    final lightColors = ['white', 'beige', 'cream', 'light blue', 'pink', 'lavender'];
    final warmColors = ['red', 'orange', 'yellow', 'rust', 'mustard', 'coral'];
    final coolColors = ['blue', 'navy', 'grey', 'light blue', 'mint', 'lavender'];

    if (darkColors.contains(color)) return 'Fall/Winter';
    if (lightColors.contains(color)) return 'Spring/Summer';
    if (warmColors.contains(color)) return brightness > 50 ? 'Spring' : 'Fall';
    if (coolColors.contains(color)) return brightness > 50 ? 'Summer' : 'Winter';
    if (brightness > 60) return 'Spring/Summer';
    if (brightness < 40) return 'Fall/Winter';
    return 'All Season';
  }

  String _guessOccasion(String color, String category, double brightness) {
    final formalColors = ['black', 'navy', 'white', 'grey', 'beige'];
    final casualColors = ['blue', 'red', 'green', 'yellow', 'pink', 'orange'];

    if (formalColors.contains(color) && brightness < 70) {
      if (category == 'tops' || category == 'dress') return 'Formal/Business';
    }
    if (category == 'outerwear') return brightness < 40 ? 'Casual/Outdoor' : 'Smart Casual';
    if (casualColors.contains(color)) return 'Casual';
    if (brightness > 70) return 'Casual/Day Wear';
    return 'Casual';
  }

  List<String> _getStyleTips(String color, String category, double brightness, double saturation) {
    final tips = <String>[];

    if (category == 'tops') {
      if (brightness > 65) tips.add('Light color top - dark bottoms ke saath best lagega');
      if (brightness < 40) tips.add('Dark top - bright accessories se pop aayega');
      if (saturation > 50) tips.add('Bold color - baaki neutral rakho');
    }
    if (category == 'bottoms') {
      if (brightness < 40) tips.add('Dark bottoms - har type ke top ke saath jaata hai');
      if (brightness > 60) tips.add('Light bottoms - darker top pehno');
    }
    if (category == 'dress') {
      if (saturation > 40) tips.add('Statement piece - minimal accessories best hain');
      if (brightness > 60) tips.add('Light dress - daytime events ke liye perfect');
    }
    if (category == 'outerwear') {
      tips.add('Contrasting colors ke upar layer karo depth ke liye');
    }

    if (color == 'black') tips.add('Timeless hai - accessories mein pop of color do');
    if (color == 'white') tips.add('Fresh aur clean lagta hai - bold jewelry pehno');
    if (color == 'red') tips.add('Eye-catching hai - makeup subtle rakho');

    if (tips.isEmpty) tips.add('Versatile piece hai - freely mix and match karo');
    return tips;
  }

  Uint8List _imageToByteList(img.Image image) {
    final bytes = Uint8List(1 * 224 * 224 * 3);
    int index = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = image.getPixel(x, y);
        bytes[index++] = pixel.r.toInt();
        bytes[index++] = pixel.g.toInt();
        bytes[index++] = pixel.b.toInt();
      }
    }
    return bytes;
  }

  Map<String, dynamic> _parseDetectionResult(dynamic result) {
    if (result == null) {
      return {
        'category': 'tops',
        'primaryColor': 'unknown',
        'colors': ['unknown'],
        'confidence': 0.5,
        'isClothing': false,
      };
    }

    final map = Map<String, dynamic>.from(result);
    return {
      'category': map['category'] ?? 'tops',
      'primaryColor': map['primaryColor'] ?? 'unknown',
      'colors': List<String>.from(map['colors'] ?? ['unknown']),
      'confidence': map['confidence'] ?? 0.5,
      'isClothing': map['isClothing'] ?? false,
    };
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

  String _getColorName(List<int> rgb) {
    final r = rgb[0];
    final g = rgb[1];
    final b = rgb[2];

    if (r > 220 && g > 220 && b > 220) return 'white';
    if (r > 200 && g > 190 && b > 170 && r < 240 && g < 230) return 'cream';
    if (r > 190 && g > 180 && b > 160) return 'beige';
    if (r > 200 && g > 190 && b > 200) return 'ivory';
    if (r < 30 && g < 30 && b < 30) return 'black';
    if (r < 60 && g < 60 && b < 60) return 'charcoal';
    if (r < 80 && g < 80 && b < 80) return 'dark grey';
    if (r > 180 && g < 80 && b < 80) return 'red';
    if (r > 140 && g < 60 && b < 80) return 'burgundy';
    if (r > 200 && g < 100 && b < 100) return 'crimson';
    if (r > 160 && g < 80 && b > 80) return 'maroon';
    if (b > 150 && r < 80 && g < 120) return 'navy';
    if (b > 180 && r < 100 && g > 100) return 'royal blue';
    if (b > 150 && r > 100 && g > 100) return 'light blue';
    if (b > 120 && r < 80 && g > 100) return 'teal';
    if (b > 160 && g > 160 && r < 100) return 'sky blue';
    if (g > 150 && r < 80 && b < 80) return 'green';
    if (g > 130 && r > 80 && b < 80) return 'olive';
    if (g > 150 && b > 100 && r < 80) return 'forest green';
    if (g > 180 && r > 120 && b < 80) return 'lime';
    if (g > 150 && r > 100 && b > 100) return 'sage';
    if (r > 200 && g > 200 && b < 80) return 'yellow';
    if (r > 200 && g > 170 && b < 60) return 'mustard';
    if (r > 180 && g > 140 && b < 80) return 'gold';
    if (r > 200 && g > 100 && b < 60) return 'orange';
    if (r > 180 && g > 80 && b < 60) return 'rust';
    if (r > 200 && g > 140 && b < 80) return 'peach';
    if (r > 200 && g > 120 && b < 80) return 'coral';
    if (r > 200 && g > 140 && b > 160) return 'pink';
    if (r > 220 && g > 170 && b > 190) return 'blush';
    if (r > 180 && g > 100 && b > 120) return 'rose';
    if (r > 120 && g < 80 && b > 150) return 'purple';
    if (r > 150 && g < 100 && b > 160) return 'lavender';
    if (r > 100 && g < 60 && b > 120) return 'plum';
    if (r > 120 && g > 70 && b > 40 && r > g && g > b) return 'brown';
    if (r > 150 && g > 100 && b > 60) return 'tan';
    if (r > 130 && g > 80 && b > 50) return 'camel';
    if (r > 120 && r < 200 && (r - g).abs() < 20 && (g - b).abs() < 20) return 'grey';
    if (r > 160 && g > 160 && b > 170) return 'silver';
    if (r > g && r > b) return r > 150 ? 'salmon' : 'brown';
    if (g > r && g > b) return 'green';
    if (b > r && b > g) return 'blue';
    return 'neutral';
  }

  List<Map<String, dynamic>> _extractColorPalette(img.Image image) {
    final colorRegions = <String, int>{};
    final sampleStep = (image.width * image.height / 1000).ceil().clamp(1, 10);
    
    for (int y = 0; y < image.height; y += sampleStep) {
      for (int x = 0; x < image.width; x += sampleStep) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final colorName = _getColorName([r, g, b]);
        colorRegions[colorName] = (colorRegions[colorName] ?? 0) + 1;
      }
    }
    
    final totalSamples = colorRegions.values.fold(0, (sum, count) => sum + count);
    final sorted = colorRegions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final palette = <Map<String, dynamic>>[];
    for (final entry in sorted.take(6)) {
      final percentage = (entry.value / totalSamples * 100).round();
      if (percentage >= 3) {
        palette.add({
          'color': entry.key,
          'percentage': percentage,
          'rgb': _getColorRgb(entry.key),
        });
      }
    }
    
    return palette;
  }

  List<int> _getColorRgb(String colorName) {
    switch (colorName) {
      case 'white': return [255, 255, 255];
      case 'black': return [0, 0, 0];
      case 'red': return [220, 50, 50];
      case 'blue': return [50, 100, 200];
      case 'yellow': return [230, 200, 50];
      case 'purple': return [150, 50, 180];
      case 'green': return [50, 180, 50];
      case 'orange': return [230, 130, 50];
      case 'brown': return [150, 100, 50];
      case 'grey': return [150, 150, 150];
      case 'pink': return [230, 150, 170];
      case 'beige': return [200, 180, 150];
      case 'navy': return [30, 50, 100];
      case 'maroon': return [128, 0, 0];
      case 'olive': return [128, 128, 0];
      case 'teal': return [0, 128, 128];
      case 'coral': return [255, 127, 80];
      case 'lavender': return [230, 230, 250];
      case 'mustard': return [255, 219, 88];
      case 'rust': return [183, 65, 14];
      case 'burgundy': return [128, 0, 32];
      case 'camel': return [193, 154, 107];
      case 'tan': return [210, 180, 140];
      case 'cream': return [255, 253, 208];
      case 'charcoal': return [54, 69, 79];
      case 'silver': return [192, 192, 192];
      case 'ivory': return [255, 255, 240];
      case 'blush': return [222, 93, 131];
      case 'rose': return [255, 0, 127];
      case 'sage': return [188, 184, 138];
      case 'plum': return [142, 69, 133];
      case 'sky blue': return [135, 206, 235];
      case 'royal blue': return [65, 105, 225];
      case 'light blue': return [173, 216, 230];
      case 'forest green': return [34, 139, 34];
      case 'lime': return [50, 205, 50];
      case 'peach': return [255, 218, 185];
      case 'salmon': return [250, 128, 114];
      case 'dark grey': return [64, 64, 64];
      default: return [128, 128, 128];
    }
  }

  void dispose() {
    _isInitialized = false;
  }
}
