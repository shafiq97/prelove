import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/router_config.dart';
import 'config/theme_config.dart';
import 'services/auth_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kReleaseMode) {
        // In release mode, consider logging to a service
      } else {
        // In debug mode, print to console
        print('FlutterError: ${details.exception}');
        print('Stack trace: ${details.stack}');
      }
    };

    // Handle uncaught asynchronous errors
    PlatformDispatcher.instance.onError = (error, stack) {
      print('Uncaught async error: $error');
      print('Stack trace: $stack');
      return true;
    };

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(const MyApp());
  }, (error, stackTrace) {
    // This catches any errors that occur outside of the Flutter framework
    print('Caught error in runZonedGuarded: $error');
    print('Stack trace: $stackTrace');
    // In a production app, you might want to log this to a service
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // Add other providers here as needed
      ],
      child: Builder(
        builder: (context) {
          // Access the auth service to monitor authentication state
          // Accessing the AuthService here ensures it's properly initialized
          Provider.of<AuthService>(context, listen: true);

          return MaterialApp.router(
            title: 'Preloved Closet',
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              // Add error handling for widget tree
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          const Text(
                            'Something went wrong',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            kDebugMode
                                ? errorDetails.exception.toString()
                                : 'An unexpected error occurred.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              };

              return child!;
            },
          );
        },
      ),
    );
  }
}
