import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../config/theme_config.dart';
import '../../widgets/app_bottom_navbar.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  List<Event> _events = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final response = await _apiService.getEvents(
        startDate: startDate,
        endDate: endDate,
      );

      if (response['success']) {
        setState(() {
          _events = (response['events'] as List)
              .map((event) => Event.fromJson(event))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['error'] ?? 'Failed to load events';
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

  List<Event> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.eventDate.year == day.year &&
          event.eventDate.month == day.month &&
          event.eventDate.day == day.day;
    }).toList();
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
        appBar: AppBar(title: const Text('Schedule')),
        body: Center(child: Text(_error)),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadEvents();
            },
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Select a day to view events'))
                : _getEventsForDay(_selectedDay!).isEmpty
                    ? const Center(child: Text('No events for this day'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _getEventsForDay(_selectedDay!).length,
                        itemBuilder: (context, index) {
                          final event = _getEventsForDay(_selectedDay!)[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.event),
                              ),
                              title: Text(event.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event.description != null) ...[
                                    Text(event.description!),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    'Time: ${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (event.outfitName != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Outfit: ${event.outfitName}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.edit),
                                          title: const Text('Edit Event'),
                                          onTap: () {
                                            context.pop();
                                            // TODO: Navigate to edit event screen
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.delete,
                                              color: Colors.red),
                                          title: const Text('Delete Event',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                          onTap: () async {
                                            final confirmed =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title:
                                                    const Text('Delete Event'),
                                                content: const Text(
                                                    'Are you sure you want to delete this event?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        context.pop(false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        context.pop(true),
                                                    style: TextButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.red),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              context.pop();
                                              try {
                                                final response =
                                                    await _apiService
                                                        .deleteEvent(event.id);
                                                if (mounted) {
                                                  if (response['success']) {
                                                    _loadEvents();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Event deleted successfully'),
                                                      ),
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(response[
                                                                'error'] ??
                                                            'Failed to delete event'),
                                                      ),
                                                    );
                                                  }
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content:
                                                          Text('Error: $e'),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/schedule/add-event'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }
}
