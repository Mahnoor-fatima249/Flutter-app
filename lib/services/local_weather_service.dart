import 'dart:math';
import '../models/user_profile.dart';

class LocalWeatherService {
  final Random _random = Random();

  final Map<String, Map<String, dynamic>> _cityWeather = {
    'lahore': {'baseTemp': 35, 'baseHumidity': 65, 'baseWind': 8},
    'karachi': {'baseTemp': 32, 'baseHumidity': 75, 'baseWind': 12},
    'islamabad': {'baseTemp': 30, 'baseHumidity': 55, 'baseWind': 6},
    'mumbai': {'baseTemp': 31, 'baseHumidity': 80, 'baseWind': 10},
    'delhi': {'baseTemp': 33, 'baseHumidity': 60, 'baseWind': 8},
    'dubai': {'baseTemp': 38, 'baseHumidity': 50, 'baseWind': 15},
    'london': {'baseTemp': 15, 'baseHumidity': 70, 'baseWind': 14},
    'new york': {'baseTemp': 18, 'baseHumidity': 65, 'baseWind': 12},
    'paris': {'baseTemp': 16, 'baseHumidity': 68, 'baseWind': 10},
    'tokyo': {'baseTemp': 20, 'baseHumidity': 60, 'baseWind': 8},
    'sydney': {'baseTemp': 22, 'baseHumidity': 65, 'baseWind': 11},
    'default': {'baseTemp': 25, 'baseHumidity': 60, 'baseWind': 10},
  };

  final List<String> _conditions = [
    'Clear', 'Clouds', 'Rain', 'Thunderstorm', 'Snow', 'Mist', 'Fog', 'Drizzle'
  ];

  final Map<String, String> _conditionIcons = {
    'Clear': '01d',
    'Clouds': '03d',
    'Rain': '10d',
    'Thunderstorm': '11d',
    'Snow': '13d',
    'Mist': '50d',
    'Fog': '50d',
    'Drizzle': '09d',
  };

  WeatherData _generateWeather(String city) {
    final cityLower = city.toLowerCase();
    final baseData = _cityWeather[cityLower] ?? _cityWeather['default']!;

    final month = DateTime.now().month;
    double seasonalAdjustment = 0;
    if (month >= 4 && month <= 9) {
      seasonalAdjustment = 10;
    } else if (month >= 10 && month <= 11) {
      seasonalAdjustment = -5;
    } else {
      seasonalAdjustment = -15;
    }

    final tempVariation = _random.nextDouble() * 6 - 3;
    final temperature = (baseData['baseTemp'] + seasonalAdjustment + tempVariation).toDouble();

    final humidityVariation = _random.nextDouble() * 20 - 10;
    final humidity = (baseData['baseHumidity'] + humidityVariation).clamp(30, 95).toDouble();

    final windVariation = _random.nextDouble() * 8 - 4;
    final windSpeed = (baseData['baseWind'] + windVariation).clamp(0, 30).toDouble();

    String condition;
    if (temperature > 30 && humidity > 70) {
      condition = _random.nextBool() ? 'Thunderstorm' : 'Clear';
    } else if (temperature < 0) {
      condition = 'Snow';
    } else if (humidity > 80) {
      condition = _random.nextBool() ? 'Rain' : 'Clouds';
    } else if (humidity > 60) {
      condition = _random.nextBool() ? 'Clouds' : 'Mist';
    } else {
      condition = 'Clear';
    }

    return WeatherData(
      temperature: temperature,
      humidity: humidity,
      condition: condition,
      icon: _conditionIcons[condition] ?? '01d',
      windSpeed: windSpeed,
      cityName: city,
    );
  }

  Future<WeatherData> getWeather(double latitude, double longitude) async {
    await Future.delayed(const Duration(milliseconds: 300));

    String city = 'default';
    if (latitude > 24 && latitude < 37 && longitude > 60 && longitude < 80) {
      city = 'lahore';
    } else if (latitude > 50 && latitude < 60 && longitude > -2 && longitude < 3) {
      city = 'london';
    } else if (latitude > 40 && latitude < 42 && longitude > -75 && longitude < -73) {
      city = 'new york';
    }

    return _generateWeather(city);
  }

  Future<WeatherData> getWeatherByCity(String city) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _generateWeather(city);
  }

  Future<Map<String, dynamic>> getForecast(double latitude, double longitude) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final forecasts = <Map<String, dynamic>>[];
    for (int i = 0; i < 5; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final tempVariation = _random.nextDouble() * 10 - 5;
      forecasts.add({
        'dt': date.millisecondsSinceEpoch ~/ 1000,
        'main': {
          'temp': 25 + tempVariation,
          'humidity': 60 + _random.nextDouble() * 20,
        },
        'weather': [
          {
            'main': _conditions[_random.nextInt(_conditions.length)],
            'description': 'scattered clouds',
            'icon': '03d',
          }
        ],
      });
    }

    return {
      'list': forecasts,
      'city': {'name': 'Local'},
    };
  }

  String getWeatherAdvice(WeatherData weather) {
    if (weather.isRaining) {
      return 'Baarish ho rahi hai! Waterproof jacket aur closed shoes pehnein.';
    }
    if (weather.temperature > 35) {
      return 'Bahut garam hai! Light colors aur breathable fabrics ka use karein.';
    }
    if (weather.temperature < 5) {
      return 'Thand bahut hai! Layers mein kapde pehnein, warm jacket zaroori hai.';
    }
    if (weather.windSpeed > 20) {
      return 'Tez hawa hai! Loose kapde avoid karein.';
    }
    if (weather.isSunny) {
      return 'Dhoop hai! Sunglasses aur light clothing best rahegi.';
    }
    return 'Mausam theek hai. Zyada tar outfits aaj kaam karenge.';
  }
}
