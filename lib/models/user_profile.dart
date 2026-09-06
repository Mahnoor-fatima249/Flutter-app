import 'clothing_item.dart';

class UserProfile {
  final String id;
  final String name;
  final String? avatarPath;
  final String? gender;
  final List<String> preferredColors;
  final List<ClothingCategory> preferredCategories;
  final List<OccasionType> commonOccasions;
  final String? stylePreference;
  final String? bodyType;
  final Map<String, dynamic>? styleDNA;

  UserProfile({
    required this.id,
    required this.name,
    this.avatarPath,
    this.gender,
    this.preferredColors = const [],
    this.preferredCategories = const [],
    this.commonOccasions = const [],
    this.stylePreference,
    this.bodyType,
    this.styleDNA,
  });

  UserProfile copyWith({
    String? name,
    String? avatarPath,
    String? gender,
    List<String>? preferredColors,
    List<ClothingCategory>? preferredCategories,
    List<OccasionType>? commonOccasions,
    String? stylePreference,
    String? bodyType,
    Map<String, dynamic>? styleDNA,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      gender: gender ?? this.gender,
      preferredColors: preferredColors ?? this.preferredColors,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      commonOccasions: commonOccasions ?? this.commonOccasions,
      stylePreference: stylePreference ?? this.stylePreference,
      bodyType: bodyType ?? this.bodyType,
      styleDNA: styleDNA ?? this.styleDNA,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarPath': avatarPath,
        'gender': gender,
        'preferredColors': preferredColors,
        'preferredCategories': preferredCategories.map((c) => c.index).toList(),
        'commonOccasions': commonOccasions.map((o) => o.index).toList(),
        'stylePreference': stylePreference,
        'bodyType': bodyType,
        'styleDNA': styleDNA,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        name: json['name'],
        avatarPath: json['avatarPath'],
        gender: json['gender'],
        preferredColors: List<String>.from(json['preferredColors'] ?? []),
        preferredCategories: (json['preferredCategories'] as List?)
                ?.map((c) => ClothingCategory.values[c])
                .toList() ??
            [],
        commonOccasions: (json['commonOccasions'] as List?)
                ?.map((o) => OccasionType.values[o])
                .toList() ??
            [],
        stylePreference: json['stylePreference'],
        bodyType: json['bodyType'],
        styleDNA: json['styleDNA'],
      );
}

class WeatherData {
  final double temperature;
  final double humidity;
  final String condition;
  final String icon;
  final double windSpeed;
  final String cityName;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.icon,
    required this.windSpeed,
    required this.cityName,
  });

  String get temperatureUnit => '${temperature.round()}°C';

  ClothingSeason get season {
    if (temperature > 30) return ClothingSeason.summer;
    if (temperature > 20) return ClothingSeason.spring;
    if (temperature > 10) return ClothingSeason.autumn;
    return ClothingSeason.winter;
  }

  bool get isRaining => condition.toLowerCase().contains('rain');
  bool get isSunny => condition.toLowerCase().contains('clear') || condition.toLowerCase().contains('sun');
  bool get isCold => temperature < 15;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'][0];
    final wind = json['wind'];
    return WeatherData(
      temperature: (main['temp'] as num).toDouble() - 273.15,
      humidity: (main['humidity'] as num).toDouble(),
      condition: weather['main'],
      icon: weather['icon'],
      windSpeed: (wind['speed'] as num).toDouble(),
      cityName: json['name'],
    );
  }
}

class StyleDNA {
  final Map<String, double> personalityTraits;
  final List<String> recommendedStyles;
  final List<String> colorPalette;
  final String styleProfile;

  StyleDNA({
    required this.personalityTraits,
    required this.recommendedStyles,
    required this.colorPalette,
    required this.styleProfile,
  });

  factory StyleDNA.fromJson(Map<String, dynamic> json) => StyleDNA(
        personalityTraits: Map<String, double>.from(json['personalityTraits'] ?? {}),
        recommendedStyles: List<String>.from(json['recommendedStyles'] ?? []),
        colorPalette: List<String>.from(json['colorPalette'] ?? []),
        styleProfile: json['styleProfile'] ?? '',
      );
}
