import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'custom_back_button_handler.dart';

/// A wrapper for all screens to handle back button navigation
class ScreenWrapper {
  /// Wrap a home screen with double-tap to exit functionality
  static Widget wrapHome(Widget screen) {
    return CustomBackButtonHandler(
      confirmExit: true,
      child: _wrapWithAppBar(screen, 'Preloved Closet', showBackButton: false),
    );
  }

  /// Wrap a bottom navigation tab screen with navigation to home on back
  static Widget wrapTab(Widget screen, String title) {
    return CustomBackButtonHandler(
      backRoute: '/home',
      child: _wrapWithAppBar(screen, title, showBackButton: true),
    );
  }

  /// Wrap a detail screen with standard back navigation
  static Widget wrapDetail(Widget screen, String title) {
    return CustomBackButtonHandler(
      child: _wrapWithAppBar(screen, title, showBackButton: true),
    );
  }

  /// Wrap any screen with custom back route
  static Widget wrapWithCustomRoute(Widget screen, String title, String route) {
    return CustomBackButtonHandler(
      backRoute: route,
      child: _wrapWithAppBar(screen, title, showBackButton: true),
    );
  }

  /// Helper method to wrap a screen with a consistent AppBar
  static Widget _wrapWithAppBar(Widget screen, String title,
      {bool showBackButton = false}) {
    return Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          automaticallyImplyLeading: showBackButton,
          leading: showBackButton
              ? BackButton(
                  onPressed: () {
                    if (GoRouter.of(context).canPop()) {
                      GoRouter.of(context).pop();
                    } else {
                      GoRouter.of(context).go('/home');
                    }
                  },
                )
              : null,
        ),
        body: screen,
      ),
    );
  }
}
