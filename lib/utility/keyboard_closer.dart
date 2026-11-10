import 'package:flutter/widgets.dart';

/// Closes the keyboard whenever the page changes (a page opened or closed, a swipe back, a sheet). Without it a
/// text field of the page underneath could take the focus back when the page above closes (its route remembers
/// what was focused), and the keyboard stayed open over a page without any field to close it.
class KeyboardCloser extends NavigatorObserver {
  static void close() {
    FocusManager.instance.primaryFocus?.unfocus();
    // The route that comes back to the top restores its focus during the transition: once more after the frame
    WidgetsBinding.instance.addPostFrameCallback((_) => FocusManager.instance.primaryFocus?.unfocus());
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => close();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // A small popup (a menu, a dialog) over a field keeps its keyboard; a page doesn't
    if (route is PageRoute) close();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => close();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => close();
}
