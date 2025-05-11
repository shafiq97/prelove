import 'package:flutter/material.dart';
import '../../models/item_model.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';

class SelectItemsScreen extends StatefulWidget {
  final List<Item> currentItems;

  const SelectItemsScreen({
    super.key,
    required this.currentItems,
  });

  @override
  State<SelectItemsScreen> createState() => _SelectItemsScreenState();
}

class _SelectItemsScreenState extends State<SelectItemsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  List<Item> _availableItems = [];
  List<Item> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
    // Initialize selected items with the current outfit items
    _selectedItems = List.from(widget.currentItems);
  }

  Future<void> _loadItems() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await _apiService.getItems();
      if (response['success']) {
        setState(() {
          _availableItems = (response['items'] as List)
              .map((item) => Item.fromJson(item))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to load items';
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

  void _toggleItemSelection(Item item) {
    setState(() {
      if (_selectedItems.any((i) => i.id == item.id)) {
        _selectedItems.removeWhere((i) => i.id == item.id);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Items')),
        body: const LoadingIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Items')),
        body: Center(
          child: Text('Error: $_error'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Items'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedItems);
            },
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected ${_selectedItems.length} item(s)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: _availableItems.length,
                itemBuilder: (context, index) {
                  final item = _availableItems[index];
                  final isSelected = _selectedItems.any((i) => i.id == item.id);

                  return GestureDetector(
                    onTap: () => _toggleItemSelection(item),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                    image: DecorationImage(
                                      image: item.imageUrl != null &&
                                              item.imageUrl!.isNotEmpty
                                          ? NetworkImage(item.imageUrl!)
                                          : const AssetImage(
                                                  'assets/images/placeholder.png')
                                              as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.category ?? 'Unknown category',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
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
          ],
        ),
      ),
    );
  }
}
