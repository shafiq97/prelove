import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/outfit_model.dart';
import '../../models/item_model.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import 'select_items_screen.dart';

class OutfitDetailsScreen extends StatefulWidget {
  final int outfitId;

  const OutfitDetailsScreen({super.key, required this.outfitId});

  @override
  State<OutfitDetailsScreen> createState() => _OutfitDetailsScreenState();
}

class _OutfitDetailsScreenState extends State<OutfitDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  Outfit? _outfit;
  bool _isEditing = false;

  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadOutfit();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadOutfit() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      print('Loading outfit details for ID: ${widget.outfitId}');
      final response = await _apiService.getOutfit(widget.outfitId.toString());

      print('Outfit details response: $response');

      if (response['success'] == true && response['outfit'] != null) {
        try {
          final outfit = Outfit.fromJson(response['outfit']);
          setState(() {
            _outfit = outfit;
            _nameController.text = outfit.name;
            _descriptionController.text = outfit.description ?? '';
            _isLoading = false;
          });
        } catch (parseError) {
          print('Error parsing outfit data: $parseError');
          setState(() {
            _error = 'Error parsing outfit data: $parseError';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to load outfit data';
          _isLoading = false;
        });

        // Show error in console for debugging
        print('Error loading outfit: $_error');
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });

      // Show exception in console for debugging
      print('Exception while loading outfit: $e');
    }
  }

  Future<void> _updateOutfit() async {
    try {
      setState(() => _isLoading = true);

      // Prepare items data for API
      final List<Map<String, dynamic>> itemsData =
          _outfit?.items?.map((item) => {'item_id': item.item.id}).toList() ??
              [];

      final response = await _apiService.updateOutfit(
        widget.outfitId.toString(),
        {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'items': itemsData,
        },
      );

      if (mounted) {
        if (response['success']) {
          _loadOutfit();
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outfit updated successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['error'] ?? 'Failed to update outfit')),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteOutfit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Outfit'),
        content: const Text('Are you sure you want to delete this outfit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      final response = await _apiService.deleteOutfit(widget.outfitId);

      if (mounted) {
        if (response['success']) {
          context.go('/planner');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Outfit deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['error'] ?? 'Failed to delete outfit')),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Function to navigate to the select items screen
  Future<void> _navigateToSelectItems() async {
    if (_outfit == null) return;

    // Extract current items from outfit
    final currentItems =
        _outfit!.items?.map((outfitItem) => outfitItem.item).toList() ?? [];

    // Navigate to select items screen and await result
    final result = await Navigator.push<List<Item>>(
      context,
      MaterialPageRoute(
        builder: (context) => SelectItemsScreen(currentItems: currentItems),
      ),
    );

    // If items were selected
    if (result != null) {
      // Create OutfitItem objects for each item
      final List<OutfitItem> outfitItems = result
          .asMap()
          .entries
          .map((entry) => OutfitItem(
                outfitId: _outfit!.id,
                itemId: entry.value.id,
                item: entry.value,
                position: entry.key + 1,
              ))
          .toList();

      // Update the outfit with new items
      setState(() {
        if (_outfit != null) {
          _outfit = _outfit!.copyWith(items: outfitItems);
        }
      });

      // Save changes to server
      _updateOutfit();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Outfit Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadOutfit,
              tooltip: 'Retry',
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Outfit',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(_error, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadOutfit,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_outfit == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Outfit not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: _isEditing
            ? TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Outfit Name',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              )
            : Text(_outfit!.name),
        actions: [
          // Edit/Save button
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateOutfit();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteOutfit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            _isEditing
                ? TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _outfit!.description ?? 'No description',
                        style: TextStyle(
                          color:
                              _outfit!.description == null ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),

            // Items section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isEditing) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Items'),
                    onPressed: () {
                      _navigateToSelectItems();
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Items grid
            if (_outfit!.items == null || _outfit!.items!.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 48, color: Colors.amber),
                    const SizedBox(height: 16),
                    const Text(
                      'No items in this outfit',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload'),
                      onPressed: _loadOutfit,
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: _outfit!.items!.length,
                itemBuilder: (context, index) {
                  final item = _outfit!.items![index].item;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Item image
                        Positioned.fill(
                          child: item.imageUrl != null
                              ? Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image_not_supported),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                        ),
                        // Item details overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item.category,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Remove item button
                        if (_isEditing)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle),
                              color: Colors.red,
                              onPressed: () {
                                // TODO: Remove item from outfit
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
