import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A widget that helps handle back button navigation properly
/// Used to wrap screens to prevent app from exiting on back button press
class CustomBackButtonHandler extends StatefulWidget {
  final Widget child;
  final String? backRoute;
  final bool confirmExit;

  const CustomBackButtonHandler({
    Key? key,
    required this.child,
    this.backRoute,
    this.confirmExit = false,
  }) : super(key: key);

  @override
  State<CustomBackButtonHandler> createState() =>
      _CustomBackButtonHandlerState();
}

class _CustomBackButtonHandlerState extends State<CustomBackButtonHandler> {
  // Track the last back press time for double-tap to exit
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If we have a back route specified, navigate to it
        if (widget.backRoute != null) {
          GoRouter.of(context).go(widget.backRoute!);
          return false; // Prevent default back behavior
        }

        // If we need to confirm exit (usually for home screen)
        if (widget.confirmExit) {
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) >
                  const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
            return false; // Don't exit yet
          }
          return true; // Exit app after second press
        }

        // Get the current location
        final currentLocation = GoRouterState.of(context).matchedLocation;

        // For regular screens with no special handling, use GoRouter to pop
        if (GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
          return false;
        }

        // Default fallback - go to home
        if (currentLocation != '/home') {
          GoRouter.of(context).go('/home');
          return false;
        }

        return true; // Allow exiting the app if we've reached here
      },
      child: widget.child,
    );
  }
}
