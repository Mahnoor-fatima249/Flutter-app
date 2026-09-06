import 'package:flutter/foundation.dart';
import '../models/clothing_item.dart';

class ARProvider extends ChangeNotifier {
  bool _isARActive = false;
  bool _isLoading = false;
  String? _error;
  ClothingItem? _currentItem;
  String? _arModelPath;
  double _rotationX = 0;
  double _rotationY = 0;
  double _scale = 1.0;
  double _positionX = 0;
  double _positionY = 0;
  bool _showSkeleton = false;
  Map<String, dynamic>? _bodyMeasurements;

  bool get isARActive => _isARActive;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ClothingItem? get currentItem => _currentItem;
  String? get arModelPath => _arModelPath;
  double get rotationX => _rotationX;
  double get rotationY => _rotationY;
  double get scale => _scale;
  double get positionX => _positionX;
  double get positionY => _positionY;
  bool get showSkeleton => _showSkeleton;
  Map<String, dynamic>? get bodyMeasurements => _bodyMeasurements;

  Future<void> startARTryOn(ClothingItem item) async {
    _isLoading = true;
    _error = null;
    _currentItem = item;
    notifyListeners();

    try {
      _arModelPath = item.imagePath;
      _isARActive = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start AR: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void stopARTryOn() {
    _isARActive = false;
    _currentItem = null;
    _arModelPath = null;
    _rotationX = 0;
    _rotationY = 0;
    _scale = 1.0;
    _positionX = 0;
    _positionY = 0;
    notifyListeners();
  }

  void updateRotation(double x, double y) {
    _rotationX = x;
    _rotationY = y;
    notifyListeners();
  }

  void updateScale(double newScale) {
    _scale = newScale.clamp(0.5, 2.0);
    notifyListeners();
  }

  void updatePosition(double x, double y) {
    _positionX = x;
    _positionY = y;
    notifyListeners();
  }

  void toggleSkeleton() {
    _showSkeleton = !_showSkeleton;
    notifyListeners();
  }

  void setBodyMeasurements(Map<String, dynamic> measurements) {
    _bodyMeasurements = measurements;
    notifyListeners();
  }

  bool get isReady => _isARActive && _arModelPath != null;

  void resetTransform() {
    _rotationX = 0;
    _rotationY = 0;
    _scale = 1.0;
    _positionX = 0;
    _positionY = 0;
    notifyListeners();
  }
}
