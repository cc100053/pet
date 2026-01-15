/// Represents a detected label from image analysis
class DetectedLabel {
  const DetectedLabel({
    required this.label,
    required this.confidence,
  });

  final String label;
  final double confidence;
}

/// Abstract interface for image labeling
abstract class ImageLabelingService {
  /// Analyze an image file and return detected labels
  Future<List<DetectedLabel>> analyzeImage(String imagePath);
  
  /// Clean up resources
  void dispose();
  
  /// Whether this is using mock implementation
  bool get isMock;
}
