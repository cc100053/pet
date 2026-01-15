import 'image_labeling_service.dart';

/// Mock implementation for iOS Simulator and Web
class MockImageLabelingService implements ImageLabelingService {
  MockImageLabelingService({double confidenceThreshold = 0.6});
  
  @override
  bool get isMock => true;
  
  @override
  Future<List<DetectedLabel>> analyzeImage(String imagePath) async {
    // Simulate analysis delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock labels for testing UI flow
    return const [
      DetectedLabel(label: 'Food', confidence: 0.95),
      DetectedLabel(label: 'Pet food', confidence: 0.88),
      DetectedLabel(label: 'Bowl', confidence: 0.75),
      DetectedLabel(label: 'Cat', confidence: 0.72),
      DetectedLabel(label: 'Indoor', confidence: 0.70),
    ];
  }
  
  @override
  void dispose() {
    // Nothing to dispose for mock
  }
}

/// Factory function for stub - always returns mock
ImageLabelingService createImageLabelingService({
  double confidenceThreshold = 0.6,
}) {
  return MockImageLabelingService(confidenceThreshold: confidenceThreshold);
}
