import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_bottom_navbar.dart';

class DonationCentersScreen extends StatefulWidget {
  const DonationCentersScreen({super.key});

  @override
  State<DonationCentersScreen> createState() => _DonationCentersScreenState();
}

class _DonationCentersScreenState extends State<DonationCentersScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _centers = [];
  List<Map<String, dynamic>> _donations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final centersResponse = await _apiService.getDonationCenters();
      if (centersResponse['success']) {
        setState(() {
          _centers =
              List<Map<String, dynamic>>.from(centersResponse['centers']);
          _isLoading = false;
        });
      }

      try {
        final donationsResponse = await _apiService.getUserDonations();
        if (donationsResponse['success']) {
          setState(() {
            _donations =
                List<Map<String, dynamic>>.from(donationsResponse['donations']);
          });
        }
      } catch (donationError) {
        print('User donations error: $donationError');
        setState(() {
          _donations = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _scheduleDonation(Map<String, dynamic> center) async {
    try {
      final authCheck = await _apiService.verifyToken();
      if (!authCheck['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please login to schedule a donation')),
          );
          context.push('/login');
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to schedule a donation')),
        );
        context.push('/login');
        return;
      }
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null || !mounted) return;

    final DateTime scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    try {
      setState(() => _isLoading = true);

      final response = await _apiService.scheduleDonation(
        centerId: center['id'],
        scheduledDate: scheduledDateTime,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (response['success']) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Donation scheduled successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['error'] ?? 'Failed to schedule donation')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (e.toString().contains('401')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Authentication failed. Please login again.')),
          );
          context.push('/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  // Format the datetime string for display
  String _formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) {
      return 'Not scheduled';
    }

    try {
      final DateTime dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error parsing date: $e');
      return dateTimeStr; // Return original string if parsing fails
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
        appBar: AppBar(title: const Text('Donation Centers')),
        body: Center(child: Text(_error)),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Donation Centers'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Centers'),
              Tab(text: 'My Donations'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _centers.isEmpty
                ? const Center(child: Text('No donation centers available'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _centers.length,
                    itemBuilder: (context, index) {
                      final center = _centers[index];
                      return Card(
                        child: ListTile(
                          title: Text(center['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(center['address']),
                              const SizedBox(height: 4),
                              Text(
                                'Operating Hours: ${center['operating_hours']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _scheduleDonation(center),
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(center['name'],
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text('Address: ${center['address']}'),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Operating Hours: ${center['operating_hours']}'),
                                    const SizedBox(height: 4),
                                    Text('Phone: ${center['phone']}'),
                                    const SizedBox(height: 4),
                                    Text(
                                        'Accepted Items: ${center['accepted_items'].join(", ")}'),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.pop();
                                          _scheduleDonation(center);
                                        },
                                        child: const Text('Schedule Donation'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
            _donations.isEmpty
                ? const Center(child: Text('No donation history'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _donations.length,
                    itemBuilder: (context, index) {
                      final donation = _donations[index];
                      return Card(
                        child: ListTile(
                          title: Text(donation['center_name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                  'Scheduled for: ${_formatDateTime(donation['scheduled_date'])}'),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${donation['status']}',
                                style: TextStyle(
                                  color: donation['status'] == 'completed'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          trailing: donation['status'] == 'scheduled'
                              ? IconButton(
                                  icon: const Icon(Icons.check_circle),
                                  onPressed: () async {
                                    try {
                                      final response = await _apiService
                                          .completeDonation(donation['id']);
                                      if (mounted && response['success']) {
                                        _loadData();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Donation marked as completed')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ],
        ),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      ),
    );
  }
}
