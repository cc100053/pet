import 'dart:async';

enum ForceUpdateDebugPromptType { soft, hard, whatsNew }

class ForceUpdateDebugTool {
  ForceUpdateDebugTool._();

  static final ForceUpdateDebugTool instance = ForceUpdateDebugTool._();

  final StreamController<ForceUpdateDebugPromptType> _controller =
      StreamController<ForceUpdateDebugPromptType>.broadcast();

  Stream<ForceUpdateDebugPromptType> get prompts => _controller.stream;

  void showSoftPrompt() {
    _controller.add(ForceUpdateDebugPromptType.soft);
  }

  void showHardPrompt() {
    _controller.add(ForceUpdateDebugPromptType.hard);
  }

  void showWhatsNewPrompt() {
    _controller.add(ForceUpdateDebugPromptType.whatsNew);
  }

  void dispose() {
    _controller.close();
  }
}
