import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/checkout_screen.dart';
import '../screens/items/item_details_screen.dart';
import '../screens/items/add_item_screen.dart';
import '../screens/planner/planner_screen.dart';
import '../screens/planner/outfit_details_screen.dart';
import '../screens/planner/create_outfit_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/schedule/add_event_screen.dart';
import '../screens/donation/donation_centers_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/settings/terms_conditions_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/admin/admin_dashboard_page.dart';
import '../services/auth_service.dart';
import '../services/admin_api.dart';
import '../widgets/screen_wrapper.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isLoggedIn = authService.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Debug logging for navigation
      print('GoRouter navigating to: ${state.matchedLocation}');
      print('Auth status: ${isLoggedIn ? 'Logged In' : 'Not Logged In'}');

      // TEMPORARY: Allow schedule and donation-centers routes even without authentication
      if (state.matchedLocation == '/schedule' ||
          state.matchedLocation.startsWith('/schedule/') ||
          state.matchedLocation == '/donation-centers' ||
          state.matchedLocation.startsWith('/donation-centers/')) {
        print('Bypassing auth check for route: ${state.matchedLocation}');
        return null;
      }

      // If not logged in and not going to auth route, redirect to login
      if (!isLoggedIn && !isAuthRoute && state.matchedLocation != '/') {
        print('Redirecting to login from: ${state.matchedLocation}');
        return '/login';
      }

      // If logged in and trying to go to auth route, redirect to home
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication routes
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            ScreenWrapper.wrapDetail(const LoginScreen(), 'Login'),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            ScreenWrapper.wrapDetail(const RegisterScreen(), 'Register'),
      ),

      // Main application routes
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          // This would typically be a scaffold with a bottom navigation bar
          return child;
        },
        routes: [
          // Home screen and related routes
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                ScreenWrapper.wrapHome(const HomeScreen()),
            routes: [
              GoRoute(
                path: 'items/:itemId',
                builder: (context, state) {
                  final itemId = int.parse(state.pathParameters['itemId']!);
                  return ScreenWrapper.wrapDetail(
                      ItemDetailsScreen(itemId: itemId), 'Item Details');
                },
              ),
            ],
          ),

          // Add item screen
          GoRoute(
            path: '/add-item',
            builder: (context, state) =>
                ScreenWrapper.wrapTab(const AddItemScreen(), 'Add Item'),
          ),

          // Cart and checkout
          GoRoute(
            path: '/cart',
            builder: (context, state) =>
                ScreenWrapper.wrapTab(const CartScreen(), 'Cart'),
            routes: [
              GoRoute(
                path: 'checkout',
                builder: (context, state) => ScreenWrapper.wrapDetail(
                    const CheckoutScreen(), 'Checkout'),
              ),
            ],
          ),

          // Planner and outfits
          GoRoute(
            path: '/planner',
            builder: (context, state) =>
                ScreenWrapper.wrapTab(const PlannerScreen(), 'Planner'),
            routes: [
              GoRoute(
                path: 'outfits/:outfitId',
                builder: (context, state) {
                  final outfitId = int.parse(state.pathParameters['outfitId']!);
                  return ScreenWrapper.wrapDetail(
                      OutfitDetailsScreen(outfitId: outfitId),
                      'Outfit Details');
                },
              ),
              GoRoute(
                path: 'create-outfit',
                builder: (context, state) => ScreenWrapper.wrapDetail(
                    const CreateOutfitScreen(), 'Create Outfit'),
              ),
            ],
          ),

          // Schedule and events
          GoRoute(
            path: '/schedule',
            builder: (context, state) =>
                ScreenWrapper.wrapTab(const ScheduleScreen(), 'Schedule'),
            routes: [
              GoRoute(
                path: 'add-event',
                builder: (context, state) => ScreenWrapper.wrapDetail(
                    const AddEventScreen(), 'Add Event'),
              ),
            ],
          ),

          // Donation centers
          GoRoute(
            path: '/donation-centers',
            builder: (context, state) => ScreenWrapper.wrapTab(
                const DonationCentersScreen(), 'Donation Centers'),
          ),

          // User profile and settings
          GoRoute(
            path: '/profile',
            builder: (context, state) =>
                ScreenWrapper.wrapTab(const ProfileScreen(), 'Profile'),
          ),

          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                ScreenWrapper.wrapDetail(const SettingsScreen(), 'Settings'),
            routes: [
              GoRoute(
                path: 'terms',
                builder: (context, state) => ScreenWrapper.wrapDetail(
                    const TermsConditionsScreen(), 'Terms & Conditions'),
              ),
              GoRoute(
                path: 'privacy',
                builder: (context, state) => ScreenWrapper.wrapDetail(
                    const PrivacyPolicyScreen(), 'Privacy Policy'),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) =>
                    ScreenWrapper.wrapDetail(const AboutScreen(), 'About'),
              ),
            ],
          ),

          // Order history
          GoRoute(
            path: '/history',
            builder: (context, state) =>
                ScreenWrapper.wrapTab(const HistoryScreen(), 'History'),
          ),

          // Admin dashboard
          GoRoute(
            path: '/admin',
            builder: (context, state) => ScreenWrapper.wrapDetail(
                const AdminDashboardPage(), 'Admin Dashboard'),
            redirect: (BuildContext context, GoRouterState state) async {
              // Check if user is an admin
              bool isAdmin = await AdminApi.isAdmin();
              if (!isAdmin) {
                return '/home'; // Redirect non-admin users to home
              }
              return null; // Allow admin users to proceed
            },
            routes: [
              // Admin users management
              GoRoute(
                path: 'users',
                builder: (context, state) => ScreenWrapper.wrapDetail(
                    const AdminDashboardPage(initialTab: 1), 'User Management'),
              ),
              // Admin items management
              GoRoute(
                path: 'items',
                builder: (context, state) => ScreenWrapper.wrapDetail(
                    const AdminDashboardPage(initialTab: 2), 'Item Management'),
              ),
              // Admin donations management
              GoRoute(
                path: 'donations',
                builder: (context, state) => ScreenWrapper.wrapDetail(
                    const AdminDashboardPage(initialTab: 3),
                    'Donation Centers'),
              ),
              // Admin events management
              GoRoute(
                path: 'events',
                builder: (context, state) => ScreenWrapper.wrapDetail(
                    const AdminDashboardPage(initialTab: 3),
                    'Event Management'),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
