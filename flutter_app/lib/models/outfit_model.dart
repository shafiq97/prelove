import 'item_model.dart';

class OutfitItem {
  final int outfitId;
  final int itemId;
  final Item item;
  final int position;

  OutfitItem({
    required this.outfitId,
    required this.itemId,
    required this.item,
    required this.position,
  });

  factory OutfitItem.fromJson(Map<String, dynamic> json) {
    try {
      // Process outfitId
      int outfitId;
      if (json['outfit_id'] is String) {
        outfitId = int.tryParse(json['outfit_id']) ?? 0;
      } else {
        outfitId = json['outfit_id'] ?? 0;
      }

      // Process itemId
      int itemId;
      if (json['item_id'] is String) {
        itemId = int.tryParse(json['item_id']) ?? 0;
      } else {
        itemId = json['item_id'] ?? 0;
      }

      // Process position
      int position;
      if (json['position'] is String) {
        position = int.tryParse(json['position']) ?? 0;
      } else {
        position = json['position'] ?? 0;
      }

      // Create item from JSON
      Item item = Item.fromJson({
        'id': itemId,
        'name': json['name'] ?? 'Unknown Item',
        'description': json['description'] ?? '',
        'price': json['price'] ?? 0.0,
        'category': json['category'] ?? 'Unknown',
        'condition': json['condition'] ?? 'unknown',
        'image_url': json['image_url'],
        'seller_id': json['seller_id'] ?? 0,
        'seller_name': json['seller_name'] ?? '',
        'is_available': json['is_available'] ?? true,
        'created_at': json['created_at'] ?? DateTime.now().toString(),
      });

      return OutfitItem(
        outfitId: outfitId,
        itemId: itemId,
        position: position,
        item: item,
      );
    } catch (e) {
      print('Error parsing OutfitItem: $e');
      print('JSON data: $json');

      // Return a default item as fallback
      return OutfitItem(
        outfitId: 0,
        itemId: 0,
        position: 0,
        item: Item.fromJson({
          'id': 0,
          'name': 'Error loading item',
          'description': 'There was an error loading this item: $e',
          'price': 0.0,
          'category': 'Unknown',
          'condition': 'unknown',
          'image_url': null,
          'seller_id': 0,
          'seller_name': '',
          'is_available': false,
          'created_at': DateTime.now().toString(),
        }),
      );
    }
  }
}

class Outfit {
  final int id;
  final String name;
  final String? description;
  final List<OutfitItem>? items;
  final int itemCount;
  final String createdAt;
  final String? updatedAt;

  Outfit({
    required this.id,
    required this.name,
    this.description,
    this.items,
    required this.itemCount,
    required this.createdAt,
    this.updatedAt,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    try {
      List<OutfitItem>? outfitItems;

      if (json['items'] != null) {
        try {
          outfitItems = (json['items'] as List)
              .map((item) => OutfitItem.fromJson(item))
              .toList();
        } catch (e) {
          print('Error parsing outfit items: $e');
          outfitItems = [];
        }
      }

      // Convert to integer if id is a string
      int outfitId;
      if (json['id'] is String) {
        outfitId = int.tryParse(json['id']) ?? 0;
      } else {
        outfitId = json['id'] ?? 0;
      }

      // Handle item_count which could be an integer or string
      int itemCount = 0;
      if (json['item_count'] != null) {
        if (json['item_count'] is int) {
          itemCount = json['item_count'];
        } else if (json['item_count'] is String) {
          itemCount = int.tryParse(json['item_count']) ?? 0;
        }
      } else {
        itemCount = outfitItems?.length ?? 0;
      }

      // Handle created_at and updated_at date fields
      String createdAt;
      try {
        createdAt = json['created_at'] ?? DateTime.now().toString();
      } catch (e) {
        createdAt = DateTime.now().toString();
      }

      String? updatedAt;
      if (json['updated_at'] != null) {
        updatedAt = json['updated_at'].toString();
      }

      return Outfit(
        id: outfitId,
        name: json['name'] ?? 'Unnamed Outfit',
        description: json['description'],
        items: outfitItems,
        itemCount: itemCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Error parsing Outfit from JSON: $e');
      print('JSON data: $json');

      // Return a default outfit if parsing fails
      return Outfit(
        id: 0,
        name: 'Error loading outfit',
        description: 'Error parsing outfit data',
        items: [],
        itemCount: 0,
        createdAt: DateTime.now().toString(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'item_count': itemCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Add a copyWith method to create a new Outfit with some updated fields
  Outfit copyWith({
    int? id,
    String? name,
    String? description,
    List<OutfitItem>? items,
    int? itemCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return Outfit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
