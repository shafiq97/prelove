import '../utils/api_helper.dart';

class Item {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? _rawImageUrl; // Private field to store the raw URL
  final String condition;
  final int sellerId;
  final String sellerName;
  final bool isAvailable;
  final DateTime createdAt;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    String? imageUrl,
    required this.condition,
    required this.sellerId,
    required this.sellerName,
    this.isAvailable = true,
    required this.createdAt,
  }) : _rawImageUrl = imageUrl;

  // Getter for imageUrl that formats the URL properly
  String? get imageUrl =>
      _rawImageUrl != null ? ApiHelper.formatImageUrl(_rawImageUrl) : null;

  factory Item.fromJson(Map<String, dynamic> json) {
    try {
      // Handle id that could be int or string
      int id;
      if (json['id'] is String) {
        id = int.tryParse(json['id']) ?? 0;
      } else {
        id = json['id'] ?? 0;
      }

      // Handle price that could be double, int or string
      double price = 0.0;
      if (json['price'] != null) {
        if (json['price'] is double) {
          price = json['price'];
        } else if (json['price'] is int) {
          price = json['price'].toDouble();
        } else if (json['price'] is String) {
          price = double.tryParse(json['price']) ?? 0.0;
        }
      }

      // Handle seller_id that could be int or string
      int sellerId = 0;
      if (json['seller_id'] != null) {
        if (json['seller_id'] is int) {
          sellerId = json['seller_id'];
        } else if (json['seller_id'] is String) {
          sellerId = int.tryParse(json['seller_id']) ?? 0;
        }
      }

      // Handle created_at that could be DateTime or string
      DateTime createdAt;
      try {
        createdAt = json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now();
      } catch (e) {
        createdAt = DateTime.now();
      }

      return Item(
        id: id,
        name: json['name'] ?? 'Unknown Item',
        description: json['description'] ?? '',
        price: price,
        category: json['category'] ?? 'Other',
        imageUrl: json['image_url'],
        condition: json['condition'] ?? 'unknown',
        sellerId: sellerId,
        sellerName: json['seller_name'] ?? 'Unknown Seller',
        isAvailable: json['is_available'] == 1 || json['is_available'] == true,
        createdAt: createdAt,
      );
    } catch (e) {
      print('Error parsing Item from JSON: $e');
      print('JSON data: $json');

      // Return a default item if parsing fails
      return Item(
        id: 0,
        name: 'Error loading item',
        description: 'Error parsing item data',
        price: 0.0,
        category: 'Unknown',
        imageUrl: null,
        condition: 'unknown',
        sellerId: 0,
        sellerName: 'Unknown',
        isAvailable: false,
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': _rawImageUrl, // Use the raw URL for saving to backend
      'condition': condition,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'is_available': isAvailable ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Item copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    String? condition,
    int? sellerId,
    String? sellerName,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? _rawImageUrl,
      condition: condition ?? this.condition,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
