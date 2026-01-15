// Barrel file for image labeling service
// 
// ⚠️ IMPORTANT: This uses STUB (mock labels) when google_mlkit_image_labeling
// is commented out in pubspec.yaml. See memory-bank/tech-stack.md for details.
//
// When MLKit is COMMENTED OUT → uses stub (mock labels)
// When MLKit is UNCOMMENTED  → uses real MLKit

export 'image_labeling_service.dart' show DetectedLabel, ImageLabelingService;

// Always use stub for now since MLKit is commented out
// When you uncomment MLKit in pubspec.yaml, change this line to:
//   export 'image_labeling_service_real.dart' show createImageLabelingService;
export 'image_labeling_service_stub.dart' show createImageLabelingService;
