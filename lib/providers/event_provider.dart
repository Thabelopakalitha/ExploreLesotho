// lib/providers/event_provider.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/event.dart';
import '../services/api_service.dart';

class EventProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Event> _allEvents = [];
  List<Event> _myEvents = [];
  List<Event> _upcomingEvents = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;
  String? _selectedStatus;
  final Set<int> _interestedEventIds = <int>{};

  List<Event> get allEvents => _allEvents;
  List<Event> get myEvents => _myEvents;
  List<Event> get upcomingEvents => _upcomingEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  String? get selectedStatus => _selectedStatus;
  Set<int> get interestedEventIds => Set<int>.from(_interestedEventIds);

  int get totalEvents => _allEvents.length;
  int get totalUpcoming => _upcomingEvents.length;
  int get totalMyEvents => _myEvents.length;

  List<Event> get trendingEvents {
    return _upcomingEvents.where((e) => e.price > 100).toList();
  }

  // Fetch all events (for admin)
  Future<bool> fetchAllEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/admin/events');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _allEvents =
              (data['events'] as List).map((e) => Event.fromJson(e)).toList();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _error = 'Failed to fetch events: ${response.statusCode}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch upcoming events (for tourists)
  Future<bool> fetchUpcomingEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/admin/events?upcoming=true');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _upcomingEvents =
              (data['events'] as List).map((e) => Event.fromJson(e)).toList();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _error = 'Failed to fetch upcoming events: ${response.statusCode}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch vendor's own events
  Future<bool> fetchMyEvents(String vendorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.get('/admin/events?vendor_id=$vendorId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _myEvents =
              (data['events'] as List).map((e) => Event.fromJson(e)).toList();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _error = 'Failed to fetch your events: ${response.statusCode}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create event
  Future<bool> createEvent(Map<String, dynamic> eventData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/admin/events', eventData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _isLoading = false;
        notifyListeners();

        if (data['success'] == true) {
          return true;
        } else {
          _error = data['message'] ?? 'Failed to create event';
          return false;
        }
      }
      _error = 'Failed to create event: ${response.statusCode}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update event
  Future<bool> updateEvent(int eventId, Map<String, dynamic> eventData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.put('/admin/events/$eventId', eventData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isLoading = false;
        notifyListeners();
        return data['success'] ?? false;
      }
      _error = 'Failed to update event: ${response.statusCode}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService
          .delete('/admin/events/$eventId'); // String works fine

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isLoading = false;
        notifyListeners();

        if (data['success'] == true) {
          // Remove by String comparison
          _myEvents.removeWhere((e) => e.eventId.toString() == eventId);
          _upcomingEvents.removeWhere((e) => e.eventId.toString() == eventId);
          _allEvents.removeWhere((e) => e.eventId.toString() == eventId);
          notifyListeners();
          return true;
        }
        return false;
      }
      _error = 'Failed to delete event: ${response.statusCode}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mark interest in event (local state only)
  void markInterested(int eventId) {
    if (_upcomingEvents.any((e) => e.eventId == eventId)) {
      _interestedEventIds.add(eventId);
      notifyListeners();
    }
  }

  bool isInterested(int eventId) => _interestedEventIds.contains(eventId);

  void toggleInterest(int eventId) {
    if (_interestedEventIds.contains(eventId)) {
      _interestedEventIds.remove(eventId);
    } else {
      _interestedEventIds.add(eventId);
    }
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  // Get filtered upcoming events
  List<Event> getFilteredUpcomingEvents() {
    var filtered = List<Event>.from(_upcomingEvents);

    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered =
          filtered.where((e) => e.category == _selectedCategory).toList();
    }

    if (_selectedStatus != null && _selectedStatus != 'All') {
      filtered = filtered.where((e) => e.status == _selectedStatus).toList();
    }

    return filtered;
  }

  // Clear filters
  void clearFilters() {
    _selectedCategory = null;
    _selectedStatus = null;
    notifyListeners();
  }

  Future<void> refresh(String? vendorId) async {
    await fetchUpcomingEvents();
    if (vendorId != null && vendorId.isNotEmpty) {
      await fetchMyEvents(vendorId);
    }
  }
}
