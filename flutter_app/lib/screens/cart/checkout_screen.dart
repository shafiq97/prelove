import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/cart_model.dart';
import '../../models/item_model.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_bottom_navbar.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedPaymentMethod = 'Cash on Delivery';
  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'Credit Card',
    'Online Banking'
  ];

  bool _isLoading = true;
  Cart? _cart;
  String _error = '';
  double _subtotal = 0;
  final double _shipping = 10.00;

  final ApiService _apiService = ApiService();

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
            _subtotal = 0;
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _cart = Cart(
            items: cartItems.map((cartItemJson) {
              final item = Item(
                id: cartItemJson['item_id'],
                name: cartItemJson['name'],
                description: cartItemJson['description'] ?? '',
                price: double.parse(cartItemJson['price'].toString()),
                category: cartItemJson['category'],
                imageUrl: cartItemJson['image_url'],
                condition: cartItemJson['condition'] ?? 'Unknown',
                sellerId: 0,
                sellerName: '',
                isAvailable: true,
                createdAt: DateTime.parse(cartItemJson['created_at']),
              );
              return CartItem(
                id: cartItemJson['cart_id'],
                item: item,
                quantity: cartItemJson['quantity'] ?? 1,
              );
            }).toList(),
          );
          _subtotal = _cart!.totalPrice;
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

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _processCheckout() async {
    if (!_formKey.currentState!.validate()) {
      print("Form validation failed.");
      return;
    }

    if (_cart == null || _cart!.isEmpty) {
      print("Cart is empty. Cannot proceed to checkout.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    print("Preparing checkout data...");
    print("Shipping Address: ${_addressController.text}");
    print("Payment Method: $_selectedPaymentMethod");

    setState(() => _isLoading = true);

    try {
      print("Calling ApiService.checkout...");
      final response = await _apiService.checkout(
        shippingAddress: _addressController.text,
        paymentMethod: _selectedPaymentMethod,
      );

      print("Checkout response received.");
      print("Raw response: $response");

      setState(() => _isLoading = false);

      if (response['success'] == true) {
        print("Checkout succeeded. Navigating to home.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed successfully!')),
          );
          context.go('/home');
        }
      } else {
        print("Checkout failed. Response content: ${response['error']}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'] ?? 'Checkout failed')),
          );
        }
      }
    } catch (e) {
      print("Checkout exception: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Summary',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_error.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: $_error',
                              style: const TextStyle(color: Colors.red)),
                        ),
                      )
                    else if (_cart == null || _cart!.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Your cart is empty'),
                        ),
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ..._cart!.items.map((item) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            item.item.imageUrl ??
                                                'https://placeholder.com/image',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                    Icons.image_not_supported,
                                                    size: 60),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item.item.name,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text('Quantity: ${item.quantity}',
                                                  style: const TextStyle(
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'RM${(item.item.price * item.quantity).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Items:'),
                                  Text('${_cart!.itemCount} items'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text('Shipping Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your address' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter phone number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) {
                          return 'Enter valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text('Payment Method',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._paymentMethods.map((method) => RadioListTile<String>(
                          title: Text(method),
                          value: method,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedPaymentMethod = v);
                            }
                          },
                        )),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text('RM${_subtotal.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Shipping:'),
                                Text('RM${_shipping.toStringAsFixed(2)}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  'RM${(_subtotal + _shipping).toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _processCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text('Place Order',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }
}
