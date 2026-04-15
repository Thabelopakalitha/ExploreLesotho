// lib/screens/events/event_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event.dart';
import '../../core/themes/color_palette.dart';
import '../../providers/event_provider.dart';
import '../../widgets/social_media_buttons.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Future<void> _openTicketOptions() async {
    final directTicketUrl = widget.event.ticketUrl?.trim();
    if (directTicketUrl != null && directTicketUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(directTicketUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }

    final searchQuery =
        '${widget.event.title} tickets ${widget.event.location}'.trim();
    final searchUrl =
        'https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}';

    try {
      final uri = Uri.parse(searchUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open ticket search');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open ticket options right now.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareEvent() async {
    final event = widget.event;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final message = '''
${event.title}
${dateFormat.format(event.startDateTime)} at ${timeFormat.format(event.startDateTime)}
${event.location}

${event.isFree ? 'Free entry' : 'Price: M${event.price.toStringAsFixed(0)}'}
''';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: message.trim(),
          subject: 'Explore Lesotho Event',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share this event right now.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final eventProvider = context.watch<EventProvider>();
    final isInterested = eventProvider.isInterested(event.eventId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ColorPalette.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              SizedBox(
                height: isMobile ? 250 : 350,
                width: double.infinity,
                child: Image.network(
                  event.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: ColorPalette.lightGreen,
                    child: const Icon(Icons.event,
                        size: 80, color: ColorPalette.primaryGreen),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  if (event.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.category!,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Title and Price Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: event.isFree
                              ? Colors.green
                              : ColorPalette.accentOrange,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          event.isFree
                              ? 'FREE'
                              : 'M${event.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Date & Time Section
                  _buildInfoSection(
                    context,
                    'Date & Time',
                    [
                      _buildInfoRow(Icons.calendar_today,
                          dateFormat.format(event.startDateTime)),
                      _buildInfoRow(Icons.access_time,
                          'Starts: ${timeFormat.format(event.startDateTime)}'),
                      _buildInfoRow(
                          Icons.timer, 'Duration: ${event.formattedDuration}'),
                      _buildInfoRow(Icons.event_available,
                          'Ends: ${timeFormat.format(event.endDateTime)}'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location Section
                  _buildInfoSection(
                    context,
                    'Location',
                    [
                      _buildInfoRow(Icons.location_on, event.location),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Host Section
                  if (event.organizer != null)
                    _buildInfoSection(
                      context,
                      'Hosted By',
                      [
                        _buildInfoRow(Icons.business, event.organizer!),
                        if (event.vendorName != null)
                          _buildInfoRow(Icons.person, event.vendorName!),
                        if (event.organizerEmail?.trim().isNotEmpty == true)
                          _buildInfoRow(Icons.email, event.organizerEmail!),
                        if (event.organizerPhone?.trim().isNotEmpty == true)
                          _buildInfoRow(Icons.phone, event.organizerPhone!),
                        if (event.organizerWebsite?.trim().isNotEmpty == true)
                          _buildInfoRow(
                              Icons.language, event.organizerWebsite!),
                      ],
                    ),

                  const SizedBox(height: 16),

                  if (event.organizerEmail?.trim().isNotEmpty == true ||
                      event.organizerPhone?.trim().isNotEmpty == true ||
                      event.organizerWebsite?.trim().isNotEmpty == true)
                    _buildInfoSection(
                      context,
                      'Contact Organizer',
                      [
                        SocialMediaButtons(
                          phone: event.organizerPhone,
                          email: event.organizerEmail,
                          website: event.organizerWebsite,
                          iconSize: 22,
                        ),
                      ],
                    ),

                  if (event.organizerEmail?.trim().isNotEmpty == true ||
                      event.organizerPhone?.trim().isNotEmpty == true ||
                      event.organizerWebsite?.trim().isNotEmpty == true)
                    const SizedBox(height: 16),

                  // Description Section
                  _buildInfoSection(
                    context,
                    'About This Event',
                    [
                      Text(
                        event.description,
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Event Status
                  if (event.status != 'upcoming')
                    _buildInfoSection(
                      context,
                      'Status',
                      [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: event.isCancelled
                                ? Colors.red.withValues(alpha: 0.1)
                                : event.isEnded
                                    ? Colors.grey.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.status.toUpperCase(),
                            style: TextStyle(
                              color: event.isCancelled
                                  ? Colors.red
                                  : event.isEnded
                                      ? Colors.grey
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  if (event.isUpcoming)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              eventProvider.toggleInterest(event.eventId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isInterested
                                        ? 'Interest removed.'
                                        : 'Interest saved!',
                                  ),
                                  backgroundColor: ColorPalette.primaryGreen,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: ColorPalette.primaryGreen),
                              backgroundColor: isInterested
                                  ? ColorPalette.primaryGreen
                                      .withValues(alpha: 0.08)
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isInterested
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 20,
                                  color: ColorPalette.primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isInterested ? 'Saved' : 'Interested',
                                  style: const TextStyle(
                                      color: ColorPalette.primaryGreen),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _openTicketOptions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorPalette.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Get Tickets'),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Share Button
                  OutlinedButton.icon(
                    onPressed: _shareEvent,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Event'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: ColorPalette.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorPalette.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.map((child) {
              if (child is Text &&
                  children.indexOf(child) != children.length - 1) {
                return Column(
                  children: [
                    child,
                    const SizedBox(height: 8),
                  ],
                );
              }
              return child;
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
