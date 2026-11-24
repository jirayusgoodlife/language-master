import 'package:flutter/gestures.dart';

/// A custom PanGestureRecognizer that claims victory in the gesture arena immediately
/// on pointer down, preventing enclosing SingleChildScrollView / PageView from
/// stealing the vertical stroke events.
class ImmediatePanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addPointer(PointerDownEvent event) {
    super.addPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
