class ApiConfig {
  // Use 10.0.2.2 for Android emulator to access host machine's localhost
  static String get baseUrl => 'http://10.0.2.2/fypProject/api/v1';

  // Auth endpoints
  static String get login => '$baseUrl/auth_api.php?action=login';
  static String get register => '$baseUrl/auth_api.php?action=register';
  static String get verifyToken => '$baseUrl/auth_api.php?action=verify-token';
  static String get getProfile => '$baseUrl/auth_api.php?action=get_profile';
  static String get updateProfile =>
      '$baseUrl/auth_api.php?action=update_profile';

  // Item endpoints
  static String get items => '$baseUrl/items_api.php?action=get_items';
  static String get searchItems => '$baseUrl/items_api.php?action=search';
  static String get createItem => '$baseUrl/items_api.php?action=create_item';

  // Cart endpoints
  static String get cart => '$baseUrl/cart_api.php?action=get_cart';
  static String get addToCart => '$baseUrl/cart_api.php?action=add_to_cart';
  static String get updateCart =>
      '$baseUrl/cart_api.php?action=update_quantity';
  static String get removeFromCart =>
      '$baseUrl/cart_api.php?action=remove_from_cart';
  static String get checkout => '$baseUrl/cart_api.php?action=checkout';

  // Planner endpoints
  static String get outfits => '$baseUrl/planner_api.php?action=get_outfits';
  static String get createOutfit =>
      '$baseUrl/planner_api.php?action=create_outfit';
  static String get updateOutfit =>
      '$baseUrl/planner_api.php?action=update_outfit';
  static String get deleteOutfit =>
      '$baseUrl/planner_api.php?action=delete_outfit';
  static String get events => '$baseUrl/planner_api.php?action=get_events';
  static String get createEvent =>
      '$baseUrl/planner_api.php?action=create_event';

  // Settings endpoints
  static String get getSettings => '$baseUrl/auth_api.php?action=get_settings';
  static String get updateSettings =>
      '$baseUrl/auth_api.php?action=update_settings';
}
