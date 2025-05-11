import 'package:flutter/material.dart';
import '../../models/outfit_model.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../services/navigation_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_drawer.dart';
import '../../config/theme_config.dart';
import '../../widgets/app_bottom_navbar.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  bool _isLoading = true;
  String _error = '';
  List<Outfit> _outfits = [];
  List<Event> _events = [];

  // Helper method to build outfit thumbnail
  Widget _buildOutfitThumbnail(OutfitItem item) {
    if (item.item.imageUrl != null && item.item.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          item.item.imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading outfit thumbnail: $error');
            return const Icon(Icons.checkroom);
          },
        ),
      );
    } else {
      return const Icon(Icons.checkroom);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final outfitsResponse = await _apiService.getPlannerOutfits();
      final eventsResponse = await _apiService.getUserEvents();

      if (outfitsResponse['success'] && eventsResponse['success']) {
        setState(() {
          _outfits = (outfitsResponse['outfits'] as List)
              .map((outfit) => Outfit.fromJson(outfit))
              .toList();

          _events = (eventsResponse['events'] as List)
              .map((event) => Event.fromJson(event))
              .toList();

          _isLoading = false;
        });
      } else {
        setState(() {
          _error = outfitsResponse['error'] ??
              eventsResponse['error'] ??
              'Failed to load data';
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Planner')),
        drawer: const AppDrawer(currentIndex: 1),
        body: Center(child: Text(_error)),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.checkroom), text: 'Outfits'),
            Tab(icon: Icon(Icons.event), text: 'Events'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentIndex: 1),
      body: TabBarView(
        controller: _tabController,
        children: [
          _outfits.isEmpty
              ? const Center(child: Text('No outfits yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _outfits.length,
                  itemBuilder: (context, index) {
                    final outfit = _outfits[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12.0),
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child:
                              outfit.items != null && outfit.items!.isNotEmpty
                                  ? _buildOutfitThumbnail(outfit.items!.first)
                                  : const Icon(Icons.checkroom),
                        ),
                        title: Text(outfit.name),
                        subtitle: Text(
                          outfit.description ?? 'No description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text('${outfit.itemCount} items'),
                        onTap: () => NavigationService.navigateToOutfitDetails(
                            context, outfit.id),
                      ),
                    );
                  },
                ),
          _events.isEmpty
              ? const Center(child: Text('No events yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12.0),
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: event.outfit != null &&
                                  event.outfit!.items != null &&
                                  event.outfit!.items!.isNotEmpty
                              ? _buildOutfitThumbnail(
                                  event.outfit!.items!.first)
                              : const Icon(Icons.event),
                        ),
                        title: Text(event.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.description ?? 'No description',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${event.eventDate.toString().split(' ')[0]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMediumColor,
                              ),
                            ),
                            if (event.outfitName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Outfit: ${event.outfitName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMediumColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {},
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            NavigationService.navigateToCreateOutfit(context);
          } else {
            NavigationService.navigateToAddEvent(context);
          }
        },
        child: Icon(
          _tabController.index == 0 ? Icons.add_circle : Icons.event_available,
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }
}
