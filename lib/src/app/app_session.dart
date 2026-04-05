import 'package:flutter/foundation.dart';

/// Stores shared UI session state, such as the active conversation thread.
class AppSessionController extends ChangeNotifier {
  /// Creates a session controller.
  AppSessionController({required String initialThreadId})
    : _selectedThreadId = initialThreadId;

  String _selectedThreadId;

  /// The currently selected thread id.
  String get selectedThreadId => _selectedThreadId;

  /// Switches the active thread.
  void selectThread(String threadId) {
    if (_selectedThreadId == threadId) {
      return;
    }
    _selectedThreadId = threadId;
    notifyListeners();
  }
}
