import 'package:flutter/material.dart';
import '../../models/cart_model.dart';
import '../../models/item_model.dart'; // Add this import for Item class
import '../../services/api_service.dart';
import '../../services/navigation_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_bottom_navbar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  Cart? _cart;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await _apiService.getCartItems();
      if (response['success']) {
        final cartItems = response['cart_items'] as List;

        if (cartItems.isEmpty) {
          setState(() {
            _cart = Cart(items: []);
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _cart = Cart(
              items: cartItems.map((cartItemJson) {
            // Create an Item object from the cart item data
            final item = Item(
              id: cartItemJson['item_id'],
              name: cartItemJson['name'],
              description: cartItemJson['description'] ?? '',
              price: double.parse(cartItemJson['price'].toString()),
              category: cartItemJson['category'],
              imageUrl: cartItemJson['image_url'],
              condition: cartItemJson['condition'] ?? 'Unknown',
              sellerId: 0, // We might not have this info in cart response
              sellerName: '', // We might not have this info in cart response
              isAvailable: true,
              createdAt: DateTime.parse(cartItemJson['created_at']),
            );

            // Create CartItem with the item object
            return CartItem(
              id: cartItemJson['cart_id'],
              item: item,
              quantity: cartItemJson['quantity'] ?? 1,
            );
          }).toList());
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to load cart';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    try {
      final response = await _apiService.updateCartQuantity(item.id, quantity);
      if (response['success']) {
        await _loadCart(); // Reload cart after successful update
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['error'] ?? 'Failed to update quantity')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      final response = await _apiService.removeFromCart(item.id);
      if (response['success']) {
        await _loadCart(); // Reload cart after successful removal
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to remove item')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(),
        bottomNavigationBar: AppBottomNavBar(currentIndex: 3),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shopping Cart'),
        ),
        body: Center(child: Text(_error)),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      );
    }

    if (_cart == null || _cart!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shopping Cart'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('Your cart is empty'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => NavigationService.navigateToHome(context),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cart!.items.length,
              itemBuilder: (context, index) {
                final item = _cart!.items[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.item.imageUrl ??
                                'https://placeholder.com/image',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported,
                                    size: 100),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Item details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.item.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'RM${item.item.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Quantity controls
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => _updateQuantity(
                                        item, item.quantity - 1),
                                  ),
                                  Text('${item.quantity}'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _updateQuantity(
                                        item, item.quantity + 1),
                                  ),
                                  const Spacer(),
                                  // Remove item button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeItem(item),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Cart summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RM${_cart!.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        NavigationService.navigateToCheckout(context);
                      },
                      child: const Text('Proceed to Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }
}
