import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/outfit_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import '../theme/app_theme.dart';
import '../widgets/outfit_card.dart';
import '../widgets/weather_widget.dart';

class OutfitSuggestionsScreen extends StatefulWidget {
  const OutfitSuggestionsScreen({super.key});

  @override
  State<OutfitSuggestionsScreen> createState() => _OutfitSuggestionsScreenState();
}

class _OutfitSuggestionsScreenState extends State<OutfitSuggestionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  OccasionType _selectedOccasion = OccasionType.casual;
  String _savedCity = 'New York';
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedCity();
  }

  Future<void> _loadSavedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('weather_city') ?? 'New York';
    setState(() {
      _savedCity = city;
      _cityController.text = city;
    });
    if (mounted) {
      context.read<OutfitProvider>().fetchWeatherByCity(city);
    }
  }

  Future<void> _saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weather_city', city);
    setState(() => _savedCity = city);
    if (mounted) {
      context.read<OutfitProvider>().fetchWeatherByCity(city);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildOccasionSelector(),
          _buildWeatherSection(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Fashion',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Sirf aapke liye outfits',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccasionSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: OccasionType.values.map((occasion) {
          final isSelected = _selectedOccasion == occasion;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(occasion.name),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedOccasion = occasion;
                });
                context.read<OutfitProvider>().setOccasion(occasion);
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              avatar: isSelected
                  ? null
                  : Icon(
                      _getOccasionIcon(occasion),
                      size: 16,
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeatherSection() {
    return Consumer<OutfitProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  hintText: 'Enter city name',
                  prefixIcon: const Icon(Icons.location_city, size: 20),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, size: 20),
                    onPressed: () {
                      final city = _cityController.text.trim();
                      if (city.isNotEmpty) _saveCity(city);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (value) {
                  final city = value.trim();
                  if (city.isNotEmpty) _saveCity(city);
                },
              ),
            ),
            if (provider.currentWeather != null)
              WeatherWidget(
                weather: provider.currentWeather!,
                advice: provider.weatherAdvice,
              ),
          ],
        );
      },
    );
  }

  Widget _buildContent() {
    return Consumer<OutfitProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSuggestionsTab(provider),
                  _buildSavedTab(provider),
                  _buildHistoryTab(provider),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primaryColor,
      unselectedLabelColor: AppTheme.textLight,
      indicatorColor: AppTheme.primaryColor,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 14),
      tabs: const [
        Tab(text: 'Suggestions'),
        Tab(text: 'Saved'),
        Tab(text: 'History'),
      ],
    );
  }

  Widget _buildSuggestionsTab(OutfitProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'AI outfits bana raha hai...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.error != null) {
      final error = provider.error!;
      final isApiIssue = error.contains('API key') || error.contains('API quota');
      final isNetworkIssue = error.contains('internet') || error.contains('network') || error.contains('SocketException');

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (isApiIssue ? Colors.orange : AppTheme.errorColor).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApiIssue ? Icons.key_off : isNetworkIssue ? Icons.wifi_off : Icons.error_outline,
                  size: 64,
                  color: isApiIssue ? Colors.orange : AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isApiIssue
                    ? 'API Limit Reached'
                    : isNetworkIssue
                        ? 'No Connection'
                        : 'Something Went Wrong',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (!isApiIssue)
                ElevatedButton.icon(
                  onPressed: () => provider.generateOutfitSuggestions(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              if (isApiIssue)
                const Text(
                  'Please update your Groq API key in the .env file to continue using AI features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (provider.suggestedOutfits.isEmpty) {
      return _buildEmptySuggestions(provider);
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: provider.suggestedOutfits.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: OutfitCard(
                  outfit: provider.suggestedOutfits[index],
                  onSave: () {
                    provider.saveOutfit(provider.suggestedOutfits[index]);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Outfit saved!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                  onWear: () {
                    _markOutfitAsWorn(provider.suggestedOutfits[index]);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedTab(OutfitProvider provider) {
    if (provider.savedOutfits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Koi outfit save nahi hua',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pasandida outfits save karo baad mein pehnne ke liye',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: provider.savedOutfits.length,
        itemBuilder: (context, index) {
          final outfit = provider.savedOutfits[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: OutfitCard(
                  outfit: outfit,
                  onSave: () {
                    provider.removeSavedOutfit(outfit.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Outfit removed'),
                      ),
                    );
                  },
                  onWear: () => _markOutfitAsWorn(outfit),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab(OutfitProvider provider) {
    if (provider.outfitHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 64,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Koi outfit history nahi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pehne hue outfits yahan dikhenge',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: provider.outfitHistory.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: OutfitCard(
                  outfit: provider.outfitHistory[index],
                  showActions: false,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptySuggestions(OutfitProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI styling ke liye tayyar?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Wardrobe mein kapde add karo aur\npersonalized outfit suggestions pao',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => provider.generateOutfitSuggestions(),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Outfits'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              provider.fetchWeatherByCity(_savedCity);
            },
            icon: const Icon(Icons.cloud_sync),
            label: const Text('Load Weather'),
          ),
        ],
      ),
    );
  }

  void _markOutfitAsWorn(Outfit outfit) {
    final provider = context.read<OutfitProvider>();
    provider.addToHistory(outfit);

    for (final item in outfit.items) {
      context.read<WardrobeProvider>().markAsWorn(item.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Outfit marked as worn!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  IconData _getOccasionIcon(OccasionType occasion) {
    switch (occasion) {
      case OccasionType.casual:
        return Icons.weekend;
      case OccasionType.formal:
        return Icons.business;
      case OccasionType.sporty:
        return Icons.fitness_center;
      case OccasionType.party:
        return Icons.celebration;
      case OccasionType.work:
        return Icons.work;
      case OccasionType.date:
        return Icons.favorite;
      case OccasionType.outdoor:
        return Icons.terrain;
    }
  }
}
