import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A service that provides easier navigation throughout the app
/// Instead of remembering route names, you can use methods
class NavigationService {
  /// Navigate to the home screen
  static void navigateToHome(BuildContext context) {
    GoRouter.of(context).go('/home');
  }

  /// Navigate to the login screen
  static void navigateToLogin(BuildContext context) {
    GoRouter.of(context).go('/login');
  }

  /// Navigate to the registration screen
  static void navigateToRegister(BuildContext context) {
    GoRouter.of(context).go('/register');
  }

  /// Navigate to the cart screen
  static void navigateToCart(BuildContext context) {
    GoRouter.of(context).go('/cart');
  }

  /// Navigate to the checkout screen
  static void navigateToCheckout(BuildContext context) {
    GoRouter.of(context).go('/cart/checkout');
  }

  /// Navigate to item details screen
  static void navigateToItemDetails(BuildContext context, int itemId) {
    GoRouter.of(context).go('/home/items/$itemId');
  }

  /// Navigate to the add item screen
  static void navigateToAddItem(BuildContext context) {
    GoRouter.of(context).go('/add-item');
  }

  /// Navigate to the planner screen
  static void navigateToPlanner(BuildContext context) {
    GoRouter.of(context).go('/planner');
  }

  /// Navigate to outfit details
  static void navigateToOutfitDetails(BuildContext context, int outfitId) {
    GoRouter.of(context).go('/planner/outfits/$outfitId');
  }

  /// Navigate to create outfit screen
  static void navigateToCreateOutfit(BuildContext context) {
    GoRouter.of(context).go('/planner/create-outfit');
  }

  /// Navigate to the schedule screen
  static void navigateToSchedule(BuildContext context) {
    GoRouter.of(context).go('/schedule');
  }

  /// Navigate to add event screen
  static void navigateToAddEvent(BuildContext context) {
    GoRouter.of(context).go('/schedule/add-event');
  }

  /// Navigate to donation centers screen
  static void navigateToDonationCenters(BuildContext context) {
    GoRouter.of(context).go('/donation-centers');
  }

  /// Navigate to profile screen
  static void navigateToProfile(BuildContext context) {
    GoRouter.of(context).go('/profile');
  }

  /// Navigate to settings screen
  static void navigateToSettings(BuildContext context) {
    GoRouter.of(context).go('/settings');
  }

  /// Navigate to terms and conditions screen
  static void navigateToTerms(BuildContext context) {
    GoRouter.of(context).go('/settings/terms');
  }

  /// Navigate to privacy policy screen
  static void navigateToPrivacy(BuildContext context) {
    GoRouter.of(context).go('/settings/privacy');
  }

  /// Navigate to about screen
  static void navigateToAbout(BuildContext context) {
    GoRouter.of(context).go('/settings/about');
  }

  /// Navigate to history screen
  static void navigateToHistory(BuildContext context) {
    GoRouter.of(context).go('/history');
  }

  /// Go back to the previous screen
  static void goBack(BuildContext context) {
    GoRouter.of(context).pop();
  }
}
