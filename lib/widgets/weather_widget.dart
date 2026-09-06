import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class WeatherWidget extends StatelessWidget {
  final WeatherData weather;
  final String? advice;
  final VoidCallback? onTap;

  const WeatherWidget({
    super.key,
    required this.weather,
    this.advice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _getWeatherGradient(),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getWeatherColor().withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildMainInfo(),
            if (advice != null) ...[
              const SizedBox(height: 16),
              _buildAdvice(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weather.cityName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              weather.condition,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        _buildWeatherIcon(),
      ],
    );
  }

  Widget _buildWeatherIcon() {
    IconData icon;
    switch (weather.condition.toLowerCase()) {
      case 'clear':
        icon = Icons.wb_sunny;
        break;
      case 'clouds':
        icon = Icons.cloud;
        break;
      case 'rain':
        icon = Icons.beach_access;
        break;
      case 'drizzle':
        icon = Icons.grain;
        break;
      case 'thunderstorm':
        icon = Icons.flash_on;
        break;
      case 'snow':
        icon = Icons.ac_unit;
        break;
      case 'mist':
      case 'fog':
        icon = Icons.foggy;
        break;
      default:
        icon = Icons.wb_cloudy;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 32,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMainInfo() {
    return Row(
      children: [
        CircularPercentIndicator(
          radius: 40,
          lineWidth: 6,
          percent: (weather.temperature / 50).clamp(0, 1),
          center: Text(
            weather.temperatureUnit,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          progressColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.2),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              _buildInfoRow(Icons.water_drop, 'Humidity', '${weather.humidity.round()}%'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.air, 'Wind', '${weather.windSpeed.round()} km/h'),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildSeasonBadge(),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.thermostat, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            weather.season.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              advice!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getWeatherGradient() {
    if (weather.isRaining) {
      return const LinearGradient(
        colors: [Color(0xFF4B6584), Color(0xFF778CA3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (weather.isSunny) {
      return const LinearGradient(
        colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (weather.isCold) {
      return const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors: [_getWeatherColor(), _getWeatherColor().withOpacity(0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _getWeatherColor() {
    if (weather.isRaining) return const Color(0xFF4B6584);
    if (weather.isSunny) return const Color(0xFFF6D365);
    if (weather.isCold) return const Color(0xFF667EEA);
    if (weather.condition.toLowerCase().contains('cloud')) {
      return const Color(0xFF95A5A6);
    }
    return AppTheme.primaryColor;
  }
}
