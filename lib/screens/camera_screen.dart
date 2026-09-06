import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/wardrobe_provider.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';
import '../services/object_detection_service.dart';
import '../services/local_ai_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _selectedImage;
  Uint8List? _imageBytes;
  Map<String, dynamic>? _detectionResult;
  bool _isProcessing = false;
  bool _useAI = true;

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _selectedImage == null
                  ? _buildCameraOptions()
                  : _buildImagePreview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Scan Clothing',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Row(
            children: [
              _buildAIToggle(),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _imageBytes = null;
                    _detectionResult = null;
                  });
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _useAI ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: _useAI ? AppTheme.primaryColor : AppTheme.textLight,
          ),
          const SizedBox(width: 6),
          Text(
            'AI ${_useAI ? 'ON' : 'OFF'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _useAI ? AppTheme.primaryColor : AppTheme.textLight,
            ),
          ),
          const SizedBox(width: 4),
          Switch(
            value: _useAI,
            onChanged: (value) {
              setState(() {
                _useAI = value;
              });
            },
            activeThumbColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraOptions() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Capture or Upload Clothing',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI will detect color, type & style',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFeatureList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      {'icon': Icons.palette, 'label': 'Auto Color Detection'},
      {'icon': Icons.category, 'label': 'Category Recognition'},
      {'icon': Icons.wb_sunny, 'label': 'Season Matching'},
      {'icon': Icons.event, 'label': 'Occasion Suggestions'},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: features.map((feature) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                feature['icon'] as IconData,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                feature['label'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImagePreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: kIsWeb && _imageBytes != null
                ? Image.memory(
                    _imageBytes!,
                    height: 300,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    _selectedImage!,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 20),
          if (_isProcessing) _buildProcessingIndicator(),
          if (_detectionResult != null) _buildDetectionResults(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            _useAI ? 'AI analyze kar raha hai...' : 'Detecting clothing...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kuch seconds lagega',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionResults() {
    final result = _detectionResult!;
    
    final styleRating = _calculateStyleRating(result);
    final colorPalette = result['colorPalette'] as List<Map<String, dynamic>>? ?? [];
    
    return Column(
      children: [
        _buildStyleRatingCard(styleRating),
        const SizedBox(height: 16),
        if (colorPalette.isNotEmpty) ...[
          _buildColorPaletteCard(colorPalette),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _useAI ? Icons.auto_awesome : Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _useAI ? 'AI Analysis Complete' : 'Detection Complete',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildResultRow('Category', result['category'] ?? 'Unknown'),
              _buildResultRow('Primary Color', result['primaryColor'] ?? 'Unknown'),
              _buildResultRow('Colors', (result['colors'] as List?)?.join(', ') ?? 'Unknown'),
              if (result['fabric'] != null)
                _buildResultRow('Fabric', result['fabric']),
              if (result['fit'] != null)
                _buildResultRow('Fit', result['fit']),
              if (result['season'] != null)
                _buildResultRow('Season', result['season']),
              if (result['occasion'] != null)
                _buildResultRow('Occasion', result['occasion']),
              if (result['material'] != null)
                _buildResultRow('Material', result['material']),
              if (result['name'] != null)
                _buildResultRow('Suggested Name', result['name']),
              if (result['confidence'] != null)
                _buildResultRow('Confidence', '${((result['confidence'] as double) * 100).round()}%'),
              if (result['seasons'] != null)
                _buildResultRow('Seasons', (result['seasons'] as List?)?.join(', ') ?? 'All'),
              if (result['occasions'] != null)
                _buildResultRow('Occasions', (result['occasions'] as List?)?.join(', ') ?? 'Any'),
            ],
          ),
        ),
        if (result['styleTips'] != null && (result['styleTips'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lightbulb, color: AppTheme.accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Style Tips',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...((result['styleTips'] as List).map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('  ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildColorPaletteCard(List<Map<String, dynamic>> palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.palette, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Colors in this Dress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: palette.length,
              itemBuilder: (context, index) {
                final colorInfo = palette[index];
                final rgb = colorInfo['rgb'] as List<int>;
                final color = Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);
                final percentage = colorInfo['percentage'] as int;
                
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _textColorForBg(color),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        colorInfo['color'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _textColorForBg(Color bg) {
    final luminance = (0.299 * bg.red + 0.587 * bg.green + 0.114 * bg.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Map<String, dynamic> _calculateStyleRating(Map<String, dynamic> result) {
    int score = 50; // Base score
    String feedback = '';
    List<String> tips = [];

    // Color analysis
    final color = (result['primaryColor'] ?? '').toLowerCase();
    final category = (result['category'] ?? '').toLowerCase();
    final material = (result['material'] ?? '').toLowerCase();

    // Color scoring
    final neutralColors = ['black', 'white', 'grey', 'navy', 'beige', 'cream'];
    final boldColors = ['red', 'yellow', 'orange', 'purple', 'pink'];
    final earthColors = ['brown', 'olive', 'tan', 'maroon'];

    if (neutralColors.contains(color)) {
      score += 15;
      tips.add('Neutral color - versatile hai!');
    } else if (boldColors.contains(color)) {
      score += 10;
      tips.add('Bold color - confidence dikhata hai!');
    } else if (earthColors.contains(color)) {
      score += 12;
      tips.add('Earth tone - trendy hai!');
    }

    // Material scoring
    final premiumMaterials = ['silk', 'leather', 'wool', 'cashmere'];
    final goodMaterials = ['cotton', 'linen', 'denim'];
    
    if (premiumMaterials.contains(material)) {
      score += 15;
      tips.add('Premium material - quality hai!');
    } else if (goodMaterials.contains(material)) {
      score += 10;
      tips.add('Good material - comfortable hai!');
    }

    // Category scoring
    final formalCategories = ['formal', 'outerwear'];
    if (formalCategories.contains(category)) {
      score += 10;
      tips.add('Smart choice - well-dressed lagoge!');
    }

    // Color variety
    final colors = result['colors'] as List? ?? [];
    if (colors.length >= 2) {
      score += 5;
      tips.add('Color variety achhi hai!');
    }

    // Deduct for issues
    if (color == 'beige' && material == 'polyester') {
      score -= 5;
      tips.add('Polyester avoid karo jab possible');
    }

    // Determine rating
    String rating;
    String emoji;
    Color ratingColor;
    String description;

    if (score >= 85) {
      rating = 'BEST';
      emoji = '🔥';
      ratingColor = const Color(0xFF10B981);
      description = 'Excellent! Ye outfit outstanding hai!';
    } else if (score >= 70) {
      rating = 'GOOD';
      emoji = '👍';
      ratingColor = const Color(0xFF3B82F6);
      description = 'Achha hai! Style on point hai.';
    } else if (score >= 50) {
      rating = 'AVERAGE';
      emoji = '👌';
      ratingColor = const Color(0xFFF59E0B);
      description = 'Theek hai. Kuch improvements ho sakte hain.';
    } else {
      rating = 'NEEDS WORK';
      emoji = '💪';
      ratingColor = const Color(0xFFEF4444);
      description = 'Try karo better options ke saath.';
    }

    return {
      'rating': rating,
      'emoji': emoji,
      'color': ratingColor,
      'score': score,
      'description': description,
      'tips': tips,
    };
  }

  Widget _buildStyleRatingCard(Map<String, dynamic> styleRating) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (styleRating['color'] as Color).withValues(alpha: 0.1),
            (styleRating['color'] as Color).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (styleRating['color'] as Color).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                styleRating['emoji'] as String,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    styleRating['rating'] as String,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: styleRating['color'] as Color,
                    ),
                  ),
                  Text(
                    '${styleRating['score']}/100',
                    style: TextStyle(
                      fontSize: 14,
                      color: (styleRating['color'] as Color).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            styleRating['description'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          if ((styleRating['tips'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...((styleRating['tips'] as List).map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppTheme.successColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ))),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_detectionResult != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addToWardrobe,
              icon: const Icon(Icons.add),
              label: const Text('Add to Wardrobe'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Retake'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('New Image'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = File(image.path);
          _imageBytes = bytes;
          _detectionResult = null;
          _isProcessing = true;
        });

        await _processImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image pick karne mein error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _cleanError(String error) {
    if (error.contains('Exception:')) {
      error = error.replaceFirst('Exception: ', '').replaceFirst('Exception: ', '');
    }
    return error;
  }

  Future<void> _processImage() async {
    try {
      Map<String, dynamic> result;

      if (_useAI) {
        final aiService = context.read<LocalAIService>();
        final imageSource = kIsWeb ? _imageBytes : _selectedImage;
        result = await aiService.analyzeClothingImage(imageSource!);
      } else {
        final detectionService = ObjectDetectionService();
        result = await detectionService.detectClothing(_selectedImage!);
      }

      setState(() {
        _detectionResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      final errorMsg = _cleanError(e.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _addToWardrobe() async {
    if (_detectionResult == null || _selectedImage == null) return;

    final result = _detectionResult!;
    final wardrobeProvider = context.read<WardrobeProvider>();

    try {
      final seasons = (result['seasons'] as List?)?.map((s) {
        return ClothingSeason.values.firstWhere(
          (season) => season.name.toLowerCase() == s.toString().toLowerCase(),
          orElse: () => ClothingSeason.allSeason,
        );
      }).toList() ?? [ClothingSeason.allSeason];

      final occasions = (result['occasions'] as List?)?.map((o) {
        return OccasionType.values.firstWhere(
          (occasion) => occasion.name.toLowerCase() == o.toString().toLowerCase(),
          orElse: () => OccasionType.casual,
        );
      }).toList() ?? [OccasionType.casual];

      final item = await wardrobeProvider.addClothingItem(
        name: result['name'] ?? 'New Item',
        category: _parseCategory(result['category'] ?? 'tops'),
        colors: List<String>.from(result['colors'] ?? [result['primaryColor'] ?? 'unknown']),
        primaryColor: result['primaryColor'] ?? 'unknown',
        seasons: seasons,
        occasions: occasions,
        imagePath: _selectedImage!.path,
        material: result['material'],
        mlConfidence: result['confidence'] != null
            ? {'detection': (result['confidence'] as num).toDouble()}
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} wardrobe mein add ho gaya!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        setState(() {
          _selectedImage = null;
          _imageBytes = null;
          _detectionResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item add karne mein error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  ClothingCategory _parseCategory(String category) {
    return ClothingCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == category.toLowerCase(),
      orElse: () => ClothingCategory.tops,
    );
  }
}
