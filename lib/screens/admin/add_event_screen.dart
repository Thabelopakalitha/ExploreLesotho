// lib/screens/admin/add_event_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/themes/color_palette.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxCapacityController = TextEditingController();
  final _organizerNameController = TextEditingController();
  final _organizerEmailController = TextEditingController();
  final _organizerPhoneController = TextEditingController();
  final _organizerWebsiteController = TextEditingController();
  final _ticketUrlController = TextEditingController();

  DateTime _startDateTime = DateTime.now().add(const Duration(days: 7));
  DateTime _endDateTime = DateTime.now().add(const Duration(days: 8));
  String _selectedCategory = 'Music';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Music',
    'Sports',
    'Food',
    'Art',
    'Culture',
    'Business',
    'Education',
    'Entertainment',
    'Festival',
    'Workshop',
    'Adventure',
    'Fashion',
    'Lifestyle',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _maxCapacityController.dispose();
    _organizerNameController.dispose();
    _organizerEmailController.dispose();
    _organizerPhoneController.dispose();
    _organizerWebsiteController.dispose();
    _ticketUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDateTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _startDateTime,
    );
    if (picked != null) {
      if (!mounted) return;
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDateTime),
      );
      if (timePicked != null) {
        if (!mounted) return;
        setState(() {
          _startDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndDateTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: _startDateTime,
      lastDate: _startDateTime.add(const Duration(days: 365)),
      initialDate: _endDateTime,
    );
    if (picked != null) {
      if (!mounted) return;
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDateTime),
      );
      if (timePicked != null) {
        if (!mounted) return;
        setState(() {
          _endDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final vendorUserId = authProvider.user?.userId ?? authProvider.user?.id;

    if (vendorUserId == null || vendorUserId.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Vendor not found. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int? maxCapacity;
    if (_maxCapacityController.text.trim().isNotEmpty) {
      maxCapacity = int.tryParse(_maxCapacityController.text.trim());
    }

    final eventData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'start_datetime': _startDateTime.toIso8601String(),
      'end_datetime': _endDateTime.toIso8601String(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'category': _selectedCategory,
      'max_capacity': maxCapacity,
      'organizer_name': _organizerNameController.text.trim().isEmpty
          ? null
          : _organizerNameController.text.trim(),
      'organizer_email': _organizerEmailController.text.trim().isEmpty
          ? null
          : _organizerEmailController.text.trim(),
      'organizer_phone': _organizerPhoneController.text.trim().isEmpty
          ? null
          : _organizerPhoneController.text.trim(),
      'organizer_website': _organizerWebsiteController.text.trim().isEmpty
          ? null
          : _organizerWebsiteController.text.trim(),
      'ticket_url': _ticketUrlController.text.trim().isEmpty
          ? null
          : _ticketUrlController.text.trim(),
    };

    final success = await eventProvider.createEvent(eventData);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      await eventProvider.fetchMyEvents(vendorUserId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eventProvider.error ?? 'Failed to create event'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Event'),
        backgroundColor: ColorPalette.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: null,
            child: Text(
              'Vendor ID: ${authProvider.user?.userId ?? authProvider.user?.id ?? "N/A"}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Events appear on tourist dashboard and can be managed from your Events tab.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blue.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title *',
                        hintText: 'e.g., Maletsunyane Braai Festival',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter event title'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe what attendees can expect...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter description'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location / Venue *',
                        hintText: 'e.g., Thaba Bosiu, Maseru',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter location'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectStartDateTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: ColorPalette.primaryGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Date & Time *',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${_startDateTime.day}/${_startDateTime.month}/${_startDateTime.year} at ${_startDateTime.hour.toString().padLeft(2, '0')}:${_startDateTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _selectEndDateTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: ColorPalette.primaryGreen),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'End Date & Time *',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${_endDateTime.day}/${_endDateTime.month}/${_endDateTime.year} at ${_endDateTime.hour.toString().padLeft(2, '0')}:${_endDateTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (M)',
                        hintText: '0 for free events',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        helperText: 'Leave 0 for free events',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxCapacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Capacity (optional)',
                        hintText: 'e.g., 100',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organizerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Organizer Name (optional)',
                        hintText: 'e.g., Lesotho Adventure Guild',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organizerEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Organizer Email (optional)',
                        hintText: 'events@example.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organizerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Organizer Phone (optional)',
                        hintText: '+266 5xxx xxxx',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organizerWebsiteController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Organizer Website (optional)',
                        hintText: 'https://example.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ticketUrlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Ticket URL (optional)',
                        hintText: 'https://tickets.example.com/event',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.confirmation_number),
                        helperText:
                            'If set, Get Tickets opens this link directly.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _createEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Event',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
